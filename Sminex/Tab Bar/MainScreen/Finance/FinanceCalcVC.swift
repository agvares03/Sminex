//
//  FinanceCalcVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/15/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class FinanceCalcVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: [AccountCalculationsJson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count == 0 ? 0 : data_.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cell = FinanceCalcCell.fromNib()
        if indexPath.row != data_.count {
            cell?.display(data_[indexPath.row])
            
        } else {
            cell?.display( AccountCalculationsJson(type: "Итого", sumAccrued: 0, sumDebt: 0, sumPay: 0) )
        }
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceCalcCell", for: indexPath) as! FinanceCalcCell
        if indexPath.row != data_.count {
            cell.display(data_[indexPath.row])
        
        } else {
            var sumAccured  = 0.0
            var sumDebt     = 0.0
            var sumPay      = 0.0
            
            data_.forEach {
                sumAccured  += $0.sumAccrued    ?? 0.0
                sumDebt     += $0.sumDebt       ?? 0.0
                sumPay      += $0.sumPay        ?? 0.0
            }
            
            cell.display( AccountCalculationsJson(type: "Итого", sumAccrued: sumAccured, sumDebt: sumDebt, sumPay: sumPay) )
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceCalcHeader", for: indexPath) as! FinanceCalcHeader
        header.display(getNameAndMonth(data_.first?.numMonthSet ?? 0) + " \(data_.first?.numYearSet ?? 0)")
        return header
    }
}

final class FinanceCalcHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    fileprivate func display(_ title: String) {
        self.title.text = title
    }
}

final class FinanceCalcCell: UICollectionViewCell {
    
    @IBOutlet private weak var sumAccured:  UILabel!
    @IBOutlet private weak var sumDebt:     UILabel!
    @IBOutlet private weak var sumPay:      UILabel!
    @IBOutlet private weak var title:       UILabel!
    
    fileprivate func display(_ item: AccountCalculationsJson) {
        
        sumAccured.text = Int(item.sumAccrued ?? 0.0).formattedWithSeparator
        sumDebt.text = Int(item.sumDebt ?? 0.0).formattedWithSeparator
        sumPay.text = Int(item.sumPay ?? 0.0).formattedWithSeparator
        title.text = item.type
        
        if item.type == "Итого" {
            sumAccured.font = UIFont.boldSystemFont(ofSize: sumAccured.font.pointSize)
            sumDebt.font    = UIFont.boldSystemFont(ofSize: sumDebt.font.pointSize)
            sumPay.font     = UIFont.boldSystemFont(ofSize: sumPay.font.pointSize)
            title.font      = UIFont.boldSystemFont(ofSize: title.font.pointSize)
        
        } else {
            sumAccured.font = UIFont.systemFont(ofSize: sumAccured.font.pointSize, weight: .light)
            sumDebt.font    = UIFont.systemFont(ofSize: sumDebt.font.pointSize, weight: .light)
            sumPay.font     = UIFont.systemFont(ofSize: sumPay.font.pointSize, weight: .light)
            title.font      = UIFont.systemFont(ofSize: title.font.pointSize, weight: .light)
        }
    }
    
    class func fromNib() -> FinanceCalcCell? {
        var cell: FinanceCalcCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? FinanceCalcCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 75
        return cell
    }
}













