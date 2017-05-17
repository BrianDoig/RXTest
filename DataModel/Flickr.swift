//
//  Flickr.swift
//  RXTest
//
//  Created by Brian Doig on 5/10/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import FlickrKitFramework
import RxSwift
import Swiftz

public class FlickrDatasource: ImageDataSource {
	/// State protection
	let queue = DispatchQueue(label: "FlickrDatasource")
	
	/// Used for fetching pages of Flickr images
	var flickrInteresting = FKFlickrInterestingnessGetList()
	
	/// The data that will be subscribed to and the main point of this class
	public let data = Variable<[ImageData<AsyncImage, URL>]>([])
	
	/// What is the next page that will be fetched?
	private var nextPage = 0
	
	/// Is there no more data to be fetched?
	private var noMoreData = false
	
	/// Private backing variable for pageSize which has side effects
	private var _pageSize = 15
	
	/// Wrapper around _pageSize and also has the side effect of resetting the
	/// datasource when page size is set since that invaidates the internal
	/// state of the datasource.
	public var pageSize: Int {
		get {
			return _pageSize
		}
		set(value) {
			_pageSize = value
			
			// Have to reset to apply the new page size
			reset()
		}
	}
	
	/// Observable letting the driver know if there is a fetch in progress or not
	private let fetching = Variable(false)
	
	/// Public observable state of the datasource fetching status.
	public var isFetching: Observable<Bool> {
		return fetching.asObservable().share()
	}
	
	/// Directly modifies and reads the items per page of the
	/// flickrInteresting object.
	public var itemsPerPage: Int {
		get {
			return Int(flickrInteresting.per_page ?? "") ?? 0
		}
		set(value) {
			// Page size less than 1 makes no sense
			precondition(value > 0)
			
			// Store the value into the get list
			flickrInteresting.per_page = "\(value)"
		}
	}
	
	public init() {
		reset()
	}
	
	/// Changes the page and updates the flickrInteresting objects page as well.
	private func changePage(to: Int) {
		self.nextPage = to
		
		flickrInteresting.page = "\(self.nextPage)"
	}
	
	/// Reset the datasource to initial state so we can perform a refresh of
	/// the data with pull to refresh.
	public func reset() {
		queue.sync {
			// We are not out of data anymore
			noMoreData = false
			
			// Reset our data to empty
			data.value = []
			
			// Create a new get list iterator
			flickrInteresting = FKFlickrInterestingnessGetList()
			
			// Set the page size
			flickrInteresting.per_page = "\(pageSize)"
			
			// Set the current page to the first
			self.changePage(to: 1)
		}
	}
	
	/// Fetches the next page from the datasource.
	/// Creates an observable that reports the finished state for the fetch.
	public func next() -> Observable<Void> {
		return Observable<Void>.create { [weak self] observer in
			// As long as we still exist when the block executes
			if let strongSelf = self {
				
				// Must guard state variables such as fetching and noMoreData
				// from access from multiple threads at once.
				strongSelf.queue.async {
					// Prevent us from executing multiple fetches at once, 
					// or fetching if we got less than a full page of data back.
					guard strongSelf.fetching.value == false
						&& strongSelf.noMoreData == false else {
						return
					}
					
					// We are now fetching
					strongSelf.fetching.value = true
					
					// Perform the async request
					FlickrKit.shared().call(strongSelf.flickrInteresting) { (response, error) -> Void in
						
						// Move back on to our own serial queue to manage state properly
						strongSelf.queue.async(execute: { () -> Void in
							
							// Unwrap the response optional and convert it to the 
							// array of dictionaries about image data.
							if let response = response,
								let topPhotos = response["photos"] as? [AnyHashable: Any],
								let photoArray = topPhotos["photo" as NSObject] as? [[AnyHashable: Any]] {
								// Map the photo dictionary into the needed ImageData<AsyncImage, URL>
								let result = photoArray.map { photoDictionary -> ImageData<AsyncImage, URL> in
									let thumbnailURL = FlickrKit.shared().photoURL(for: .small240, fromPhotoDictionary: photoDictionary)
									let photoURL = FlickrKit.shared().photoURL(for: FKPhotoSize.large1024, fromPhotoDictionary: photoDictionary)
									let data = ImageData(thumbnail: getImage(url: thumbnailURL), image: photoURL)
									return data
								}
								
								// Have we reached the last page of data?
								if (result.count < strongSelf.pageSize) {
									strongSelf.noMoreData = true
								}
								
								// Append the array of new items
								strongSelf.data.value.append(contentsOf: result)
							}
							
							// Increment the page number
							strongSelf.changePage(to: strongSelf.nextPage + 1)
							
							// We are no longer fetching
							strongSelf.fetching.value = false
							
							// Tell our observer we are done
							observer.on(.completed)
						})
					}
				}
			}
			
			return Disposables.create()
		}
		
	}
	
}

