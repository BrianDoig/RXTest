//
//  FlickrCollectionViewController.swift
//  RXTest
//
//  Created by Brian Doig on 5/10/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import UIKit
import DataModel
import RxSwift
import RxCocoa
import Swiftz

class FlickrCollectionViewController: BaseCollectionViewController {

	override func viewDidLoad() {
		// Set the datasource for this view
		self.datasource = FlickrDatasource()
		
		// Set the reuse identifier before we set everything up.
		self.reuseIdentifier = "FlickrCell"
		
		super.viewDidLoad()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}
