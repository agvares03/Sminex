//
//  CounterCellNew.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit

final class CounterCellNew: UICollectionViewCell {
    @IBOutlet private weak var sendLbl:         UILabel!
    @IBOutlet private weak var counter_name:    UILabel!
    @IBOutlet private weak var income:          UILabel!
    @IBOutlet private weak var outcome:         UILabel!
    @IBOutlet private weak var dateSend:        UILabel!
    @IBOutlet private weak var kolTarif:        UILabel!
    @IBOutlet private weak var tarifBot:        NSLayoutConstraint!
    @IBOutlet private weak var tarifHeight:     NSLayoutConstraint!
    @IBOutlet private weak var oneTarif:        UILabel!
    @IBOutlet private weak var oneTarifDrop:    UILabel!
    @IBOutlet private weak var oneTarifLbl:     UILabel!
    @IBOutlet private weak var oneTarifWidth:   NSLayoutConstraint!
    @IBOutlet private weak var twoTarif:        UILabel!
    @IBOutlet private weak var twoTarifDrop:    UILabel!
    @IBOutlet private weak var twoTarifLbl:     UILabel!
    @IBOutlet private weak var tarif:           UILabel!
    @IBOutlet private weak var tarifDrop:       UILabel!
    @IBOutlet private weak var tarifLbl:        UILabel!
    @IBOutlet private weak var tarifWidth:      NSLayoutConstraint!
    @IBOutlet private weak var tarifLine:       UILabel!
    @IBOutlet private weak var dateCheck:       UILabel!
    @IBOutlet private weak var dateCheckLbl:    UILabel!
    @IBOutlet private weak var dateCheckHeight: NSLayoutConstraint!
    @IBOutlet private weak var sendBtn:         UIButton!
    
