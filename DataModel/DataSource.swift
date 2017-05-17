//
//  DataSource.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import RxSwift

public protocol ImageDataSource {
	var data: Variable<[ImageData<AsyncImage, URL>]> { get }
	var pageSize: Int { get set }
	var isFetching: Observable<Bool> { get }
	
	func reset()
	func next() -> Observable<Void>
}
