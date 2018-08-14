//
//  PhotoCell.swift
//  Sminex
//
//  Created by Anton Barbyshev on 23.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

protocol PhotoCellDelegate: class {
    func deleteTap(sender: UICollectionViewCell)
}

class PhotoCell: UICollectionViewCell {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: Properties
    
    weak var delegate: PhotoCellDelegate?
    
    // MARK: Functions
    
    func configure(image: UIImage) {
        imageView.image = image
    }
    
    // MARK: Actions
    
    @IBAction private func delete() {
        delegate?.deleteTap(sender: self)
    }
    
    // MARK: View lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 6
    }
    
}
