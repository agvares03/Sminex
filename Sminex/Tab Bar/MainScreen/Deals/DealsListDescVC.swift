//
//  DealsListDescVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/10/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import UIScreenExtension

final class DealsListDescVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: DealsJson?
    open var anotherDeals_: [DealsJson] = []
    private var displayDeals: [DealsJson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayDeals = anotherDeals_.filter { return $0.id != data_?.id }
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource = self
        collection.delegate   = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden           = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden           = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayDeals.count <= 3 ? displayDeals.count : 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealsListDescCell", for: indexPath) as! DealsListDescCell
        cell.display(displayDeals[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "DealsListDescHeader", for: indexPath) as! DealsListDescHeader
        header.display(data_)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let storyboard = UIStoryboard(name: "Deals", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "dealDetails") as! DealsListDescVC
        vc.data_ = displayDeals[indexPath.row]
        vc.anotherDeals_ = anotherDeals_
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cell = DealsListDescCell.fromNib()
        cell?.display(anotherDeals_[indexPath.row])
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let header = DealsListDescHeader.fromNib()
        header?.display(data_)
        let size = header?.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
}


final class DealsListDescHeader: UICollectionReusableView {
    
    @IBOutlet         weak var imageHeight:    NSLayoutConstraint!
    @IBOutlet         weak var imageWidth:     NSLayoutConstraint!
    @IBOutlet private weak var image:          UIImageView!
    @IBOutlet private weak var titleLabel:     UILabel!
    @IBOutlet private weak var dateLabel:      UILabel!
    @IBOutlet private weak var bodyLabel:      UILabel!
    @IBOutlet private weak var linksLabel:     UILabel!
    
    open var link_obj:String = "";
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        let url = NSURL(string: link_obj)!
        UIApplication.shared.openURL(url as URL)
    }
    
    func display(_ data_: DealsJson?) {
        
        if data_?.img != nil {
            image.image = data_?.img
        
        } else {
            image.frame.size.height = 0
        }
        
        titleLabel.text = data_?.name
        bodyLabel.text = data_?.body
        
        if data_?.link != "" {
            // Сделаем Перейти на сайт кликабельным
            let tap = UITapGestureRecognizer(target: self, action: #selector(DealsListDescHeader.tapFunction))
            linksLabel.text = "Перейти на сайт"
            linksLabel.isUserInteractionEnabled = true
            linksLabel.addGestureRecognizer(tap)
            link_obj = (data_?.link)!
//            linksLabel.text = "Перейти на сайт: \(data_?.link ?? "")"
        
        } else {
            linksLabel.text = ""
        }
        
        if data_?.dateStop != "" {
            let df = DateFormatter()
            df.dateFormat = "YYYY-MM-DD"
            let date = df.date(from: data_?.dateStop ?? "2018-01-01")
            df.dateFormat = "dd MMMM yyyy"
            df.locale = Locale(identifier: "Ru-ru")
            dateLabel.text = df.string(from: date ?? Date())
        }
        
        titleLabel.preferredMaxLayoutWidth = titleLabel.bounds.size.width
        bodyLabel.preferredMaxLayoutWidth  = bodyLabel.bounds.size.width
        linksLabel.preferredMaxLayoutWidth = linksLabel.bounds.size.width
        
    }
    
    class func fromNib() -> DealsListDescHeader? {
        
        var cell: DealsListDescHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? DealsListDescHeader {
                cell = view
            }
        }
        
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        if (300.0...350.0).contains(points) {
            cell?.imageWidth.constant  = 288
            cell?.imageHeight.constant = 144
            
        } else if (350.0...400.0).contains(points) {
            cell?.imageWidth.constant  = 343
            cell?.imageHeight.constant = 170
            
        } else {
            cell?.imageWidth.constant  = 382
            cell?.imageHeight.constant = 191
        }
        
//        cell?.titleLabel.preferredMaxLayoutWidth = cell?.titleLabel.bounds.size.width ?? 0.0
//        cell?.bodyLabel.preferredMaxLayoutWidth  = cell?.bodyLabel.bounds.size.width  ?? 0.0
//        cell?.linksLabel.preferredMaxLayoutWidth = cell?.linksLabel.bounds.size.width ?? 0.0
        
        return cell
    }
}



final class DealsListDescCell: UICollectionViewCell {
    
    @IBOutlet private weak var image:   UIImageView!
    @IBOutlet private weak var title:   UILabel!
    
    func display(_ item: DealsJson) {
        
        if item.img != nil {
            image.image = item.img
        
        } else {
            image.frame.size.width = 0
        }
        self.title.text = item.name
    }
    
    class func fromNib() -> DealsListDescCell? {
        
        var cell: DealsListDescCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? DealsListDescCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 75
        return cell
    }
}














