//
//  DataSource.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

/// Image datasource protocol that is used to allow the view controllers to
/// share a common interface.
public protocol ImageDataSource {
	var data: Variable<[ImageData<AsyncImage, URL>]> { get }
	var pageSize: Int { get set }
	var isFetching: Observable<Bool> { get }
	
	func reset()
	func next() -> Observable<Void>
}

/// This represents an image and it's URL that it came from
public struct Image {
	public let image: UIImage?
	public let url: URL
	
	public init(_ image: UIImage?, _ url: URL) {
		self.image = image
		self.url = url
	}
}

/// This represents an image which may not have been fetched yet.
public typealias AsyncImage = Variable<Image>

/// This represents a pair of data representing the thumbnail and the full res image.
/// This is a generic because it can be transformed several steps along the way.
public class ImageData<Thumbnail, Image> {
	public let thumbnail: Thumbnail
	public let image: Image
	
	public init(thumbnail: Thumbnail, image: Image) {
		self.thumbnail = thumbnail
		self.image = image
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
				imageCache.setObject(image,
				                     forKey: url.absoluteString as NSString,
				                     cost: Int(image.size.height * image.size.width))
				
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
