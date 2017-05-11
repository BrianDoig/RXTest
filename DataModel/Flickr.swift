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

public typealias AsyncImage = Observable<UIImage>

public func flickrInterestingGetURL() -> Observable<[URL]> {
	return Observable.create { (observer) -> Disposable in
		// Start with an empty list
		observer.on(.next([]))
		
		let flickrInteresting = FKFlickrInterestingnessGetList()
		flickrInteresting.per_page = "15"
		
		FlickrKit.shared().call(flickrInteresting) { (response, error) -> Void in
			DispatchQueue.main.async(execute: { () -> Void in
				if let response = response {
					
					// Pull out the photo urls from the results
					if let topPhotos = response["photos"] as? [AnyHashable: Any] {
						
						if let photoArray = topPhotos["photo" as NSObject] as? [[AnyHashable: Any]] {
							
							let photoURLs = photoArray.map(curry(FlickrKit.shared().photoURL(for:fromPhotoDictionary:))(.small240))
							
							// Return the array
							observer.on(.next(photoURLs))
						}
					}
				}
				// Either way we are completed at this point
				observer.on(.completed)
			})
		}
		
		// No resources we need to dispose of
		return Disposables.create()
	}
}

public func flickrInterestingGetImages() -> Observable<[AsyncImage]> {
	return flickrInterestingGetURL().map({ (urls) -> [AsyncImage] in
		return urls.map(getImage)
	})
}

public func getImage(url: URL) -> AsyncImage {
	// Create an observable sequence of placeholder image to final image
	return Observable.create({ (observer) -> Disposable in
		// Start with the placeholder image
		observer.on(.next(#imageLiteral(resourceName: "PlaceholderImage")))
		
		// Make sure synchronous operation is not on main queue
		DispatchQueue.global().async {
			// Try to get the data for the image and create an image from it
			if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
				// Set the image as the next in the stream
				observer.on(.next(image))
			} else {
				// Put up an error image
				observer.on(.next(#imageLiteral(resourceName: "errorstop")))
			}
			
			// Either way we are now completed
			observer.on(.completed)
		}
		
		// No resources we need to dispose of
		return Disposables.create()
	})
}
