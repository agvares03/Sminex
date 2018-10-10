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
    @IBOutlet private weak var dateBtn:     UIButton!
    @IBOutlet private weak var outcome:     UILabel!
    
    @IBOutlet private weak var picker:      UIPickerView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func datePickerPresed(_ sender: UIButton) {
        if picker.isHidden {
            
            //            if !imgScroll.isHidden {
            //                //                sendBtnConst.constant   = 180
            //                //
            //                //            } else {
            //                //                sendBtnConst.constant   = 340
            //                imageConst.constant     = 180
            //            }
            picker.isHidden         = false
        } else {
            picker.isHidden         = true
        }
    }
    
    open var data_:     MeterValue?
    open var period_:   [CounterPeriod]?
    var selectedYear: String?
    var years:[String] = []
    
    private var values: [CounterHistoryCellData] = []
    
    var fraction:       String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Выбор года - уберем с экрана
        picker.isHidden = true
        picker.delegate = self
        
        fraction = data_?.fractionalNumber
        
        res.text = data_?.resource
        name.text = "Счетчик " + (data_?.meterUniqueNum)!
        years.append(period_![0].year!)
        var i = 0
        period_?.forEach { period in
            if period.year! != years[i]{
                years.append(period.year!)
                i += 1
            }
        }
        dateBtn.setTitle("▼ " + period_![0].year!, for: .normal)
        outcome.text = "Расход (" + (data_?.units ?? "") + ")"
        
        self.setData()
        
        collection.delegate     = self
        collection.dataSource   = self
    }
    
    func setData(){
        var metValues: [MeterValue] = []
        var arrInput:[String] = []
        var arrValue:[String] = []
        var predInput = "0,00"
        values.removeAll()
        period_?.forEach { period in
            guard period.year == dateBtn.titleLabel?.text?.replacingOccurrences(of: "▼ ", with: "") else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth ?? "1")
                if val.meterUniqueNum == data_?.meterUniqueNum {
                    metValues.append(val)
                    print(val)
                    arrInput.append(val.valueInput!)
                    arrValue.append(val.value!)
                }
            }
        }
        period_?.forEach { period in
            let str: String = (dateBtn.titleLabel?.text?.replacingOccurrences(of: "▼ ", with: ""))!
            guard period.year == String((Int(str)! - 1)) else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth ?? "1")
                if val.meterUniqueNum == data_?.meterUniqueNum {
                    if predInput == "0,00" && val.valueInput != "0,00"{
                       predInput = val.valueInput!
                    }
                }
            }
        }
        var i = 0
        metValues.forEach {
            var income = "0,00"
            var k = 0
            if income == "0,00"{
                arrValue.forEach {
                    if $0 != "0,00" && k > i && income == "0,00"{
                        income = $0
                        return
                    }
                    k += 1
                }
            }
            var n = 0
            if income == "0,00"{
                arrInput.forEach {
                    if $0 != "0,00" && n > i && income == "0,00"{
                        income = $0
                        return
                    }
                    n += 1
                }
            }
            if income == "0,00"{
                income = predInput
            }
            i += 1
            values.append( CounterHistoryCellData(value: $0.value, previousValue: $0.difference, period: Int($0.period ?? "1") ?? 1, income: income, fraction: fraction!) )
        }
        
        values.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        collection.reloadData()
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

extension CounterHistoryVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return years.count
    }
    
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return years[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        selectedYear = years[row]
        dateBtn.setTitle("▼ " + selectedYear!, for: .normal)
        self.setData()
        picker.isHidden = true
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var label: UILabel
        
        if let view = view as? UILabel {
            label = view
        } else {
            label = UILabel()
        }
        
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont(name: "Menlo-Regular", size: 15)
        
        label.text = years[row]
        
        return label
    }
}

final class CounterHistoryCell: UICollectionViewCell {
    
    @IBOutlet private weak var month:   UILabel!
    @IBOutlet private weak var send:    UILabel!
    @IBOutlet private weak var outcome: UILabel!
    @IBOutlet private weak var income:  UILabel!
    
    fileprivate func display(_ item: CounterHistoryCellData) {
        self.month.text = item.month
        
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





