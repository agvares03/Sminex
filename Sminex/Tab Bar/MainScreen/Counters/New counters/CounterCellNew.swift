//
//  CounterCellNew.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit

final class CounterCellNew: UICollectionViewCell {
    @IBOutlet private weak var sendLbl:         UILabel!
    @IBOutlet private weak var sendLblHeight:   NSLayoutConstraint!
    @IBOutlet private weak var counter_name:    UILabel!
    @IBOutlet private weak var income:          UILabel!
    @IBOutlet private weak var outcome:         UILabel!
    @IBOutlet private weak var dateSend:        UILabel!
    @IBOutlet private weak var kolTarif:        UILabel!
    @IBOutlet private weak var tarifBot:        NSLayoutConstraint!
    @IBOutlet private weak var tarifHeight:     NSLayoutConstraint!
    @IBOutlet private weak var oneTarif:        UILabel!
    @IBOutlet private weak var oneTarifLbl:     UILabel!
    @IBOutlet private weak var oneTarifWidth:   NSLayoutConstraint!
    @IBOutlet private weak var twoTarif:        UILabel!
    @IBOutlet private weak var twoTarifLbl:     UILabel!
    @IBOutlet private weak var tarif:           UILabel!
    @IBOutlet private weak var tarifLbl:        UILabel!
    @IBOutlet private weak var tarifWidth:      NSLayoutConstraint!
    @IBOutlet private weak var tarifLine:       UILabel!
    @IBOutlet private weak var dateCheck:       UILabel!
    @IBOutlet private weak var dateCheckLbl:    UILabel!
    @IBOutlet private weak var dateCheckHeight: NSLayoutConstraint!
    @IBOutlet private weak var sendBtn:         UIButton!
    @IBOutlet private weak var sendBtnHeight:   NSLayoutConstraint!
    
    @IBAction private func go_action(_ sender: UIButton) {
        self.delegate2.pressed(index: index)
    }
    
    @IBAction private func history_action(_ sender: UIButton) {
        self.delegate2.pressedHistory(ident: index, name: (counter_name.text?.replacingOccurrences(of: "Счетчик №", with: ""))!)
    }
    
    var delegate : UIViewController!
    var delegate2: NewCounterDelegate!
    var index = 0
    func display(_ item: MeterValue, delegate: UIViewController, index: Int, delegate2: NewCounterDelegate, date: String, canCount: Bool) {
        var canCount2 = canCount
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
        if dateTo == 0 && dateFrom == 0{
            sendLbl.text  = ""
            sendLblHeight.constant = 0
            canCount2 = true
        }
        if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
            sendLblHeight.constant = 45
            canCount2 = false
            sendLbl.text  = "Снятие и передача показаний осуществляется управляющей компанией"
        }
        self.delegate = delegate
        self.delegate2 = delegate2
        self.index = index
        sendLblHeight.constant = 45
        if canCount2{
            sendBtnHeight.constant = 42
            sendBtn.isHidden = false
        }else{
            sendBtnHeight.constant = 1
            sendBtn.isHidden = true
        }
        counter_name.text = "Счетчик №" + item.meterUniqueNum!
        var dat: String = item.lastModf!
        if date != nil && date != "" && date != " "{
            date.forEach{_ in
                if dat.contains(find: " "){
                    dat.removeLast()
                }
            }
            let dat1 = dat.components(separatedBy: ".")
            dat = dat1[0] + " " + getNameAndMonth(dat1[1]) + " " + dat1[2]
            dateSend.text = dat
        }else{
            dateSend.text = "-"
        }
        
        dateCheck.text = item.checkDate
        if item.checkDate == ""{
            dateCheck.isHidden = true
            dateCheckLbl.isHidden = true
            dateCheckHeight.constant = 10
        }else{
            dateCheck.isHidden = false
            dateCheckLbl.isHidden = false
            if canCount2{
                dateCheckHeight.constant = 65
            }else{
                dateCheckHeight.constant = 40
            }
        }
        
