//
//  PixabayImage.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import Gloss

public struct PixabayImage: Decodable {
	public let id: UInt64
	
	public let pageURL: String
	public let pageImageWidth: Int
	public let pageImageHeight: Int
	
	public let previewURL: String
	public let previewWidth: Int
	public let previewHeight: Int
	
	public let imageURL: String
	public let imageWidth: Int
	public let imageHeight: Int
	
	public let viewCount: Int64
	public let downloadCount: Int64
	public let likeCount: Int64
	public let tags: [String]
	public let username: String
	
	public init(id: UInt64, pageURL: String, pageImageWidth: Int, pageImageHeight: Int, previewURL: String, previewWidth: Int, previewHeight: Int, imageURL: String, imageWidth: Int, imageHeight: Int, viewCount: Int64, downloadCount: Int64, likeCount: Int64, tags: [String], username: String) {
		self.id = id
		self.pageURL = pageURL
		self.pageImageWidth = pageImageWidth
		self.pageImageHeight = pageImageHeight
		self.previewURL = previewURL
		self.previewWidth = previewWidth
		self.previewHeight = previewHeight
		self.imageURL = imageURL
		self.imageWidth = imageWidth
		self.imageHeight = imageHeight
		self.viewCount = viewCount
		self.downloadCount = downloadCount
		self.likeCount = likeCount
		self.tags = tags
		self.username = username
	}
	
	public init?(json: JSON) {
		let splitCSV: (String) -> [String] = { csv in
			csv.characters
				.split { $0 == "," }
				.map { String($0).trimmingCharacters(in: NSCharacterSet.whitespaces) }
		}

		if let id: UInt64 = "id" <~~ json,
			let pageURL: String = "pageURL" <~~ json,
			let pageImageWidth: Int = "imageWidth" <~~ json,
			let pageImageHeight: Int = "imageHeight" <~~ json,
			
			let previewURL: String = "previewURL" <~~ json,
			let previewWidth: Int = "previewWidth" <~~ json,
			let previewHeight: Int = "previewHeight" <~~ json,
			
			let imageURL: String = "webformatURL" <~~ json,
			let imageWidth: Int = "webformatWidth" <~~ json,
			let imageHeight: Int = "webformatHeight" <~~ json,
			
			let viewCount: Int64 = "views" <~~ json,
			let downloadCount: Int64 = "downloads" <~~ json,
			let likeCount: Int64 = "likes" <~~ json,
			let username: String  = "user" <~~ json {
			self.init(id: id,
			          pageURL: pageURL,
			          pageImageWidth: pageImageWidth,
			          pageImageHeight: pageImageHeight,
			          previewURL: previewURL,
			          previewWidth: previewWidth,
			          previewHeight: previewHeight,
			          imageURL: imageURL,
			          imageWidth: imageWidth,
			          imageHeight: imageHeight,
			          viewCount: viewCount,
			          downloadCount: downloadCount,
			          likeCount: likeCount,
			          tags: ("tags" <~~ json).map(splitCSV) ?? [],
			          username: username)
		} else {
			return nil
		}
	}
}

