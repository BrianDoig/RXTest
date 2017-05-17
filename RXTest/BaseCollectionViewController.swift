//
//  BaseCollectionViewController.swift
//  RXTest
//
//  Created by Brian Doig on 5/17/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import UIKit
import DataModel
import RxSwift
import RxCocoa
import Swiftz

class BaseCollectionViewController: UICollectionViewController {
	/// Collection view cell reuse identifier
	var reuseIdentifier = ""
	
	/// This is the datasource for the collection view
	let cvDataSource = RxCollectionViewSectionedReloadDataSource<SectionOfImageCellData>()
	
	/// This is allows all the data streams to be deallocated when the view
	/// controller is deallocated.
	let disposeBag = DisposeBag()
	
	/// This is the refresh control for the collection view.
	let refreshControl = UIRefreshControl()
	
	/// This is the datasource that has it's data fed into the cvDataSource
	/// This must be set in a child class prior to super.viewDidLoad() being
	/// called.
	var datasource: ImageDataSource! = nil
	
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
	
	/// Calculate the number of objects for a page based on how big the screen is.
	/// This is needed since the page size must be big enough to cover the whole
	/// screen when displayed in order to trigger the detection of reaching the
	/// bottom of the scroll view since it's filtering out duplicate events.
	private func calculatePageSize() {
		// Get the size of the collection view
		let size = self.collectionView?.bounds.size ?? CGSize(width: 2048, height: 1536)
		
		// Our cells are 104x104 with padding but this gives slightly more than we need to fill screen
		let cellSize = CGSize(width: 100, height: 100)
		
		// Figure out how many items per page we need 
		let pageSize = Int((size.width * size.height) / (cellSize.width * cellSize.height))
		
		// Set the size into the datasource.
		self.datasource.pageSize = pageSize
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Determine the number of cells per page needed
		calculatePageSize()
		
		// Set up the refresh control
		collectionView?.refreshControl = refreshControl
		refreshControl.addTarget(self, action: #selector(BaseCollectionViewController.refresh), for: .valueChanged)
		
		// Create the callback that generates collection view cells
		// Unowned OK because as long as the datasource exists, so does the
		// collection view.
		cvDataSource.configureCell = { [unowned self] (ds, cv, ip, item) in
			// Dequeue the cell and force cast it.  Not super safe but it
			// should not change and if it does, it will break immidiatly.
			let cell = cv.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: ip) as! ImageCollectionViewCell
			
			// As long as self still exists, and we have an imageView that is not nil
			if let imageView = cell.imageView {
				// Bind the image stream to the image view
				item.image.thumbnail.asObservable()
					.map({ $0.image })
					.bind(to: imageView.rx.image)
					.disposed(by: self.disposeBag)
				
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
		
		if let cv = self.collectionView {
			
			// Create the end of page trigger.  It looks if the collection view is
			// within 20 points of the end of the view and if so it tries to load the
			// next page.
			cv.rx.contentOffset
				.asDriver()
				.map({ [weak self] (cv) -> Bool in
					// Since the offest changed, ask the collection view if we are
					// near the bottom of the edge.  It then returns true or false
					// for the event.
					return (self?.collectionView?.isNearBottomEdge(edgeOffset: 5.0)) ?? false
				})
				.distinctUntilChanged() // This filters out duplicate trues and duplicate falses to prevent a reload for each pixel the scroll view moves near the bottom.
				.asObservable()
				.observeOn(MainScheduler.instance)
				.subscribe({ [weak self] in
					// Only load the next page when we recieve true.
					if $0.element == true {
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
					}
				})
				.disposed(by: disposeBag)
		}
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
				.map({ (images) -> [SectionOfImageCellData] in
					return [
						SectionOfImageCellData(header: "", items: images.map(ImageCellData.init))
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