    @IBAction private func go_action(_ sender: UIButton) {
        self.delegate2.pressed(index: index)
    }
    var delegate : UIViewController!
    var delegate2: NewCounterDelegate!
    var index = 0
    func display(_ item: MeterValue, delegate: UIViewController, index: Int, delegate2: NewCounterDelegate, date: String, canCount: Bool) {
        let dateFrom = UserDefaults.standard.integer(forKey: "meterReadingsDayFrom")
        let dateTo = UserDefaults.standard.integer(forKey: "meterReadingsDayTo")
        let calendar = Calendar.current
        let curDay = calendar.component(.day, from: Date())
        if curDay > dateTo || curDay < dateFrom{
            sendLbl.text = "Передача показаний за этот месяц осуществляется с \(dateFrom) по \(dateTo) число"
        }else if !canCount{
            sendLbl.text = "Данные по приборам учета собираются УК самостоятельно"
        }else{
            sendLbl.text = "Передача показаний за этот месяц осуществляется с \(dateFrom) по \(dateTo) число"
        }
        self.delegate = delegate
        self.delegate2 = delegate2
        self.index = index
        if canCount{
            sendBtn.isHidden = false
        }else{
            sendBtn.isHidden = true
        }
        counter_name.text = "Счетчик №" + item.meterUniqueNum!
        var dat = date
        date.forEach{_ in 
            if dat.contains(find: " "){
                dat.removeLast()
            }
        }
        var dat1 = dat.components(separatedBy: ".")
        dat = dat1[0] + " " + getNameAndMonth(dat1[1]) + " " + dat1[2]
        dateSend.text = dat
        dateCheck.text = item.checkDate
        if item.checkDate == ""{
            dateCheck.isHidden = true
            dateCheckLbl.isHidden = true
            dateCheckHeight.constant = 10
        }else{
            dateCheck.isHidden = false
            dateCheckLbl.isHidden = false
            dateCheckHeight.constant = 70
        }
        
        if item.value1 == "" || item.value1 == " " || item.value1 == "-" || item.value1 == nil{
            income.text = "0,00 " + item.units!
        }else{
            income.text = item.value1! + " " + item.units!
        }
        
        if item.valueInput1 == "" || item.valueInput1 == " " || item.valueInput1 == "-" || item.valueInput1 == nil{
            outcome.text = "0,00 " + item.units!
        }else{
            outcome.text = item.valueInput1! + " " + item.units!
        }
        if item.typeTarif == "1" || item.typeTarif == " " || item.typeTarif == ""{
            kolTarif.text = "1 - тарифный"
            tarifHeight.constant = 0
            tarifBot.constant = 5
            oneTarif.isHidden = true
            oneTarifDrop.isHidden = true
            oneTarifLbl.isHidden = true
            twoTarif.isHidden = true
            twoTarifDrop.isHidden = true
            twoTarifLbl.isHidden = true
            var am = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            var am2 = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            if am == "0 ₽"{
                am = "0.00 ₽"
                am2 = "0.00 ₽"
            }
            am.forEach{_ in
                if am.contains(find: "."){
                    am.removeLast()
                }
            }
            am2.forEach{_ in
                if am2.contains(find: "."){
                    am2.removeFirst()
                }
            }
            self.tarif.text    = am
            self.tarifDrop.text = "," + am2  + "₽/\(item.units!)"
            if item.tarifPrice1 == "0"{
                self.tarif.text    = "0"
                self.tarifDrop.text = ",00 ₽/\(item.units!)"
            }
            tarifLine.isHidden = true
            tarifLbl.isHidden = true
        }else if item.typeTarif == "2"{
            tarifLine.isHidden = false
            kolTarif.text = "2 - тарифный"
            tarifHeight.constant = 70
            tarifWidth.constant = 0
            oneTarifWidth.constant = (self.delegate.view.frame.size.width - 2) / 2
            tarifBot.constant = 74
            var am = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            var am2 = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            if am == "0 ₽"{
                am = "0.00 ₽"
                am2 = "0.00 ₽"
            }
            am.forEach{_ in
                if am.contains(find: "."){
                    am.removeLast()
                }
            }
            am2.forEach{_ in
                if am2.contains(find: "."){
                    am2.removeFirst()
                }
            }
            self.oneTarif.text    = am
            self.oneTarifDrop.text = "," + am2  + "₽/\(item.units!)"
            if item.tarifPrice1 == "0"{
                self.oneTarif.text    = "0"
                self.oneTarifDrop.text = ",00 ₽/\(item.units!)"
            }
            oneTarifLbl.text = "Тариф - Т1(" + item.tarifName1! + ")"
            var am1 = item.tarifPrice2!.replacingOccurrences(of: ",", with: ".")
            var am12 = item.tarifPrice2!.replacingOccurrences(of: ",", with: ".")
            if am1 == "0 ₽"{
                am1 = "0.00 ₽"
                am12 = "0.00 ₽"
            }
            am1.forEach{_ in
                if am1.contains(find: "."){
                    am1.removeLast()
                }
            }
            am12.forEach{_ in
                if am12.contains(find: "."){
                    am12.removeFirst()
                }
            }
            self.twoTarif.text    = am1
            self.twoTarifDrop.text = "," + am12  + "₽/\(item.units!)"
            if item.tarifPrice2 == "0"{
                self.twoTarif.text    = "0"
                self.twoTarifDrop.text = ",00 ₽/\(item.units!)"
            }
            twoTarifLbl.text = "Тариф - Т2(" + item.tarifName2! + ")"
            oneTarif.isHidden = false
            oneTarifLbl.isHidden = false
            twoTarif.isHidden = false
            twoTarifLbl.isHidden = false
            tarif.isHidden = true
            tarifDrop.isHidden = true
            tarifLbl.isHidden = true
        }else if item.typeTarif == "3"{
            tarifLine.isHidden = false
            kolTarif.text = "3 - тарифный"
            tarifHeight.constant = 70
            tarifWidth.constant = (self.delegate.view.frame.size.width - 2) / 3
            oneTarifWidth.constant = (self.delegate.view.frame.size.width - 2) / 3
            tarifBot.constant = 74
            var am = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            var am2 = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            if am == "0 ₽"{
                am = "0.00 ₽"
                am2 = "0.00 ₽"
            }
            am.forEach{_ in
                if am.contains(find: "."){
                    am.removeLast()
                }
            }
            am2.forEach{_ in
                if am2.contains(find: "."){
                    am2.removeFirst()
                }
            }
            self.oneTarif.text    = am
            self.oneTarifDrop.text = "," + am2  + "₽/\(item.units!)"
            if item.tarifPrice1 == "0"{
                self.oneTarif.text    = "0"
                self.oneTarifDrop.text = ",00 ₽/\(item.units!)"
            }
            oneTarifLbl.text = "Тариф - Т1(" + item.tarifName1! + ")"
            var am1 = item.tarifPrice2!.replacingOccurrences(of: ",", with: ".")
            var am12 = item.tarifPrice2!.replacingOccurrences(of: ",", with: ".")
            if am1 == "0 ₽"{
                am1 = "0.00 ₽"
                am12 = "0.00 ₽"
            }
            am1.forEach{_ in
                if am1.contains(find: "."){
                    am1.removeLast()
                }
            }
            am12.forEach{_ in
                if am12.contains(find: "."){
                    am12.removeFirst()
                }
            }
            self.twoTarif.text    = am1
            self.twoTarifDrop.text = "," + am12  + "₽/\(item.units!)"
            if item.tarifPrice2 == "0"{
                self.twoTarif.text    = "0"
                self.twoTarifDrop.text = ",00 ₽/\(item.units!)"
            }
            twoTarifLbl.text = "Тариф - Т2(" + item.tarifName2! + ")"
            var am3 = item.tarifPrice3!.replacingOccurrences(of: ",", with: ".")
            var am32 = item.tarifPrice3!.replacingOccurrences(of: ",", with: ".")
            if am3 == "0 ₽"{
                am3 = "0.00 ₽"
                am32 = "0.00 ₽"
            }
            am3.forEach{_ in
                if am3.contains(find: "."){
                    am3.removeLast()
                }
            }
            am32.forEach{_ in
                if am32.contains(find: "."){
                    am32.removeFirst()
                }
            }
            self.tarif.text    = am3
            self.tarifDrop.text = "," + am32  + "₽/\(item.units!)"
            if item.tarifPrice3 == "0"{
                self.tarif.text    = "0"
                self.tarifDrop.text = ",00 ₽/\(item.units!)"
            }
            tarifLbl.text = "Тариф - Т3(" + item.tarifName3! + ")"
            oneTarif.isHidden = false
            oneTarifLbl.isHidden = false
            twoTarif.isHidden = false
            twoTarifLbl.isHidden = false
            tarif.isHidden = false
            tarifLbl.isHidden = false
        }
    }
    
