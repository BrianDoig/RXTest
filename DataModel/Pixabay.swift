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
	/// Used to clean up Observables when the PixabayDatasource deallocates
	let disposeBag = DisposeBag()
	
	/// Syncronization queue for variables such as nextPage, totalElements, etc
	let queue = DispatchQueue(label: "PixabayDatasource")
	
	/// This is part of the imageDataSource protocol and is the data users
	/// of this class are most likely going to be observing.
	public let data = Variable<[ImageData<AsyncImage, URL>]>([])
	
	/// This is the total number of images being returned.
	private var totalElements = 0
	
	/// The next page that will be fetched.
	private var nextPage = 0
	
	/// This flag indicates that there is no more data to be fetched.
	private var noMoreData = false
	
	/// Private variable that holds pageSize's data
	private var _pageSize = 15
	
	/// Public acessor to _pageSize.  Has the side effect of resetting the
	/// datasource when the setter is called.  This is because it invalidates
	/// all the existing paging information.
	public var pageSize: Int {
		get {
			return _pageSize
		}
		set(value) {
			_pageSize = value
			
			// Have to reset to apply the new page size
			reset()
		}
	}
	
	/// Used for the controller to determine if it is fetching or not.
	
	private let fetching = Variable(false)
	public var isFetching: Observable<Bool> {
		return fetching.asObservable().share()
	}
	
	/// Default initializer
	public init() {
		reset()
	}
	
	/// Changes the page to the desired page number
	private func changePage(to: Int) {
		self.nextPage = to
	}
	
	/// Resets the datasource by empting it out and setting all counters to default
	public func reset() {
		queue.sync {
			/// Total number of elements in the call that can be fetched
			totalElements = 0
			
			// We are not out of data anymore
			noMoreData = false
			
			// Reset our data to empty
			data.value = []
			
			// Set the current page to the first
			self.changePage(to: 1)
		}
	}
	
	/// This function builds the URL for the data we are going to fetch.
	private func buildURL(page: Int, per_page: Int) -> String {
		return "https://pixabay.com/api/?key=5392719-b80f839b53a1d197e04aa1c95&image_type=photo&page=\(page)&per_page=\(per_page)"
	}
	
	/// This function builds the observable result of the network call.
	/// This function also handles mapping the the JSON to a model object.
	private func networkCall() -> Observable<PixabayResponse> {
		return requestData(.get, buildURL(page: self.nextPage, per_page: self.pageSize))
			.map({ (response, json) -> PixabayResponse in
				if let pixabayResponse = try? JSONDecoder().decode(PixabayResponse.self, from: json) {
					return pixabayResponse
				} else {
					throw DataErrors.jsonError(data: json)
				}
			})
			.shareReplay(1)
	}
	
	/// This function fetches the next page of data from the data soure
	public func next() -> Observable<Void> {
		// Create the observable
		return Observable<Void>.create { [weak self] observer in
			// As long as we still exist when the block executes
			if let strongSelf = self {
				
				// Execute on the queue since we have to access state variables
				// asyncronously sunch as fetching and noMoreData
				strongSelf.queue.async {
					// Prevent us from executing multiple fetches at once,
					// or fetching if we got less than a full page of data back.
					guard strongSelf.fetching.value == false
						&& strongSelf.noMoreData == false else {
							return
					}
					
					// We are now fetching
					strongSelf.fetching.value = true
					
					// Perform the async request for data
					strongSelf.networkCall().subscribe({ (event) -> Void in
						// Process the data we got back on the queue again since
						// we are modifying fetching, next page, etc async.
						strongSelf.queue.async(execute: {
							// Presuming we got back a response
							if let response = event.element {
								// Store the total number of elements in the search response
								strongSelf.totalElements = Int(response.totalCount)
								
								// Convert the response PixabayImage into ImageData objects so we
								// can append them to self.data
								let data = response.images.flatMap(PixabayImage.toImageData)
								
								// Append the next page of data to the existing data
								strongSelf.data.value.append(contentsOf: data)
								
								// If we have met or exceeded the number of objects
								// indicated as the maximum, then we are done.
								if strongSelf.data.value.count >= strongSelf.totalElements {
									strongSelf.noMoreData = true
								}
								
								// Increment our next page
								strongSelf.changePage(to: strongSelf.nextPage + 1)
								
								// We are done fetching
								strongSelf.fetching.value = false
								
								// Signal the observer we are done
								observer.on(.completed)
							}
							
						})
						// Dispose of the observable in the bag.
					}).disposed(by: strongSelf.disposeBag)
				}
			}
			
			return Disposables.create()
		}
		
	}
	
}

