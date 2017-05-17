//
//  GetImage.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation

// Cache for images already loaded previously
private let imageCache = NSCache<NSString, UIImage>()

private struct OpQueue {
	static let shared: OperationQueue = {
		let oq = OperationQueue()
//		oq.maxConcurrentOperationCount = 16
		return oq
	}()
}

// This function takes a url and returns an asyncronously loading image.
public func getImage(url: URL) -> AsyncImage {
	let result: AsyncImage
	
	if let image = imageCache.object(forKey: url.absoluteString as NSString) {
		result = AsyncImage(Image(image, url))
	} else {
		result = AsyncImage(Image(nil, url))
		
		OpQueue.shared.addOperation({
			// Try to get the data for the image and create an image from it
			if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
				imageCache.setObject(image,
				                     forKey: url.absoluteString as NSString,
				                     cost: Int(image.size.height * image.size.width))
				
				// Set the image as the next in the stream
				result.value = Image(image, url)
			} else {
				// Put up an error image
				result.value = Image(#imageLiteral(resourceName: "errorstop"), url)
			}
		})
	}
	
	return result
}
