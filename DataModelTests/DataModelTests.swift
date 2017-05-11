//
//  DataModelTests.swift
//  DataModelTests
//
//  Created by Brian Doig on 5/10/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import XCTest
@testable import DataModel
import FlickrKitFramework
import Swiftz
import RxSwift
import RxBlocking

func blockingLast<T>(_ stream: Observable<T>) -> T? {
	return (try? stream.toBlocking().last()).flatMap(identity)
}

class DataModelTests: XCTestCase {
	
	var disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
		
		FlickrKit.shared().initialize(withAPIKey: "f3c938d136c47d99d57c3792cb598106", sharedSecret: "a4c6a8ae37364fe5")
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

	func testFlickr() {
//		let expect = expectation(description: "Flickr")
		
		let flickr = flickrInterestingGetURL()
		
		let blocked = flickr.toBlocking()
		
		let result = try? blocked.toArray()
		
		print(result ?? "BOOM!")
		
//		waitForExpectations(timeout: 10)
	}
	
	func testFlickrImages() {
//		let expect = expectation(description: "Flickr")
		
		let networkCall = flickrInterestingGetImages()
		
		if let images = blockingLast(networkCall) {
			let uiimages = images.flatMap(blockingLast)
			uiimages.forEach { print($0) }
		}

	
//		waitForExpectations(timeout: 30)
	}
	
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
