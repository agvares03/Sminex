//
//  FinanceCalcsArchiveVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/15/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import ExpyTableView

final class FinanceCalcsArchiveVC: UIViewController, ExpyTableViewDataSource, ExpyTableViewDelegate {
    
    @IBOutlet private weak var table:   ExpyTableView!
    @IBOutlet private weak var tableHeight: NSLayoutConstraint!
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    struct Objects {
        var sectionName : String!
        var filteredData : [AccountCalculationsJson]!
    }
    
    public var data_:           [AccountCalculationsJson] = []
    public var dataDebt: [AccountBillsJson] = []
    private var filteredData: [AccountCalculationsJson] = []
    private var index = 0
    private var section = 0
    public var debt:          AccountDebtJson?
    var kolYear: [String] = []
    var dataFilt = [Objects]()
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
        var year = 0
        filteredData.forEach{
            if $0.numYearSet != year{
                year = $0.numYearSet!
                kolYear.append(String($0.numYearSet!))
            }
        }
        for i in 0...kolYear.count - 1{
            var s = filteredData
            s.removeAll()
            filteredData.forEach{
                if String($0.numYearSet!) == kolYear[i]{
                    s.append($0)
                }
            }
            dataFilt.append(Objects(sectionName: kolYear[i], filteredData: s))
        }
//        print(dataFilt.count)
        automaticallyAdjustsScrollViewInsets = false
        table.dataSource    = self
        table.delegate      = self
        self.table.estimatedRowHeight = 50
        self.table.rowHeight = UITableViewAutomaticDimension
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataFilt.count
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCalcsArchiveYearCell") as! FinanceCalcsArchiveYearCell
        cell.display(dataFilt[section].sectionName)
        
        //do other header related calls or settups
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 && (Double((debt?.sumPay)!) < 0.00){
            return dataFilt[section].filteredData.count + 2
        }else{
            return dataFilt[section].filteredData.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && (Double((debt?.sumPay)!) < 0.00){
            if indexPath.row > 0{
                index = indexPath.row - 2
                section = indexPath.section
                performSegue(withIdentifier: Segues.fromFinanceCalcsArchive.toCalc, sender: self)
            }
        }else{
            if indexPath.row > 0{
                index = indexPath.row - 1
                section = indexPath.section
                performSegue(withIdentifier: Segues.fromFinanceCalcsArchive.toCalc, sender: self)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCalcsArchiveCell") as! FinanceCalcsArchiveCell
        if indexPath.section == 0 && indexPath.row == 1 && (Double((debt?.sumPay)!) < 0.00){
            var sum = String(format:"%.2f", debt!.sumPay!)
            if Double(debt!.sumPay!) > 999.00 || Double(debt!.sumPay!) < -999.00{
                let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
            }
            cell.display(title: "Аванс", desc: sum.replacingOccurrences(of: "-", with: ""))
        } else {
            var debt = 0.0
            var currDate = (0, 0)
            if indexPath.section == 0 && (Double((self.debt!.sumPay)!) < 0.00){
                currDate = (dataFilt[indexPath.section].filteredData[indexPath.row - 2].numMonthSet, dataFilt[indexPath.section].filteredData[indexPath.row - 2].numYearSet) as! (Int, Int)
            }else{
                currDate = (dataFilt[indexPath.section].filteredData[indexPath.row - 1].numMonthSet, dataFilt[indexPath.section].filteredData[indexPath.row - 1].numYearSet) as! (Int, Int)
            }
            data_.forEach {
                if ($0.numMonthSet == currDate.0 && $0.numYearSet == currDate.1) {
                    debt += ($0.sumDebt ?? 0.0)
                }
            }
//            if UserDefaults.standard.string(forKey: "typeBuilding") != ""{
                var year = ""
                if indexPath.section == 0 && (Double((self.debt!.sumPay)!) < 0.00){
                    year = "\(dataFilt[indexPath.section].filteredData[indexPath.row - 2].numYearSet ?? 0)"
                }else{
                    year = "\(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numYearSet ?? 0)"
                }
                if indexPath.section == 0 && (Double((self.debt!.sumPay)!) < 0.00){
                    if dataFilt[indexPath.section].filteredData[indexPath.row - 2].numYearSet! > 2000{
                        year.removeFirst()
                        year.removeFirst()
                    }
                }else{
                    if dataFilt[indexPath.section].filteredData[indexPath.row - 1].numYearSet! > 2000{
                        year.removeFirst()
                        year.removeFirst()
                    }
                }
                var sum = String(format:"%.2f", debt)
                if Double(debt) > 999.00 || Double(debt) < -999.00{
                    let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
                }
                if sum.first == "-" {
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
                }
                if debt == 0.00{
                    if indexPath.section == 0 && (Double((self.debt!.sumPay)!) < 0.00){
                        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
                                     desc: "Оплачено")
                    }else{
                        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: "Оплачено")
                    }
                }else if debt > 0.00{
                    if indexPath.section == 0 && (Double((self.debt!.sumPay)!) < 0.00){
                        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
                                     desc: "Задолженность " + sum)
                    }else{
                        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: "Задолженность " + sum)
                    }
                }else{
                    if indexPath.section == 0 && (Double((self.debt!.sumPay)!) < 0.00){
                        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
                                     desc: sum)
                    }else{
                        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: sum)
                    }
                }
