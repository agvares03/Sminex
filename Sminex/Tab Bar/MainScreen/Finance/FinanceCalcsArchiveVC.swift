//
//  FinanceCalcsArchiveVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/15/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit


final class FinanceCalcsArchiveVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    public var data_:           [AccountCalculationsJson] = []
    private var filteredData: [AccountCalculationsJson] = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var currMonth = 0
        filteredData = data_.filter {
            if ($0.numMonthSet ?? 0) != currMonth {
                currMonth = ($0.numMonthSet ?? 0)
                return true
            }
            return false
        }
        
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 50.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromFinanceCalcsArchive.toCalc, sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceCalcsArchiveCell", for: indexPath) as! FinanceCalcsArchiveCell
        var debt = 0.0
        let currDate = (filteredData[indexPath.row].numMonthSet, filteredData[indexPath.row].numYearSet)
        data_.forEach {
            if ($0.numMonthSet == currDate.0 && $0.numYearSet == currDate.1) {
                debt += ($0.sumDebt ?? 0.0)
            }
        }
        cell.display(title: getNameAndMonth(filteredData[indexPath.row].numMonthSet ?? 0) + " \(filteredData[indexPath.row].numYearSet ?? 0)",
            desc: debt != 0.0 ? "Долг \(debt.formattedWithSeparator)" : "")
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceCalcsArchive.toCalc {
            let vc = segue.destination as! FinanceCalcVC
            let date = (filteredData[index].numMonthSet, filteredData[index].numYearSet)
            vc.data_ = data_.filter {
                return (date.0 == $0.numMonthSet && date.1 == $0.numYearSet)
            }
        }
    }
}

final class FinanceCalcsArchiveCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    fileprivate func display(title: String, desc: String) {
        self.title.text = title
        self.desc.text  = desc
    }
}
