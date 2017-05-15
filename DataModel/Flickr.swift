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

public typealias AsyncImage = Variable<UIImage>

public struct ImageData<T, U> {
	public let thumbnail: T
	public let image: U
}

public class FlickrDatasource {
	let queue = DispatchQueue(label: "FlickrDatasource.nextPage")
	
	var flickrInteresting = FKFlickrInterestingnessGetList()
	
	public let data = Variable<[ImageData<URL, URL>]>([])
	
	private var nextPage = 0
	
	private var _pageSize = 15
	private var pageSize: Int {
		get {
			return _pageSize
		}
		set(value) {
			_pageSize = value
			
			// Have to reset to apply the new page size
			reset()
		}
	}
	
	private let fetching = Variable(false)
	public var isFetching: Observable<Bool> {
		return fetching.asObservable()
	}
	
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
		// We don't care about the event finishing here, so dispose of it
		next().subscribe({ _ in }).dispose()
	}
	
	public var images: Observable<[ImageData<AsyncImage, URL>]> {
		return data.asObservable().map({ (urls) -> [ImageData<AsyncImage, URL>] in
			return urls.map {
				ImageData(thumbnail: getImage(url: $0.thumbnail),
				          image: $0.image)
			}
		})
	}
	
	private func changePage(to: Int) {
		self.nextPage = to
		
		flickrInteresting.page = "\(self.nextPage)"
	}
	
	public func reset() {
		queue.sync {
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
	
	public func next() -> Observable<Void> {
		return Observable<Void>.create { [weak self] observer in
			// As long as we still exist when the block executes
			if let strongSelf = self {
				
				strongSelf.queue.async {
					// Prevent us from executing multiple fetches at once
					guard strongSelf.fetching.value == false else {
						return
					}
					
					// We are now fetching
					strongSelf.fetching.value = true
					
					// Perform the async request
					FlickrKit.shared().call(strongSelf.flickrInteresting) { (response, error) -> Void in
						
						// Move back on to our own serial queue to manage state properly
						strongSelf.queue.async(execute: { () -> Void in
							
							// Unwrap the response optional
							if let response = response {
								
								// Pull out the photo urls from the results
								if let topPhotos = response["photos"] as? [AnyHashable: Any] {
									
									if let photoArray = topPhotos["photo" as NSObject] as? [[AnyHashable: Any]] {
										
										let result = photoArray.map { photoDictionary -> ImageData<URL, URL> in
											let thumbnailURL = FlickrKit.shared().photoURL(for: .small240, fromPhotoDictionary: photoDictionary)
											let photoURL = FlickrKit.shared().photoURL(for: FKPhotoSize.large1024, fromPhotoDictionary: photoDictionary)
											let data = ImageData(thumbnail: thumbnailURL, image: photoURL)
											return data
										}
										
										// Append the array of new items
										strongSelf.data.value = strongSelf.data.value + result
									}
								}
								
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

public func getImage(url: URL) -> AsyncImage {
	let result = Variable(#imageLiteral(resourceName: "PlaceholderImage"))
	
	DispatchQueue.global().async {
		// Try to get the data for the image and create an image from it
		if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
			// Set the image as the next in the stream
			result.value = image
		} else {
			// Put up an error image
			result.value = #imageLiteral(resourceName: "errorstop")
		}
	}

	return result
}