        if item.value1 == "" || item.value1 == " " || item.value1 == "-" || item.value1 == nil{
            outcome.text = "0,00 " + item.units!
        }else{
            outcome.text = item.value1! + " " + item.units!
        }
        
        if item.previousValue1 == "" || item.previousValue1 == " " || item.previousValue1 == "-" || item.previousValue1 == nil{
            income.text = "0,00 " + item.units!
        }else{
            income.text = item.previousValue1! + " " + item.units!
        }
        tarifWidth.constant = (self.delegate.view.frame.size.width - 32 - 2) / 3
        if item.typeTarif == "1" || item.typeTarif == " " || item.typeTarif == ""{
            kolTarif.text = "1 - тарифный"
            tarifHeight.constant = 0
            tarifBot.constant = 20
            oneTarif.isHidden = true
            oneTarifLbl.isHidden = true
            twoTarif.isHidden = true
            twoTarifLbl.isHidden = true
            let am = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            self.tarif.text    = am + " ₽/\(item.units!)"
            if item.tarifPrice1 == "0"{
                self.tarif.text    = "0,00 ₽/\(item.units!)"
            }
            tarifLine.isHidden = true
            tarifLbl.isHidden = true
        }else if item.typeTarif == "2"{
            tarifLine.isHidden = false
            kolTarif.text = "2 - тарифный"
            tarifHeight.constant = 70
            tarifWidth.constant = 0
            oneTarifWidth.constant = (self.delegate.view.frame.size.width - 32 - 2) / 2
            tarifBot.constant = 56
            let am = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            self.oneTarif.text    = am + " ₽/\(item.units!)"
            if item.tarifPrice1 == "0"{
                self.oneTarif.text    = "0,00 ₽/\(item.units!)"
            }
            oneTarifLbl.text = "Тариф - Т1(" + item.tarifName1! + ")"
            let am1 = item.tarifPrice2!.replacingOccurrences(of: ",", with: ".")
            self.twoTarif.text    = am1 + " ₽/\(item.units!)"
            if item.tarifPrice2 == "0"{
                self.twoTarif.text    = "0,00 ₽/\(item.units!)"
            }
            twoTarifLbl.text = "Тариф - Т2(" + item.tarifName2! + ")"
            oneTarif.isHidden = false
            oneTarifLbl.isHidden = false
            twoTarif.isHidden = false
            twoTarifLbl.isHidden = false
            tarif.isHidden = true
            tarifLbl.isHidden = true
        }else if item.typeTarif == "3"{
            tarifLine.isHidden = false
            kolTarif.text = "3 - тарифный"
            tarifHeight.constant = 70
            tarifWidth.constant = (self.delegate.view.frame.size.width - 32 - 2) / 3
            oneTarifWidth.constant = (self.delegate.view.frame.size.width - 32 - 2) / 3
            tarifBot.constant = 56
            let am = item.tarifPrice1!.replacingOccurrences(of: ",", with: ".")
            self.oneTarif.text    = am + " ₽/\(item.units!)"
            if item.tarifPrice1 == "0"{
                self.oneTarif.text    = "0,00 ₽/\(item.units!)"
            }
            oneTarifLbl.text = "Тариф - Т1(" + item.tarifName1! + ")"
            let am1 = item.tarifPrice2!.replacingOccurrences(of: ",", with: ".")
            self.twoTarif.text    = am1 + " ₽/\(item.units!)"
            if item.tarifPrice2 == "0"{
                self.twoTarif.text    = "0,00 ₽/\(item.units!)"
            }
            twoTarifLbl.text = "Тариф - Т2(" + item.tarifName2! + ")"
            let am3 = item.tarifPrice3!.replacingOccurrences(of: ",", with: ".")
            self.tarif.text    = am3 + " ₽/\(item.units!)"
            if item.tarifPrice3 == "0"{
                self.tarif.text    = "0,00 ₽/\(item.units!)"
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
