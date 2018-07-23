//
//  PhotoCell.swift
//  Sminex
//
//  Created by Anton Barbyshev on 23.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

protocol PhotoCellDelegate: class {
    func deleteTap()
}

class PhotoCell: UICollectionViewCell {
    
    // MARK: Outlets
    
    @IBOutlet private weak var imageView: UIImageView!
    
    // MARK: Properties
    
    weak var delegate: PhotoCellDelegate?
    
    // MARK: Functions
    
    func configure(image: UIImage) {
        imageView.image = image
    }
    
    // MARK: Actions
    
    @IBAction private func delete() {
        delegate?.deleteTap()
    }
    
}
