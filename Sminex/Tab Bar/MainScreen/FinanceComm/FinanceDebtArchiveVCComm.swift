//
//  FinancePayVCComm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 18/07/2019.
//

import UIKit
import ExpyTableView

class FinanceDebtArchiveVCComm: UIViewController, ExpyTableViewDataSource, ExpyTableViewDelegate {
    
    @IBOutlet private weak var table:   ExpyTableView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    struct Objects {
        var sectionName : String!
        var filteredData : [AccountBillsJson]!
    }
    
    public var data_: [AccountBillsJson] = []
    public var filteredData: [AccountBillsJson] = []
    var kolYear: [String] = []
    var dataFilt = [Objects]()
    private var index = 0
    private var section = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var currMonth = 0
        filteredData = data_.filter {
            if ($0.numMonth ?? 0) != currMonth {
                currMonth = ($0.numMonth ?? 0)
                return true
            }
            return false
        }
        var year = 0
        filteredData.forEach{
            if $0.numYear != year{
                year = $0.numYear!
                kolYear.append(String($0.numYear!))
            }
        }
        for i in 0...kolYear.count - 1{
            var s = filteredData
            s.removeAll()
            filteredData.forEach{
                if String($0.numYear!) == kolYear[i]{
                    s.append($0)
                }
            }
            dataFilt.append(Objects(sectionName: kolYear[i], filteredData: s))
        }
        automaticallyAdjustsScrollViewInsets = false
        table.dataSource = self
        table.delegate   = self
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
            return dataFilt.count
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceDebtArchiveYearCommCell") as! FinanceDebtArchiveYearCommCell
        var last = false
        if section == (dataFilt.count - 1){
            last = true
        }
        cell.display(dataFilt[section].sectionName, section: section, last: last)
        
        //do other header related calls or settups
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        if section == 0 && (Double((debt?.sumPay)!) < 0.00 && UserDefaults.standard.string(forKey: "typeBuilding") != ""){
//            return dataFilt[section].filteredData.count + 2
//        }else{
            return dataFilt[section].filteredData.count + 1
//        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            return 62.0
        }else{
            return 50.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row > 0{
            index = indexPath.row - 1
            section = indexPath.section
            performSegue(withIdentifier: Segues.fromFinanceDebtArchiveVC.toReceipt, sender: self)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceDebtArchiveCommCell") as! FinanceDebtArchiveCommCell
        //        cell.display(title: self.getNameAndMonth(data_[indexPath.row].numMonth ?? 0) + " \(data_[indexPath.row].numYear ?? 0)", desc: (((data_[safe: indexPath.row]?.sum ?? 0.0) - (data_[safe: indexPath.row]?.payment_sum ?? 0.0)).formattedWithSeparator))
        cell.display(title: self.getNameAndMonth(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numMonth ?? 0) + " \(dataFilt[indexPath.section].filteredData[indexPath.row - 1].numYear ?? 0)", desc: (((dataFilt[indexPath.section].filteredData[indexPath.row - 1].sum ?? 0.0)).formattedWithSeparator))
        return cell
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        
        if state == .willExpand {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceDebtArchiveYearCommCell
            var last = false
            if section == (dataFilt.count - 1){
                last = true
            }
            cell.expand(true, last: last)
            
        } else if state == .willCollapse {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceDebtArchiveYearCommCell
            var last = false
            if section == (dataFilt.count - 1){
                last = true
            }
            cell.expand(false, last: last)
        }
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceDebtArchiveVC.toReceipt {
            let vc = segue.destination as! FinanceDebtVCComm
            vc.data_ = dataFilt[section].filteredData[index]
        }
    }
    
    private func getNameAndMonth(_ number_month: Int) -> String {
        
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

final class FinanceDebtArchiveYearCommCell: UITableViewCell, ExpyTableViewHeaderCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var botView: UIView!
    
    func display(_ title: String, section: Int, last: Bool) {
        if section == 0{
            topView.isHidden = false
            botView.isHidden = true
        }else if last{
            topView.isHidden = true
            botView.isHidden = false
        }else{
            topView.isHidden = false
            botView.isHidden = false
        }
        self.title.text     = title
        self.img.image = UIImage(named: "expand")
    }
    
    func changeState(_ state: ExpyState, cellReuseStatus cellReuse: Bool) {
        switch state {
        case .willExpand:
            self.img.image = UIImage(named: "expanded")
        case .willCollapse:
            self.img.image = UIImage(named: "expand")
        case .didExpand:
            self.img.image = UIImage(named: "expanded")
        case .didCollapse:
            self.img.image = UIImage(named: "expand")
        }
    }
    
    func expand(_ isExpanded: Bool, last: Bool) {
        if !isExpanded {
            self.img.image = UIImage(named: "expand")
            if last{
                topView.isHidden = true
                botView.isHidden = false
            }
        } else {
            if last{
                topView.isHidden = false
                botView.isHidden = false
            }
            self.img.image = UIImage(named: "expanded")
        }
    }
}

final class FinanceDebtArchiveCommCell: UITableViewCell {
    
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
        self.desc.text  = sum.replacingOccurrences(of: ".", with: ",")
    }
}
