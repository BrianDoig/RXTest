//
//  PixabayResponse.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation

public struct PixabayResponse: Decodable {
	public let totalCount: Int64
	public let images: [PixabayImage]
	
	enum JSONCodingKeys: String, CodingKey {
		case totalCount	= "totalHits"
		case images		= "hits"
	}
	
	public init(totalCount: Int64, images: [PixabayImage]) {
		self.totalCount = totalCount
		self.images = images
	}
	
	public init(from decoder: Decoder) throws {
		// The <~~ operator is from the Gloss JSON parsing library
		let container = try decoder.container(keyedBy: JSONCodingKeys.self)
		
		self.init(totalCount: try container.decode(Int64.self, forKey: .totalCount),
		          images: try container.decode([PixabayImage].self, forKey: .images))
		
	}
}

