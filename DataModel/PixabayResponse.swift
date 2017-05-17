//
//  PixabayResponse.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import Gloss

public struct ResponseEntity: Decodable {
	public let totalCount: Int64
	public let images: [PixabayImage]
	
	public init(totalCount: Int64, images: [PixabayImage]) {
		self.totalCount = totalCount
		self.images = images
	}
	
	public init?(json: JSON) {
		if let totalCount: Int64 = "" <~~ json,
			let images: [PixabayImage] = "" <~~ json {
			self.init(totalCount: totalCount, images: images)
		} else {
			return nil
		}
		
	}
	
}

