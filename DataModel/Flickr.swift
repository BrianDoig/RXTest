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

public struct Image {
	public let image: UIImage?
	public let url: URL
	
	public init(_ image: UIImage?, _ url: URL) {
		self.image = image
		self.url = url
	}
}

public typealias AsyncImage = Variable<Image>

public class ImageData<T, U> {
	public let thumbnail: T
	public let image: U
	
	public init(thumbnail: T, image: U) {
		self.thumbnail = thumbnail
		self.image = image
	}
}

public class FlickrDatasource {
	let queue = DispatchQueue(label: "FlickrDatasource.nextPage")
	
	var flickrInteresting = FKFlickrInterestingnessGetList()
	
	public let data = Variable<[ImageData<AsyncImage, URL>]>([])
	
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
										
										let result = photoArray.map { photoDictionary -> ImageData<AsyncImage, URL> in
											let thumbnailURL = FlickrKit.shared().photoURL(for: .small240, fromPhotoDictionary: photoDictionary)
											let photoURL = FlickrKit.shared().photoURL(for: FKPhotoSize.large1024, fromPhotoDictionary: photoDictionary)
											let data = ImageData(thumbnail: getImage(url: thumbnailURL), image: photoURL)
											return data
										}
										
										// Append the array of new items
										strongSelf.data.value.append(contentsOf: result)
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

// Cache for images already loaded previously
private let imageCache = NSCache<NSString, UIImage>()

// This function takes a url and returns an asyncronously loading image.
public func getImage(url: URL) -> AsyncImage {
	let result: AsyncImage
	
	if let image = imageCache.object(forKey: url.absoluteString as NSString) {
		result = AsyncImage(Image(image, url))
	} else {
		result = AsyncImage(Image(nil, url))
		
		DispatchQueue.global().async {
			// Try to get the data for the image and create an image from it
			if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
//				imageCache.setObject(image,
//				                     forKey: url.absoluteString as NSString,
//				                     cost: Int(image.size.height * image.size.width))
				
				// Set the image as the next in the stream
				result.value = Image(image, url)
			} else {
				// Put up an error image
				result.value = Image(#imageLiteral(resourceName: "errorstop"), url)
			}
		}
	}

	return result
}
