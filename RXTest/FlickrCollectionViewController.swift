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
import RxDataSources

private let reuseIdentifier = "FlickrCell"

class FlickrCollectionViewController: UICollectionViewController {

	let cvDataSource = RxCollectionViewSectionedReloadDataSource<SectionOfFlickrCellData>()
	
	let disposeBag = DisposeBag()
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        self.collectionView!.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

		// Create the callback that generates collection view cells
		cvDataSource.configureCell = { [weak self] (ds, cv, ip, item) in
			// Dequeue the cell and force cast it.  Not super safe but it 
			// should not change and if it does, it will break immidiatly.
			let cell = cv.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: ip) as! ImageCollectionViewCell
			
			// As long as self still exists, and we have an imageView that is not nil
			if let imageView = cell.imageView,
				let strongSelf = self  {
				// Bind the image stream to the image view
				item.image.bind(to: imageView.rx.image)
					.disposed(by: strongSelf.disposeBag)
			}
			
			// Return the generated table view cell.
			print(cell)
			return cell
		}
		
		// Need to set this to nil to override the existing one set in the storyboard.
		// Otherwise the library will throw an assert.
		self.collectionView?.dataSource = nil
		
		// Create the image datasource
		self.generateNewImageDatasource()
    }
	
	private func generateNewImageDatasource() {
		// Presuming the collection view still exists (it's weak to avoid memory leak)
		if let cv = self.collectionView {
			// Generate the data stream, transform it into table view sections,
			// observe it on the main queue, and then bind the datasource
			// to the collection view.
			flickrInterestingGetImages()
				.map({ (images) -> [SectionOfFlickrCellData] in
					return [
						SectionOfFlickrCellData(header: "", items: images.map(FlickrCellData.init))
					]
				})
				.observeOn(MainScheduler.instance)
				.bind(to: cv.rx.items(dataSource: cvDataSource))
				.disposed(by: disposeBag)
			
			
			
			
		}
		

	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of items
//        return 0
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
//    
//        // Configure the cell
//    
//        return cell
//    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
