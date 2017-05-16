//
//  FlickrDatasource.swift
//  RXTest
//
//  Created by Brian Doig on 5/10/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import UIKit
import DataModel
import RxSwift
import RxCocoa
import Swiftz

struct FlickrCellData: IdentifiableType, Equatable {
	typealias Identity = Int
	
	let image: ImageData<AsyncImage, URL>
	
	var identity : Identity {
		return image.image.hashValue ^ image.thumbnail.value.url.hashValue
	}
	
	static func ==(lhs: FlickrCellData, rhs: FlickrCellData) -> Bool {
		return lhs.image.image == rhs.image.image
			&& lhs.image.thumbnail.value.url == rhs.image.thumbnail.value.url
			&& lhs.image.thumbnail.value.image == rhs.image.thumbnail.value.image
	}
}

struct SectionOfFlickrCellData: SectionModelType, IdentifiableType {
	typealias Item = FlickrCellData
	typealias Identity = Int
	
	var header: String
	var items: [Item]
	
	var identity: Identity {
		return items.reduce(header.hash, { (result, cellData) -> Identity in
			return result
				^ cellData.image.image.hashValue
				^ cellData.image.thumbnail.value.url.hashValue
				^ (cellData.image.thumbnail.value.image?.hashValue ?? 0xF0F0F0F0F0F0F0)
		})
	}
	
	init(original: SectionOfFlickrCellData, items: [Item]) {
		self = original
		self.items = items
	}
	
	init(header: String, items: [Item]) {
		self.header = header
		self.items = items
	}
}

extension SectionOfFlickrCellData: AnimatableSectionModelType {
	
}
