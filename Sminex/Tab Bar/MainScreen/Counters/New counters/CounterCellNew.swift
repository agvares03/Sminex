//
//  CounterCellNew.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit

final class CounterCellNew: UICollectionViewCell {
    
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
    @IBOutlet private weak var twoTarigWidth:   NSLayoutConstraint!
    @IBOutlet private weak var tarif:           UILabel!
    @IBOutlet private weak var tarifLbl:        UILabel!
    @IBOutlet private weak var tarifWidth:      NSLayoutConstraint!
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
        let dat1 = dat.components(separatedBy: ".")
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
            kolTarif.text = "1 - Тарифный"
            tarifHeight.constant = 0
            tarifBot.constant = 0
            oneTarif.isHidden = true
            oneTarifLbl.isHidden = true
            twoTarif.isHidden = true
            twoTarifLbl.isHidden = true
            tarif.text = item.tarifPrice1
            tarifLbl.isHidden = true
        }else if item.typeTarif == "2"{
            kolTarif.text = "2 - Тарифный"
            tarifHeight.constant = 70
            tarifWidth.constant = 0
            oneTarifWidth.constant = (self.delegate.view.frame.size.width - 2) / 2
            tarifBot.constant = 74
            oneTarif.text = item.tarifPrice1
            oneTarifLbl.text = item.tarifName1
            twoTarif.text = item.tarifPrice2
            twoTarifLbl.text = item.tarifName2
            oneTarif.isHidden = false
            oneTarifLbl.isHidden = false
            twoTarif.isHidden = false
            twoTarifLbl.isHidden = false
            tarif.isHidden = true
            tarifLbl.isHidden = true
        }else if item.typeTarif == "3"{
            kolTarif.text = "3 - Тарифный"
            tarifHeight.constant = 70
            tarifWidth.constant = (self.delegate.view.frame.size.width - 2) / 3
            oneTarifWidth.constant = (self.delegate.view.frame.size.width - 2) / 3
            tarifBot.constant = 74
            oneTarif.text = item.tarifPrice1
            oneTarifLbl.text = item.tarifName1
            twoTarif.text = item.tarifPrice2
            twoTarifLbl.text = item.tarifName2
            tarif.text = item.tarifPrice3
            tarifLbl.text = item.tarifName3
            oneTarif.isHidden = false
            oneTarifLbl.isHidden = false
            twoTarif.isHidden = false
            twoTarifLbl.isHidden = false
            tarif.isHidden = false
            tarifLbl.isHidden = false
        }
    }
    
    private func getNameAndMonth(_ number_month: String) -> String {
        
        if number_month == "1" {
            return "Января"
        } else if number_month == "2" {
            return "Февраля"
        } else if number_month == "3" {
            return "Марта"
        } else if number_month == "4" {
            return "Апреля"
        } else if number_month == "5" {
            return "Мая"
        } else if number_month == "6" {
            return "Июня"
        } else if number_month == "7" {
            return "Июля"
        } else if number_month == "8" {
            return "Августа"
        } else if number_month == "9" {
            return "Сентября"
        } else if number_month == "10" {
            return "Октября"
        } else if number_month == "11" {
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
