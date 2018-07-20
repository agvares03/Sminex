//
//  CounterHistoryVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/29/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire

final class CounterHistoryVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate {
    
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var res:         UILabel!
    @IBOutlet private weak var name:        UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var outcome:     UILabel!
    
    @IBOutlet private weak var picker:      UIPickerView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_:     MeterValue?
    open var period_:   [CounterPeriod]?
    
    private var values: [CounterHistoryCellData] = []
    
    var fraction:       String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Выбор года - уберем с экрана
        picker.isHidden = true
        
        fraction = data_?.fractionalNumber
        
        res.text = data_?.resource
        name.text = "Счетчик " + (data_?.meterUniqueNum)!
        date.text = period_![0].year
        outcome.text = "Расход (" + (data_?.units ?? "") + ")"
        
        var metValues: [MeterValue] = []
        
        period_?.forEach { period in
            
            guard period.year == period_?.first?.year else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth ?? "1")
                if val.meterUniqueNum == data_?.meterUniqueNum {
                    metValues.append(val)
                    
                }
            }
        }
        
        metValues.forEach {
           values.append( CounterHistoryCellData(value: $0.value, previousValue: $0.difference, period: Int($0.period ?? "1") ?? 1, income: $0.valueInput ?? "", fraction: fraction!) )
        }
        
        values.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        
        collection.delegate     = self
        collection.dataSource   = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return values.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryCell", for: indexPath) as! CounterHistoryCell
        cell.display(values[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collection.frame.size.width, height: 30.0)
    }
}

final class CounterHistoryCell: UICollectionViewCell {
    
    @IBOutlet private weak var month:   UILabel!
    @IBOutlet private weak var send:    UILabel!
    @IBOutlet private weak var outcome: UILabel!
    @IBOutlet private weak var income:  UILabel!
    
    fileprivate func display(_ item: CounterHistoryCellData) {
        
        self.month.text     = item.month
        if item.fractionNumber.contains(find: "alse") {
            self.send.text      = item.send.replacingOccurrences(of: ",00", with: "")
            self.outcome.text   = item.outcome.replacingOccurrences(of: ",00", with: "")
            self.income.text    = item.income.replacingOccurrences(of: ",00", with: "")
        } else {
            self.send.text      = item.send
            self.outcome.text   = item.outcome
            self.income.text    = item.income
        }
    }
}

private final class CounterHistoryCellData {
    
    let month:           String
    let send:            String
    let outcome:         String
    let income:          String
    let fractionNumber:  String
    
    init(value: String?, previousValue: String?, period: Int, income: String, fraction: String) {
        
        send = value ?? ""
        outcome = previousValue ?? ""
        self.income  = income
        
        self.fractionNumber = fraction
        
        if period == 1 {
            month = "Январь"
        } else if period == 2 {
            month = "Февраль"
        } else if period == 3 {
            month = "Март"
        } else if period == 4 {
            month = "Апрель"
        } else if period == 5 {
            month = "Май"
        } else if period == 6 {
            month = "Июнь"
        } else if period == 7 {
            month = "Июль"
        } else if period == 8 {
            month = "Август"
        } else if period == 9 {
            month = "Сентябрь"
        } else if period == 10 {
            month = "Октябрь"
        } else if period == 11 {
            month = "Ноябрь"
        } else {
            month = "Декабрь"
        }
    }
}