//            }else{
//                cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numMonthSet ?? 0) + " \(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numYearSet ?? 0)",
//                desc: debt != 0.0 ? "Долг \(debt.formattedWithSeparator)" : "")
//            }
        }
        return cell
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        switch state {
        case .willExpand:
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceCalcsArchiveYearCell
            cell.expand(true)
        case .willCollapse:
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceCalcsArchiveYearCell
            cell.expand(false)
        case .didExpand:
            print("DID EXPAND")

        case .didCollapse:
            print("DID COLLAPSE")
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceCalcsArchive.toCalc {
            let vc = segue.destination as! FinanceCalcVC
            let date = (dataFilt[section].filteredData[index].numMonthSet, dataFilt[section].filteredData[index].numYearSet)
            var ind = 0
            for i in 0...filteredData.count - 1{
                if filteredData[i].numMonthSet == dataFilt[section].filteredData[index].numMonthSet && filteredData[i].numYearSet == dataFilt[section].filteredData[index].numYearSet{
                    ind = i
                }
            }
            vc.dataDebt = dataDebt
            vc.index = ind
            vc.date = date
            vc.filteredCalcs = filteredData
            vc.calcs = data_
            vc.data_ = data_.filter {
                return (date.0 == $0.numMonthSet && date.1 == $0.numYearSet)
            }
        }
    }
    
    private func getNameAndMonth(_ number_month: Int) -> String {
        print(number_month)
        if number_month == 1 {
            return "Янв"
        } else if number_month == 2 {
            return "Фев"
        } else if number_month == 3 {
            return "Мар"
        } else if number_month == 4 {
            return "Апр"
        } else if number_month == 5 {
            return "Май"
        } else if number_month == 6 {
            return "Июн"
        } else if number_month == 7 {
            return "Июл"
        } else if number_month == 8 {
            return "Авг"
        } else if number_month == 9 {
            return "Сен"
        } else if number_month == 10 {
            return "Окт"
        } else if number_month == 11 {
            return "Ноя"
        } else {
            return "Дек"
        }
    }
}

final class FinanceCalcsArchiveCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet weak var img: UIImageView!
    
    fileprivate func display(title: String, desc: String) {
        self.title.text = title
        self.desc.text  = desc.replacingOccurrences(of: ".", with: ",")
        if title == "Аванс" || desc.contains(find: "-"){
            self.desc.textColor = UIColor(red: 0/255, green: 128/255, blue: 0/255, alpha: 1.0)
            self.desc.alpha = 1
        }else{
            self.desc.textColor = .darkText
            self.desc.alpha = 0.5
        }
        if (title == "Аванс") {
            img.image = nil
        }else{
            img.image = UIImage(named: "arrow_right")
        }
    }
}
final class FinanceCalcsArchiveYearCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet weak var img: UIImageView!
    
    func display(_ title: String) {
        self.title.text     = title
        self.img.image = UIImage(named: "expand")
    }
    
    func expand(_ isExpanded: Bool) {
        if !isExpanded {
            self.img.image = UIImage(named: "expand")
            
        } else {
            self.img.image = UIImage(named: "expanded")
        }
    }
}
