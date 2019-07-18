//
//  FinanceDebtArchiveVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/15/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class FinanceDebtArchiveVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    public var data_: [AccountBillsJson] = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource = self
        collection.delegate   = self
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtArchiveCell", for: indexPath) as! FinanceDebtArchiveCell
//        cell.display(title: getNameAndMonth(data_[indexPath.row].numMonth ?? 0) + " \(data_[indexPath.row].numYear ?? 0)", desc: (((data_[safe: indexPath.row]?.sum ?? 0.0) - (data_[safe: indexPath.row]?.payment_sum ?? 0.0)).formattedWithSeparator))
        cell.display(title: getNameAndMonth(data_[indexPath.row].numMonth ?? 0) + " \(data_[indexPath.row].numYear ?? 0)", desc: (((data_[safe: indexPath.row]?.sum ?? 0.0)).formattedWithSeparator))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 50.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromFinanceDebtArchiveVC.toReceipt, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceDebtArchiveVC.toReceipt {
            let vc = segue.destination as! FinanceDebtVC
            vc.data_ = data_[index]
        }
    }
}


final class FinanceDebtArchiveCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    fileprivate func display(title: String, desc: String) {
        let d: Double = Double(desc.replacingOccurrences(of: ",", with: "."))!
        var sum = String(format:"%.2f", d)
        if d > 999.00 || d < -999.00{
            let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
            sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
        }
        if sum.first == "-" {
            sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
        }
        self.title.text = title
        self.desc.text  = sum
    }
}
