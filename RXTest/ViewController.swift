//
//  ViewController.swift
//  RXTest
//
//  Created by Brian Doig on 5/5/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import UIKit
import Alamofire
import RxSwift
import RxCocoa
import RxAlamofire
import Swiftz
import FlickrKitFramework

typealias Result<T> = Either<Error, T>

func add(a: Int) -> (_ b: Int) -> Int { return { b in a + b } }

class ViewController: UIViewController {

	var result: Result<Int> = .Right(5)
	var a: Int? = 5
	var b: Int? = 7
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

