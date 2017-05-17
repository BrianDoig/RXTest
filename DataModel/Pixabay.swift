//
//  Pixabay.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import Foundation
import RxSwift
import Swiftz
import Alamofire
import RxAlamofire
import Gloss

enum DataErrors: Error {
	case jsonError(data: Any)
}

public class PixabayDatasource: ImageDataSource {
	let disposeBag = DisposeBag()
	
	let queue = DispatchQueue(label: "FlickrDatasource.nextPage")
	
	public let data = Variable<[ImageData<AsyncImage, URL>]>([])
	
	private var totalElements = 0
	
	private var nextPage = 0
	
	private var noMoreData = false
	
	private var _pageSize = 15
	public var pageSize: Int {
		get {
			return _pageSize
		}
		set(value) {
			_pageSize = value
			
			//print("pageSize = \(value)")
			
			// Have to reset to apply the new page size
			reset()
		}
	}
	
	private let fetching = Variable(false)
	public var isFetching: Observable<Bool> {
		return fetching.asObservable()
	}
	
	public init() {
		reset()
	}
	
	private func changePage(to: Int) {
		self.nextPage = to
		//print("Changing page to \(to)")
	}
	
	public func reset() {
		queue.sync {
			totalElements = 0
			
			
			// We are not out of data anymore
			noMoreData = false
			
			// Reset our data to empty
			data.value = []
			
			// Set the current page to the first
			self.changePage(to: 1)
		}
	}
	
	private func buildURL(page: Int, per_page: Int) -> String {
		return "https://pixabay.com/api/?key=5392719-b80f839b53a1d197e04aa1c95&image_type=photo&page=\(page)&per_page=\(per_page)"
	}
	
	private func networkCall() -> Observable<PixabayResponse> {
		return requestJSON(.get, buildURL(page: self.nextPage, per_page: self.pageSize))
			.map({ (response, json) -> PixabayResponse in
				if let pixabayResponse = PixabayResponse(json: json as? JSON ?? [:]) {
					return pixabayResponse
				} else {
					throw DataErrors.jsonError(data: json)
				}
			})
	}
	
	public func next() -> Observable<Void> {
		return Observable<Void>.create { [weak self] observer in
			// As long as we still exist when the block executes
			if let strongSelf = self {
				
				strongSelf.queue.async {
					// Prevent us from executing multiple fetches at once,
					// or fetching if we got less than a full page of data back.
					guard strongSelf.fetching.value == false
						&& strongSelf.noMoreData == false else {
							return
					}
					
					// We are now fetching
					strongSelf.fetching.value = true
					
					// Perform the async request
					strongSelf.networkCall().subscribe({ (event) -> Void in
						strongSelf.queue.async(execute: {
							if let response = event.element {
								strongSelf.totalElements = Int(response.totalCount)
								
								let data = response.images.flatMap(PixabayImage.toImageData)
								
								//print("Fetched \(data.count) records")
								
								strongSelf.data.value.append(contentsOf: data)
								
								//print("Total \(strongSelf.data.value.count) records")
								
								if strongSelf.data.value.count >= strongSelf.totalElements {
									strongSelf.noMoreData = true
									//print("noMoreData = true: \(strongSelf.data.value.count) >= \(strongSelf.totalElements)")
								}
								
								strongSelf.changePage(to: strongSelf.nextPage + 1)
								
								strongSelf.fetching.value = false
								
								observer.on(.completed)
							}
							
						})
						
					}).disposed(by: strongSelf.disposeBag)
				}
			}
			
			return Disposables.create()
		}
		
	}
	
}

