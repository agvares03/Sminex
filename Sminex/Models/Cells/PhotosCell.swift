//
//  PhotosCell.swift
//  Sminex
//
//  Created by Anton Barbyshev on 23.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

protocol PhotosCellDelegate: class {
    func photoDidDelete(index: Int)
    func photoDidOpen(index: Int)
}

class PhotosCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    weak var delegate: PhotosCellDelegate?
    private var images = [UIImage]()
    
    // MARK: Functions
    
    func configure(images: [UIImage]) {
        self.images = images
        collectionView.reloadData()
    }
    
    // MARK: View lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

extension PhotosCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        cell.delegate = self
        cell.configure(image: images[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.photoDidOpen(index: indexPath.row)
    }
    
}

extension PhotosCell: PhotoCellDelegate {
    
    func deleteTap() {
        
    }
    
}
