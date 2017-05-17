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

