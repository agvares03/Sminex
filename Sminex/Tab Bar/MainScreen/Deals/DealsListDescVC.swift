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
import DeviceKit


final class DealsListDescVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    public var data_: DealsJson?
    public var anotherDeals_: [DealsJson] = []
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
        return displayDeals.count
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
        cell?.display(displayDeals[indexPath.row])
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
    @IBOutlet         weak var imageWidth :    NSLayoutConstraint!
    @IBOutlet private weak var image      :    UIImageView!
    @IBOutlet private weak var titleLabel :    UILabel!
    @IBOutlet private weak var dateLabel  :    UILabel!
    @IBOutlet private weak var bodyLabel  :    UILabel!
    @IBOutlet private weak var linksLabel :    UILabel!
    
    public var link_obj:String = "";
    
    @objc func tapFunction(sender:UITapGestureRecognizer) {
        let url: URL = NSURL(string: link_obj)! as URL
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    func display(_ data_: DealsJson?) {
        
        if data_?.img != nil {
            image.image = data_?.img
        } else {
            image.frame.size.height = 0
        }
        let width:Double = Double((data_?.img?.size.width)!)
        let height1:Double = Double((data_?.img?.size.height)!)
        let r: Double =  width / height1
        if r < 1.5{
            image.contentMode = .scaleToFill
        }
        titleLabel.text = data_?.name
        bodyLabel.text = data_?.body
        
        func heightForTitle(text:String, width:CGFloat) -> CGFloat{
            titleLabel.numberOfLines = 0
            titleLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            titleLabel.text = text
            
            titleLabel.sizeToFit()
            return titleLabel.frame.height
        }
        
        func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
            bodyLabel.numberOfLines = 0
            bodyLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
            bodyLabel.font = font
            bodyLabel.text = text
            
            bodyLabel.sizeToFit()
            return bodyLabel.frame.height
        }
        
        let font = UIFont(name: "Helvetica", size: 16.0)
        
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
        let height = heightForView(text: bodyLabel.text!, font: font!, width: bodyLabel.preferredMaxLayoutWidth)
        let height2 = heightForTitle(text: titleLabel.text!, width: titleLabel.preferredMaxLayoutWidth)
        bodyLabel.bounds.size.height = height + 20
        titleLabel.bounds.size.height = height2 + 50
        linksLabel.preferredMaxLayoutWidth = linksLabel.bounds.size.width
        
        if (UIDevice.current.modelName.contains(find: "iPhone 4")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 4s")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5c")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5s")) {
//          ||  (UIDevice.current.modelName.contains(find: "Simulator")) {
            
            imageWidth.constant  = 304
            imageHeight.constant = 150
            
        } else {
            
            let points = Double(UIScreen.pixelsPerInch ?? 0.0)
            if (250.0...280.0).contains(points) {
                imageWidth.constant  = 834
                imageHeight.constant = 450
            }else if (300.0...320.0).contains(points) {
                imageWidth.constant  = 288
                imageHeight.constant = 144
                image.contentMode = .scaleToFill
            } else if (320.0...350.0).contains(points) {
                
                imageWidth.constant  = 304
                imageHeight.constant = 170
                image.contentMode = .scaleToFill
                if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .iPhone5 || Device() == .simulator(.iPhone5){
                    imageWidth.constant  = 288
                    imageHeight.constant = 144
                }
            } else if (350.0...400.0).contains(points) {
                imageWidth.constant  = 343
                imageHeight.constant = 144
                image.contentMode = .scaleToFill
            } else if (400.0...450.0).contains(points) {
                imageWidth.constant  = 382
                imageHeight.constant = 180
                image.contentMode = .scaleToFill
            } else {
//                imageWidth.constant  = 382
//                imageHeight.constant = 175
                imageWidth.constant  = 304
                imageHeight.constant = 170
                image.contentMode = .scaleToFill
            }
        } 
        
    }
    
    class func fromNib() -> DealsListDescHeader? {
        
        var cell: DealsListDescHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? DealsListDescHeader {
                cell = view
            }
        }
        
//        if (300.0...350.0).contains(points) {
//            cell?.imageWidth.constant  = 343
//            cell?.imageHeight.constant = 174
//
//        } else if (350.0...400.0).contains(points) {
//            cell?.imageWidth.constant  = 343
//            cell?.imageHeight.constant = 170
//
//        } else {
//            cell?.imageWidth.constant  = 382
//            cell?.imageHeight.constant = 191
//        }
        
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
        image.contentMode = .scaleToFill
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














