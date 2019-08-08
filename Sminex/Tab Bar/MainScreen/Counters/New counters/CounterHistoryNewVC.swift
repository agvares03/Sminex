//
//  CounterHistoryNewVC.swift
//  Sminex
//
//  Created by Sergey Ivanov on 02/08/2019.
//

import UIKit
import Alamofire
import DeviceKit

class CounterHistoryNewVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate {
    
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var collection2:  UICollectionView!
    @IBOutlet private weak var collection3:  UICollectionView!
    @IBOutlet private weak var res:         UILabel!
    @IBOutlet private weak var name:        UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var dateBtn:     UIButton!
    @IBOutlet private weak var dateBtn2:     UIButton!
    @IBOutlet private weak var dateBtn3:     UIButton!
    @IBOutlet private weak var outcome:     UILabel!
    @IBOutlet private weak var outcome2:     UILabel!
    @IBOutlet private weak var outcome3:     UILabel!
    @IBOutlet private weak var collHeight1: NSLayoutConstraint!
    @IBOutlet private weak var collHeight2: NSLayoutConstraint!
    @IBOutlet private weak var collHeight3: NSLayoutConstraint!
    @IBOutlet private weak var picker:      UIPickerView!
    @IBOutlet private weak var picker2:      UIPickerView!
    @IBOutlet private weak var picker3:      UIPickerView!
    @IBOutlet private weak var view2:       UIView!
    @IBOutlet private weak var view3:       UIView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func datePickerPresed(_ sender: UIButton) {
        if picker.isHidden {
            picker.isHidden         = false
            picker2.isHidden         = false
            picker3.isHidden         = false
        } else {
            picker.isHidden         = true
            picker2.isHidden         = true
            picker3.isHidden         = true
        }
    }
    
    public var data_:     MeterValue?
    public var period_:   [CounterPeriod]?
    var selectedYear: String?
    var years:[String] = []
    
    private var values: [CounterHistoryCellData] = []
    private var values2: [CounterHistoryCellData] = []
    private var values3: [CounterHistoryCellData] = []
    
    var fraction:       String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .iPhone5 || Device() == .simulator(.iPhone5){
            res.font = res.font.withSize(16)
            dateBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            dateBtn2.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            dateBtn3.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        }
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        if (250.0...280.0).contains(points) {
            name.font = name.font.withSize(22)
            name.minimumScaleFactor = 1
        }
        view2.isHidden = true
        view3.isHidden = true
        collection2.isHidden = true
        collection3.isHidden = true
        if data_?.typeTarif == "2"{
            view2.isHidden = false
            collection2.isHidden = false
        }else if data_?.typeTarif == "3"{
            view2.isHidden = false
            view3.isHidden = false
            collection2.isHidden = false
            collection3.isHidden = false
        }
        // Выбор года - уберем с экрана
        picker.isHidden = true
        picker.delegate = self
        picker2.isHidden = true
        picker2.delegate = self
        picker3.isHidden = true
        picker3.delegate = self
        
        fraction = data_?.fractionalNumber
        
        res.text = data_?.resource
        if res.text!.contains(find: "лектроэнергия"){
            res.text = res.text! + "\n"
        }
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
        dateBtn2.setTitle("▼ " + period_![0].year!, for: .normal)
        dateBtn3.setTitle("▼ " + period_![0].year!, for: .normal)
        outcome.text = "Расход (" + (data_?.units ?? "") + ")"
        outcome2.text = "Расход (" + (data_?.units ?? "") + ")"
        outcome3.text = "Расход (" + (data_?.units ?? "") + ")"
        
        self.setData()
        
