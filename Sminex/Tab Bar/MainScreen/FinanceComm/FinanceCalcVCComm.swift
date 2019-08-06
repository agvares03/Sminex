//
//  FinanceCalcVCComm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 18/07/2019.
//

import UIKit

class FinanceCalcVCComm: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    public var data_: [AccountCalculationsJson] = []
    public var calcs: [AccountCalculationsJson] = []
    public var index = Int()
    public var date: (Int?, Int?)
    
    @IBAction func SwipeRight(_ sender: UISwipeGestureRecognizer) {
        if index > 0{
            index -= 1
            
        }
    }
    
    @IBAction func SwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if index < calcs.count - 1{
            index += 1
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        for k in 0...data_.count - 1{
            if (data_[k].type?.containsIgnoringCase(find: "пени"))!{
                if UserDefaults.standard.bool(forKey: "denyShowFine"){
                    data_.remove(at: k)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count == 0 ? 0 : data_.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cell = FinanceCalcCommCell.fromNib()
        if indexPath.row != data_.count {
            cell?.display(data_[indexPath.row])
            
        } else {
            cell?.display( AccountCalculationsJson(type: "Итого", sumAccrued: 0, sumDebt: 0, sumPay: 0) )
        }
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceCalcCommCell", for: indexPath) as! FinanceCalcCommCell
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
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceCalcCommHeader", for: indexPath) as! FinanceCalcCommHeader
        header.display(getNameAndMonth(data_.first?.numMonthSet ?? 0) + " \(data_.first?.numYearSet ?? 0)")
        return header
    }
}

final class FinanceCalcCommHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    fileprivate func display(_ title: String) {
        self.title.text = title
    }
}

final class FinanceCalcCommCell: UICollectionViewCell {
    
    @IBOutlet private weak var sumAccured:  UILabel!
    @IBOutlet private weak var sumDebt:     UILabel!
    @IBOutlet private weak var sumPay:      UILabel!
    @IBOutlet private weak var title:       UILabel!
    
    fileprivate func display(_ item: AccountCalculationsJson) {
        var sumA = String(format:"%.2f", item.sumAccrued!)
        if item.sumAccrued! > 999.00 || item.sumAccrued! < -999.00{
            let i = Int(sumA.distance(from: sumA.startIndex, to: sumA.index(of: ".")!)) - 3
            sumA.insert(" ", at: sumA.index(sumA.startIndex, offsetBy: i))
        }
        if sumA.first == "-" {
            sumA.insert(" ", at: sumA.index(sumA.startIndex, offsetBy: 1))
        }
        sumAccured.text = sumA
        
        var sumD = String(format:"%.2f", item.sumDebt!)
        if item.sumDebt! > 999.00 || item.sumDebt! < -999.00{
            let i = Int(sumD.distance(from: sumD.startIndex, to: sumD.index(of: ".")!)) - 3
            sumD.insert(" ", at: sumD.index(sumD.startIndex, offsetBy: i))
        }
        if sumD.first == "-" {
            sumD.insert(" ", at: sumD.index(sumD.startIndex, offsetBy: 1))
        }
        sumDebt.text = sumD
        
        var sumP = String(format:"%.2f", item.sumPay!)
        if item.sumPay! > 999.00 || item.sumPay! < -999.00{
            let i = Int(sumP.distance(from: sumP.startIndex, to: sumP.index(of: ".")!)) - 3
            sumP.insert(" ", at: sumP.index(sumP.startIndex, offsetBy: i))
        }
        if sumP.first == "-" {
            sumP.insert(" ", at: sumP.index(sumP.startIndex, offsetBy: 1))
        }
        sumPay.text = sumP
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
    
    class func fromNib() -> FinanceCalcCommCell? {
        var cell: FinanceCalcCommCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? FinanceCalcCommCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 75
        return cell
    }
}
