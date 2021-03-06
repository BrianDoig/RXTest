//
//  ImageViewController.swift
//  RXTest
//
//  Created by Brian Doig on 5/11/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import UIKit
import DataModel
import RxSwift
import RxCocoa

class ImageViewController: UIViewController {
	
	@IBOutlet weak var imageView: UIImageView?
	
	/// Disposes Observables if the controller goes away.
	let disposeBag = DisposeBag()
	
	/// The private backing variable for the image.
	private var _image: AsyncImage? = nil
	
	/// Public interface to the image.  Has the side effect of binding the
	/// image view to the AsyncImage
	var image: AsyncImage? {
		get {
			// Return our value
			return _image
		}
		set(value) {
			// Set our value
			_image = value
			
			// Assuming the view is already loaded
			if let theImageView = imageView {
				// Then bind it to the image view
				_image?.asObservable()
					.map({ $0.image })
					.bind(to: theImageView.rx.image)
					.disposed(by: disposeBag)
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Force the views to be loaded
		_ = self.view

		// Do any additional setup after loading the view.
   }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// If we have both an imageView and the image
		if let theImageView = imageView, let theImage = image {
			// Then bind it to the image view
			theImage.asObservable()
				.map({ $0.image })
				.bind(to: theImageView.rx.image)
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
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
