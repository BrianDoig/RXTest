//
//  ImageCollectionViewCell.swift
//  RXTest
//
//  Created by Brian Doig on 5/10/17.
//  Copyright © 2017 Brian Doig. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImageCollectionViewCell: UICollectionViewCell {
    
	@IBOutlet weak var imageView: UIImageView?
	
	override func prepareForReuse() {
		if let image = self.imageView?.rx.image {
			Variable<UIImage?>(nil).asObservable().bind(to: image).dispose()
		}
	}
}
