//
//  PixabayImage.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import Swiftz

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
	
	enum JSONCodingKeys: String, CodingKey {
		case id
		case pageURL
		case pageImageWidth = "imageWidth"
		case pageImageHeight = "imageHeight"
		
		case previewURL
		case previewWidth
		case previewHeight
		
		case imageURL = "webformatURL"
		case imageWidth = "webformatWidth"
		case imageHeight = "webformatHeight"
		
		case viewCount = "views"
		case downloadCount = "downloads"
		case likeCount = "likes"
		case tags
		case username = "user"
	}
	
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
	
	public init(from decoder: Decoder) throws {
		// Used to turn the comma seperated list of tags into an array of tags.
		let splitCSV: (String) -> [String] = { csv in
			csv.characters
				.split { $0 == "," }
				.map { String($0).trimmingCharacters(in: NSCharacterSet.whitespaces) }
		}
		
		// The <~~ operator is from the Gloss JSON parsing library
		let container = try decoder.container(keyedBy: JSONCodingKeys.self)
		
		self.init(id: try container.decode(UInt64.self, forKey: .id),
		          pageURL: try container.decode(String.self, forKey: .pageURL),
		          pageImageWidth: try container.decode(Int.self, forKey: .pageImageWidth),
		          pageImageHeight: try container.decode(Int.self, forKey: .pageImageHeight),
		          previewURL: try container.decode(String.self, forKey: .previewURL),
		          previewWidth: try container.decode(Int.self, forKey: .previewWidth),
		          previewHeight: try container.decode(Int.self, forKey: .previewHeight),
		          imageURL: try container.decode(String.self, forKey: .imageURL),
		          imageWidth: try container.decode(Int.self, forKey: .imageWidth),
		          imageHeight: try container.decode(Int.self, forKey: .imageHeight),
		          viewCount: try container.decode(Int64.self, forKey: .viewCount),
		          downloadCount: try container.decode(Int64.self, forKey: .downloadCount),
		          likeCount: try container.decode(Int64.self, forKey: .likeCount),
		          tags: splitCSV(try container.decode(String.self, forKey: .tags)),
		          username: try container.decode(String.self, forKey: .username))
		
		
	}
	
	public static func toImageData(_ image: PixabayImage) -> ImageData<AsyncImage, URL>? {
		/*
		Curry takes a function with the method signature 
		
		(A, B) -> C
		
		and changes it to the signature
		
		(A) -> (B) -> C
		
		This is known as the curried form which was invented by Haskell Curry.
		
		The expression "a <^> b" is equivalent to "b.map(a)".
		The expression "a <*> b" is equivalent to "b.flatMap(a)".
		
		Having the orders paramater order switched for the operators, combined
		with the curried form allow you write an expression that is similar to
		calling the original function with optional paramaters passed in when
		the function does not accept optional paramaters.  If any value is nil
		then the whole result is nil. Thus the two code snippets are equivalent
		
		let a: A? = A()
		let b: B? = B()
		let c: C? = C()
		
		let result: D? 
		if let aa = a, bb = b, cc = c {
			result = f(aa, bb, cc) 
		} else { 
			result = nil 
		}
		
		can be written as 
		
		let result = curry(f) <^> a <*> b <*> c
		
		which looks much closer to f(a,b,c) than the if let method.
		
		They curry function, <^> and <*> are from the Swiftz libary which is 
		for functional programming.  You will find them in many open source
		swift libraries since they are standard operators in many languages.
		
		Thus since initing URL with a string returns an URL? and you must have
		both images the expression returns nil if either image fails to be
		created.
		
		So the one line of code below replaces the following 7 lines of code
		let result: ImageData<AsyncImage, URL>?
		if let previewURL = URL(string: image.previewURL),
			let asyncPreviewImage = getImage(asyncURL),
			let imageURL = URL(string: image.imageURL) {
			result = ImageData<AsyncImage, URL>(thumbnail: asyncPreviewImage, image: imageURL)
		} else {
			result = nil 
		}
		return result
		*/
		return curry(ImageData<AsyncImage, URL>.init)				// Curried form
			<^> URL(string: image.previewURL).flatMap(getImage)		// Passing in first paramater as an optional
			<*> URL(string: image.imageURL)							// Passing in second paramater as an optional
	}
	
}

