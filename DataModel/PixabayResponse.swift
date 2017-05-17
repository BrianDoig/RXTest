//
//  PixabayResponse.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import Gloss

public struct PixabayResponse: Decodable {
	public let totalCount: Int64
	public let images: [PixabayImage]
	
	public init(totalCount: Int64, images: [PixabayImage]) {
		self.totalCount = totalCount
		self.images = images
	}
	
	public init?(json: JSON) {
		if let totalCount: Int64 = "totalHits" <~~ json,
			let images: [PixabayImage] = "hits" <~~ json {
			self.init(totalCount: totalCount, images: images)
		} else {
			return nil
		}
		
	}
	
}

