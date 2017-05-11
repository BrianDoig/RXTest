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
import RxDataSources

struct FlickrCellData {
	let image: ImageData<AsyncImage, URL>
}

struct SectionOfFlickrCellData {
	var header: String
	var items: [Item]
}

extension SectionOfFlickrCellData: SectionModelType {
	typealias Item = FlickrCellData
	
	init(original: SectionOfFlickrCellData, items: [Item]) {
		self = original
		self.items = items
	}
}