        collection.delegate     = self
        collection.dataSource   = self
        collection2.delegate     = self
        collection2.dataSource   = self
        collection3.delegate     = self
        collection3.dataSource   = self
    }
    
    func setData(){
        var metValues: [MeterValue] = []
        var arrInput:[String] = []
        var arrValue:[String] = []
        var arrInput2:[String] = []
        var arrValue2:[String] = []
        var arrInput3:[String] = []
        var arrValue3:[String] = []
        var predInput = "0,00"
        var predInput2 = "0,00"
        var predInput3 = "0,00"
        values.removeAll()
        period_?.forEach { period in
            guard period.year == dateBtn.titleLabel?.text?.replacingOccurrences(of: "▼ ", with: "") else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth ?? "1")
                if val.meterUniqueNum == data_?.meterUniqueNum {
                    metValues.append(val)
                    print(val)
                    arrInput.append(val.valueInput1!)
                    arrValue.append(val.value1!)
                    if data_?.typeTarif == "2"{
                        arrInput2.append(val.valueInput2!)
                        arrValue2.append(val.value2!)
                    }else if data_?.typeTarif == "3"{
                        arrInput2.append(val.valueInput2!)
                        arrValue2.append(val.value2!)
                        arrInput3.append(val.valueInput3!)
                        arrValue3.append(val.value3!)
                    }
                }
            }
        }
        period_?.forEach { period in
            let str: String = (dateBtn.titleLabel?.text?.replacingOccurrences(of: "▼ ", with: ""))!
            guard period.year == String((Int(str)! - 1)) else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth ?? "1")
                if val.meterUniqueNum == data_?.meterUniqueNum {
                    if predInput == "0,00" && val.valueInput1 != "0,00"{
                        predInput = val.valueInput1!
                    }
                    if data_?.typeTarif == "2"{
                        if predInput2 == "0,00" && val.valueInput2 != "0,00"{
                            predInput2 = val.valueInput2!
                        }
                    }else if data_?.typeTarif == "3"{
                        if predInput2 == "0,00" && val.valueInput2 != "0,00"{
                            predInput2 = val.valueInput2!
                        }
                        if predInput3 == "0,00" && val.valueInput3 != "0,00"{
                            predInput3 = val.valueInput3!
                        }
                    }
                }
            }
        }
        var i = 0
        metValues.forEach {
            var income = "0,00"
            var income2 = "0,00"
            var income3 = "0,00"
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
            if data_?.typeTarif == "2"{
                if income2 == "0,00"{
                    arrValue2.forEach {
                        if $0 != "0,00" && k > i && income2 == "0,00"{
                            income2 = $0
                            return
                        }
                        k += 1
                    }
                }
            }else if data_?.typeTarif == "3"{
                if income2 == "0,00"{
                    arrValue2.forEach {
                        if $0 != "0,00" && k > i && income2 == "0,00"{
                            income2 = $0
                            return
                        }
                        k += 1
                    }
                }
                if income2 == "0,00"{
                    arrValue3.forEach {
                        if $0 != "0,00" && k > i && income3 == "0,00"{
                            income3 = $0
                            return
                        }
                        k += 1
                    }
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
            if data_?.typeTarif == "2"{
                if income2 == "0,00"{
                    arrValue2.forEach {
                        if $0 != "0,00" && n > i && income2 == "0,00"{
                            income2 = $0
                            return
                        }
                        k += 1
                    }
                }
            }else if data_?.typeTarif == "3"{
                if income2 == "0,00"{
                    arrValue2.forEach {
                        if $0 != "0,00" && n > i && income2 == "0,00"{
                            income2 = $0
                            return
                        }
                        k += 1
                    }
                }
                if income2 == "0,00"{
                    arrValue3.forEach {
                        if $0 != "0,00" && n > i && income3 == "0,00"{
                            income3 = $0
                            return
                        }
                        k += 1
                    }
                }
            }
            if income == "0,00"{
                income = predInput
            }
            if income2 == "0,00"{
                income2 = predInput2
            }
            if income3 == "0,00"{
                income3 = predInput3
            }
            i += 1
            values.append( CounterHistoryCellData(value: $0.value1, previousValue: $0.difference1, period: Int($0.period ?? "1") ?? 1, income: income, fraction: fraction!) )
            if data_?.typeTarif == "2"{
                values2.append( CounterHistoryCellData(value: $0.value2, previousValue: $0.difference2, period: Int($0.period ?? "1") ?? 1, income: income2, fraction: fraction!) )
            }else if data_?.typeTarif == "3"{
                values2.append( CounterHistoryCellData(value: $0.value2, previousValue: $0.difference2, period: Int($0.period ?? "1") ?? 1, income: income2, fraction: fraction!) )
                values3.append( CounterHistoryCellData(value: $0.value3, previousValue: $0.difference3, period: Int($0.period ?? "1") ?? 1, income: income3, fraction: fraction!) )
            }
        }
        
        values.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        values2.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        values3.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        collection.reloadData()
        collection2.reloadData()
        collection3.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.collHeight1.constant = 1000
        self.collHeight2.constant = 1000
        self.collHeight2.constant = 1000
        var height1: CGFloat = 0
        for cell in self.collection.visibleCells {
            height1 += cell.bounds.height
        }
        self.collHeight1.constant = height1
        var height2: CGFloat = 0
        for cell in self.collection2.visibleCells {
            height2 += cell.bounds.height
        }
        self.collHeight2.constant = height2
        var height3: CGFloat = 0
        for cell in self.collection3.visibleCells {
            height3 += cell.bounds.height
        }
        self.collHeight3.constant = height3
        if collectionView == collection{
            return values.count
        }else if collectionView == collection2{
            return values2.count
        }else{
            return values3.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collection{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryNewCell", for: indexPath) as! CounterHistoryNewCell
            cell.display(values[indexPath.row])
            return cell
        }else if collectionView == collection2{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryNewCell2", for: indexPath) as! CounterHistoryNewCell
            cell.display(values2[indexPath.row])
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryNewCell3", for: indexPath) as! CounterHistoryNewCell
            cell.display(values3[indexPath.row])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collection{
            return CGSize(width: collection.frame.size.width, height: 30.0)
        }else if collectionView == collection2{
            return CGSize(width: collection2.frame.size.width, height: 30.0)
        }else{
            return CGSize(width: collection3.frame.size.width, height: 30.0)
        }
    }
}

extension CounterHistoryNewVC: UIPickerViewDelegate, UIPickerViewDataSource {
    
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
        self.setData()
        dateBtn.setTitle("▼ " + selectedYear!, for: .normal)
        dateBtn2.setTitle("▼ " + selectedYear!, for: .normal)
        dateBtn3.setTitle("▼ " + selectedYear!, for: .normal)
        picker.isHidden = true
        picker2.isHidden = true
        picker3.isHidden = true
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

final class CounterHistoryNewCell: UICollectionViewCell {
    
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