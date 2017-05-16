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

private let reuseIdentifier = "FlickrCell"

extension UIScrollView {
	/// This method determins if the scroll view is near the bottom edge using
	/// the edgeOffset as the distance used to trigger scrolling.
	func  isNearBottomEdge(edgeOffset: CGFloat = 20.0) -> Bool {
		return self.contentOffset.y + self.frame.size.height + edgeOffset > self.contentSize.height
	}
}

class FlickrCollectionViewController: UICollectionViewController {

	/// This is the datasource for the collection view
	let cvDataSource = RxCollectionViewSectionedReloadDataSource<SectionOfFlickrCellData>()
	
	/// This is allows all the data streams to be deallocated when the view
	/// controller is deallocated.
	let disposeBag = DisposeBag()
	
	/// This is the refresh control for the collection view.
	let refreshControl = UIRefreshControl()
	
	/// This is the datasource that has it's data fed into the cvDataSource
	private let datasource = FlickrDatasource()
	
	/// This method allows for the refresh functionality to be triggered.
	/// It removes all the data from the datasource and then loads the first page.
	@objc private func refresh() {
		datasource.reset()
		
		datasource.next()
			.subscribe({ [weak self] _ in
				// When the datasource is done loading, end refreshing
				self?.refreshControl.endRefreshing()
			})
			.disposed(by: disposeBag)
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		// Set up the refresh control
		collectionView?.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(FlickrCollectionViewController.refresh), for: .valueChanged)

		
		// Create the callback that generates collection view cells
		cvDataSource.configureCell = { [weak self] (ds, cv, ip, item) in
			// Dequeue the cell and force cast it.  Not super safe but it 
			// should not change and if it does, it will break immidiatly.
			let cell = cv.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: ip) as! ImageCollectionViewCell
			
			// As long as self still exists, and we have an imageView that is not nil
			if let imageView = cell.imageView,
				let strongSelf = self  {
				// Bind the image stream to the image view
				item.image.thumbnail.asObservable()
					.map({ $0.image })
					.bind(to: imageView.rx.image)
					.disposed(by: strongSelf.disposeBag)
				
			}
			
			// Return the generated table view cell.
			return cell
		}
		
		// Handle image presses
		self.collectionView?.rx.itemSelected.subscribe(onNext: { [weak self] (indexPath) in
			// Make sure self stays around for the duration of this async block
			// if it has not already gone away.
			if let strongSelf = self {
				// Get our async image for that index path
				let asyncImage = getImage(url: strongSelf.cvDataSource[indexPath].image.image)
				
				// Perform the segue passing the asyncImage as the sender so
				// that it can be set into the view controller as it is loaded.
				strongSelf.performSegue(withIdentifier: "ShowImage", sender: asyncImage)
			}
		}).disposed(by: disposeBag)
		
		
		// Need to set this to nil to override the existing one set in the storyboard.
		// Otherwise the library will throw an assert.
		self.collectionView?.dataSource = nil
		
		// Create the image datasource
		self.generateNewImageDatasource()
		
		// Create the next page trigger
		createNextPageTrigger()
    }
	
	/// This method creates the next page trigger that binds the bottom of the
	/// scroll view to the loading and update of the UI.
	private func createNextPageTrigger() {
		// Grab a direct reference to the dispose bag so we can use it in
		// closures without needing to refer to self.
		let disposeBag = self.disposeBag
		
		// Create the end of page trigger.  It looks if the collection view is
		// within 20 points of the end of the view and if so it tries to load the
		// next page.
		let loadNextPageTrigger = self.collectionView?.rx.contentOffset.asDriver()
			.flatMap { [weak self] _ in
				return ((self?.collectionView?.isNearBottomEdge(edgeOffset: 150.0)) ?? false)
					? Driver.just(())
					: Driver.empty()
			} ?? Driver.empty()
		
		// When loading the next page triggers only accept one trigger within
		// a period of time to eliminate all the scroll viwe bounce extra triggers.
		loadNextPageTrigger.asObservable()
			.debounce(1.0, scheduler: MainScheduler.instance)
			.observeOn(MainScheduler.instance)
			.subscribe({ [weak self] in
				// This needs to be here so that the paramater passed in gets
				// accessed.  If it's not accessed, then it won't trigger the
				// next page load.
				_ = $0
				
				// Start the network activity indicator since we are loading
				UIApplication.shared.isNetworkActivityIndicatorVisible = true
				
				// Now we need to tell the datasource to load the next page
				// and end refreshing when it's done.
				self?.datasource.next()
					.subscribe({ _ in
						// We are done so turn off the network indicator
						UIApplication.shared.isNetworkActivityIndicatorVisible = false
					})
					.disposed(by: disposeBag)
			})
			.disposed(by: disposeBag)

	}
	
	/// This method handles setting the image to be displayed into the segue
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? ImageViewController {
			if let asyncImage = sender as? AsyncImage{
				vc.image = asyncImage
			}
		}
	}
	
	/// This method sets up a new datasource and binds it to the collection view
	private func generateNewImageDatasource() {
		// Presuming the collection view still exists (it's weak to avoid memory leak)
		if let cv = self.collectionView {
			// Generate the data stream, transform it into table view sections,
			// observe it on the main queue, and then bind the datasource
			// to the collection view.
			datasource.data.asObservable()
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



}
