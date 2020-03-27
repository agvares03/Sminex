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
    
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var collection2:     UICollectionView!
    @IBOutlet private weak var collection3:     UICollectionView!
    @IBOutlet private weak var res:             UILabel!
    @IBOutlet private weak var name:            UILabel!
    @IBOutlet private weak var tarifName1:      UILabel!
    @IBOutlet private weak var tarifName2:      UILabel!
    @IBOutlet private weak var tarifName3:      UILabel!
    @IBOutlet private weak var dateBtn:         UIButton!
    @IBOutlet private weak var dateBtn2:        UIButton!
    @IBOutlet private weak var dateBtn3:        UIButton!
    @IBOutlet private weak var outcome:         UILabel!
    @IBOutlet private weak var outcome2:        UILabel!
    @IBOutlet private weak var outcome3:        UILabel!
    @IBOutlet private weak var lastCount:       UILabel!
    @IBOutlet private weak var lastCount2:      UILabel!
    @IBOutlet private weak var lastCount3:      UILabel!
    @IBOutlet private weak var resHeight:       NSLayoutConstraint!
    @IBOutlet private weak var collHeight1:     NSLayoutConstraint!
    @IBOutlet private weak var collHeight2:     NSLayoutConstraint!
    @IBOutlet private weak var collHeight3:     NSLayoutConstraint!
    @IBOutlet private weak var nameHeight1:     NSLayoutConstraint!
    @IBOutlet private weak var nameHeight2:     NSLayoutConstraint!
    @IBOutlet private weak var nameHeight3:     NSLayoutConstraint!
    @IBOutlet private weak var picker:          UIPickerView!
    @IBOutlet private weak var picker2:         UIPickerView!
    @IBOutlet private weak var picker3:         UIPickerView!
    @IBOutlet private weak var view2:           UIView!
    @IBOutlet private weak var view3:           UIView!
    @IBOutlet private weak var dateIcon:        UIImageView!
    @IBOutlet private weak var dateIcon2:       UIImageView!
    @IBOutlet private weak var dateIcon3:       UIImageView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func datePickerPresed(_ sender: UIButton) {
        if picker.isHidden {
            self.dateIcon.image = UIImage(named: "expanded")
            self.dateIcon2.image = UIImage(named: "expanded")
            self.dateIcon3.image = UIImage(named: "expanded")
            picker.isHidden         = false
            picker2.isHidden         = false
            picker3.isHidden         = false
        } else {
            self.dateIcon.image = UIImage(named: "expand")
            self.dateIcon2.image = UIImage(named: "expand")
            self.dateIcon3.image = UIImage(named: "expand")
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
        view2.isHidden = true
        view3.isHidden = true
        tarifName2.isHidden = true
        tarifName3.isHidden = true
        collection2.isHidden = true
        collection3.isHidden = true
        collHeight1.constant = 380
        collHeight2.constant = 0
        collHeight3.constant = 0
        nameHeight2.constant = 0
        nameHeight3.constant = 0
        let tarif1 = "Тариф - Т1(" + (data_?.tarifName1)! + ")"
        tarifName1.text = tarif1.uppercased()
        if data_?.typeTarif == "2"{
            view2.isHidden = false
            collection2.isHidden = false
            collHeight2.constant = 380
            nameHeight2.constant = 40
            tarifName2.isHidden = false
            let tarif2 = "Тариф - Т2(" + (data_?.tarifName2)! + ")"
            tarifName2.text = tarif2.uppercased()
        }else if data_?.typeTarif == "3"{
            view2.isHidden = false
            view3.isHidden = false
            collection2.isHidden = false
            collection3.isHidden = false
            tarifName2.isHidden = false
            tarifName3.isHidden = false
            collHeight2.constant = 380
            collHeight3.constant = 380
            nameHeight2.constant = 40
            nameHeight3.constant = 40
            let tarif2 = "Тариф - Т2(" + (data_?.tarifName2)! + ")"
            let tarif3 = "Тариф - Т3(" + (data_?.tarifName3)! + ")"
            tarifName2.text = tarif2.uppercased()
            tarifName3.text = tarif3.uppercased()
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
        resHeight.constant = heightForView(text: data_?.resource ?? "", font: res.font, width: view.frame.size.width - 48)
        name.text = "Счетчик " + (data_?.meterUniqueNum)!
        years.append(period_![0].year!)
        selectedYear = period_![0].year!
        var i = 0
        period_?.forEach { period in
            if period.year! != years[i]{
                years.append(period.year!)
                i += 1
            }
        }
        dateBtn.setTitle(period_![0].year!, for: .normal)
        dateBtn2.setTitle(period_![0].year!, for: .normal)
        dateBtn3.setTitle(period_![0].year!, for: .normal)
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
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
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
        values2.removeAll()
        values3.removeAll()
        period_?.forEach { period in
            guard period.year == selectedYear else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth!)
                if val.meterUniqueNum == data_?.meterUniqueNum {
                    metValues.append(val)
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
            guard period.year == String((Int(selectedYear!)! - 1)) else { return }
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
        print(metValues.count)
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
            values.append( CounterHistoryCellData(value: $0.value1, previousValue: $0.difference1, period: Int($0.period ?? "1") ?? 1, income: $0.previousValue1!, fraction: fraction!) )
            if data_?.typeTarif == "2"{
                values2.append( CounterHistoryCellData(value: $0.value2, previousValue: $0.difference2, period: Int($0.period ?? "1") ?? 1, income: $0.previousValue2!, fraction: fraction!) )
            }else if data_?.typeTarif == "3"{
                values2.append( CounterHistoryCellData(value: $0.value2, previousValue: $0.difference2, period: Int($0.period ?? "1") ?? 1, income: $0.previousValue2!, fraction: fraction!) )
                values3.append( CounterHistoryCellData(value: $0.value3, previousValue: $0.difference3, period: Int($0.period ?? "1") ?? 1, income: $0.previousValue3!, fraction: fraction!) )
            }
        }
        var dat = ""
        values.forEach{
            dat = dat + ", " + $0.month
        }
        print(dat)
        values.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        values2.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        values3.sort { (Int($0.month) ?? 0 > Int($1.month) ?? 0) }
        collection.reloadData()
        collection2.reloadData()
        collection3.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collection{
            if values.count > 6{
                self.collHeight1.constant = 302
                return values.count
            }else if values.count > 0{
                self.collHeight1.constant = 130 + CGFloat(30 * values.count)
                return values.count
            }else{
                self.collHeight1.constant = 0
                return 0
            }
        }else if collectionView == collection2{
            if values2.count > 6{
                self.collHeight2.constant = 302
                return values2.count
            }else if values2.count > 0{
                self.collHeight2.constant = 130 + CGFloat(30 * values2.count)
                return values2.count
            }else{
                self.collHeight2.constant = 0
                return 0
            }
        }else{
            if values3.count > 6{
                self.collHeight3.constant = 302
                return values3.count
            }else if values3.count != 0{
                self.collHeight3.constant = 130 + CGFloat(30 * values3.count)
                return values3.count
            }else{
                self.collHeight3.constant = 0
                return 0
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collection{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryNewCell", for: indexPath) as! CounterHistoryNewCell
            lastCount.text = values[0].income.replacingOccurrences(of: ",00", with: "") + " " + (data_?.units ?? "")
            cell.display(values[indexPath.row])
            return cell
        }else if collectionView == collection2{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryNewCell2", for: indexPath) as! CounterHistoryNewCell
            lastCount2.text = values[0].income.replacingOccurrences(of: ",00", with: "") + " " + (data_?.units ?? "")
            cell.display(values2[indexPath.row])
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterHistoryNewCell3", for: indexPath) as! CounterHistoryNewCell
            lastCount3.text = values[0].income.replacingOccurrences(of: ",00", with: "") + " " + (data_?.units ?? "")
            cell.display(values3[indexPath.row])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collection{
            return CGSize(width: collection.frame.size.width - 32, height: 30.0)
        }else if collectionView == collection2{
            return CGSize(width: collection2.frame.size.width - 32, height: 30.0)
        }else{
            return CGSize(width: collection3.frame.size.width - 32, height: 30.0)
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
        DispatchQueue.main.async {
            self.dateBtn.setTitle(self.selectedYear!, for: .normal)
            self.dateBtn2.setTitle(self.selectedYear!, for: .normal)
            self.dateBtn3.setTitle(self.selectedYear!, for: .normal)
            self.dateIcon.image = UIImage(named: "expand")
            self.dateIcon2.image = UIImage(named: "expand")
            self.dateIcon3.image = UIImage(named: "expand")
            self.picker.isHidden = true
            self.picker2.isHidden = true
            self.picker3.isHidden = true
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var label: UILabel
        
        if let view = view as? UILabel {
            label = view
        } else {
            label = UILabel()
        }
        
        label.textColor = mainGrayColor
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
