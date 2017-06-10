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
import RxData

struct ImageCellData {
	let image: ImageData<AsyncImage, URL>
}

struct SectionOfImageCellData: SectionModelType {
	typealias Item = ImageCellData
	typealias Identity = Int
	
	var header: String
	var items: [Item]
	
	init(original: SectionOfImageCellData, items: [Item]) {
		self = original
		self.items = items
	}
	
	init(header: String, items: [Item]) {
		self.header = header
		self.items = items
	}
}

extension UIScrollView {
	/// This method determins if the scroll view is near the bottom edge using
	/// the edgeOffset as the distance used to trigger scrolling.
	func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
		return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
	}
}

