//
//  Package.swift
//  RXTest
//
//  Created by Brian Doig on 5/7/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import PackageDescription

let package = Package(
	name: "RXTest",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4),
		.Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3)
	]
)