    private func getNameAndMonth(_ number_month: String) -> String {
        
        if number_month == "01" || number_month == "1"{
            return "Января"
        } else if number_month == "02"  || number_month == "2"{
            return "Февраля"
        } else if number_month == "03"  || number_month == "3"{
            return "Марта"
        } else if number_month == "04"  || number_month == "4"{
            return "Апреля"
        } else if number_month == "05"  || number_month == "5"{
            return "Мая"
        } else if number_month == "06"  || number_month == "6"{
            return "Июня"
        } else if number_month == "07"  || number_month == "7"{
            return "Июля"
        } else if number_month == "08"  || number_month == "8"{
            return "Августа"
        } else if number_month == "09"  || number_month == "9"{
            return "Сентября"
        } else if number_month == "10"  || number_month == "10"{
            return "Октября"
        } else if number_month == "11"  || number_month == "11"{
            return "Ноября"
        } else {
            return "Декабря"
        }
    }
    
    class func fromNib() -> CounterCellNew? {
        var cell: CounterCellNew?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? CounterCellNew {
                cell = view
            }
        }
        cell?.counter_name.preferredMaxLayoutWidth = cell?.counter_name.bounds.size.width ?? 0.0
        //cell?.desc.preferredMaxLayoutWidth = cell?.desc.bounds.size.width ?? 0.0
        return cell
    }
}
