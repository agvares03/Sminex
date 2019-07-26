//
//  FinanceVCComm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 18/07/2019.
//

import UIKit
import Gloss
import ExpyTableView

class FinanceVCComm: UIViewController, ExpyTableViewDataSource, ExpyTableViewDelegate {
    
    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBOutlet private weak var table:   ExpyTableView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func barcodePreesed(_ sender: UIButton) {
        if debt?.codPay != "" && debt?.codPay != nil {
            performSegue(withIdentifier: Segues.fromFinanceVC.toBarcode, sender: self)
            
        } else {
            showToast(message: "Нет данных по QR-коду")
        }
    }
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Segues.fromFinanceVC.toPay, sender: self)
    }
    
    private var backColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1.0)
    private var url:        URLRequest?
    private var index = 0
    private var debt:          AccountDebtJson?
    private var receipts:      [AccountBillsJson]        = []
    private var calcs:         [AccountCalculationsJson] = []
    private var filteredCalcs: [AccountCalculationsJson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        automaticallyAdjustsScrollViewInsets = false
        startAnimation()
        table.dataSource    = self
        table.delegate      = self
        
        DispatchQueue.global(qos: .userInitiated).async {
            TemporaryHolder.instance.calcsGroup.wait()
            TemporaryHolder.instance.receiptsGroup.wait()
            self.calcs = TemporaryHolder.instance.calcs
            self.receipts = TemporaryHolder.instance.receipts
            self.filteredCalcs = TemporaryHolder.instance.filteredCalcs
            self.getAccountDebt()
            DispatchQueue.main.async {
                self.table.reloadData()
                //                self.stopAnimation()
            }
        }
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
//        if UserDefaults.standard.string(forKey: "typeBuilding") != ""{
//            return 4
//        }else{
            return 3
//        }
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceSectionCommCell") as! FinanceSectionCommCell
        if section == 1 {
            cell.display("Квитанции")
            
        } else {
            cell.display("Взаиморасчеты")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceHeaderCommCell") as! FinanceHeaderCommCell
            cell.selectionStyle = .none
            if debt != nil {
                var datePay = self.debt?.datePay
                if (datePay?.count ?? 0) > 9 {
                    datePay?.removeLast(9)
                }
                var sum = String(format:"%.2f", debt!.sumPay!)
                if Double(debt!.sumPay!) > 999.00 || Double(debt!.sumPay!) < -999.00{
                    let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
                }
                if sum.first == "-" {
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
                }
                cell.display(amount: sum + " ₽", date: "До " + (datePay ?? ""))
            } else {
                // Значит запрос не прошел
                let dateFormatter = DateFormatter()
                let date = Date()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                
                let comp: DateComponents = Calendar.current.dateComponents([.year, .month], from: date)
                let startOfMonth = Calendar.current.date(from: comp)!
                
                var comps2 = DateComponents()
                comps2.month = 1
                comps2.day = -1
                let endOfMonth = Calendar.current.date(byAdding: comps2, to: startOfMonth)
                let dateText = dateFormatter.string(from: endOfMonth!)
                
                let datePay = dateText
                //                if (datePay.count) > 9 {
                //                    datePay.removeLast(8)
                //                }
                cell.display(amount: (debt?.sumPay ?? 0.0).formattedWithSeparator + " ₽", date: "До " + (datePay))
            }
            cell.contentView.backgroundColor = backColor
            return cell
            
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCommCell", for: indexPath) as! FinanceCommCell
            if indexPath.row == receipts.count + 1 || indexPath.row == 4 {
                cell.display(title: "Архив квитанции", desc: "")
                cell.contentView.backgroundColor = .white
                
            } else {
                //                cell.display(title: getNameAndMonth(receipts[safe: indexPath.row - 1]?.numMonth ?? 0) + " \(receipts[safe: indexPath.row - 1]?.numYear ?? 0)",
                //                    desc: ((receipts[safe: indexPath.row - 1]?.sum ?? 0.0) - (receipts[safe: indexPath.row - 1]?.payment_sum ?? 0.0)).formattedWithSeparator)
                //                if UserDefaults.standard.string(forKey: "typeBuilding") != ""{
                var year = "\(receipts[safe: indexPath.row - 1]?.numYear ?? 0)"
                if receipts[safe: indexPath.row - 1]!.numYear! > 2000{
                    year.removeFirst()
                    year.removeFirst()
                }
                var sum = String(format:"%.2f", receipts[safe: indexPath.row - 1]!.sum!)
                if Double(receipts[safe: indexPath.row - 1]!.sum!) > 999.00 || Double(receipts[safe: indexPath.row - 1]!.sum!) < -999.00{
                    let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
                }
                if sum.first == "-" {
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
                }
                cell.display(title: getNameAndMonth(receipts[safe: indexPath.row - 1]?.numMonth ?? 0) + " " + year,
                             desc: sum)
                //                }else{
                //                    cell.display(title: getNameAndMonth(receipts[safe: indexPath.row - 1]?.numMonth ?? 0) + " \(receipts[safe: indexPath.row - 1]?.numYear ?? 0)",
                //                        desc: ((receipts[safe: indexPath.row - 1]?.sum ?? 0.0)).formattedWithSeparator)
                //                }
                cell.contentView.backgroundColor = backColor
            }
            return cell
            
            //        }else if indexPath.section == 3 {
            //            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCommCell", for: indexPath) as! FinanceCommCell
            //            if (self.calcs.count == 0) {
            //                cell.display(title: "", desc: "")
            //            } else {
            //                cell.display(title: "История взаиморасчетов", desc: "")
            //                cell.contentView.backgroundColor = .white
            //            }
            //            return cell
            
        } else if indexPath.section == 2{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCommCell", for: indexPath) as! FinanceCommCell
            if (indexPath.row == filteredCalcs.count + 1 || indexPath.row == 4) && (Double((debt?.sumPay)!) >= 0.00){
                if (self.calcs.count == 0) {
                    cell.display(title: "", desc: "")
                } else {
                    cell.display(title: "История взаиморасчетов", desc: "")
                    cell.contentView.backgroundColor = .white
                }
            }else if (indexPath.row == filteredCalcs.count + 1 || indexPath.row == 5) && (Double((debt?.sumPay)!) < 0.00){
                if (self.calcs.count == 0) {
                    cell.display(title: "", desc: "")
                } else {
                    cell.display(title: "История взаиморасчетов", desc: "")
                    cell.contentView.backgroundColor = .white
                }
            }else if indexPath.row == 1 && (Double((debt?.sumPay)!) < 0.00){
                var sum = String(format:"%.2f", debt!.sumPay!)
                if Double(debt!.sumPay!) > 999.00 || Double(debt!.sumPay!) < -999.00{
                    let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
                }
                cell.display(title: "Аванс", desc: sum.replacingOccurrences(of: "-", with: ""))
                cell.contentView.backgroundColor = backColor
            } else {
                var debt = 0.00
                var currDate = (0, 0)
                if (Double((self.debt!.sumPay)!) < 0.00){
                    currDate = (filteredCalcs[indexPath.row - 2].numMonthSet, filteredCalcs[indexPath.row - 2].numYearSet) as! (Int, Int)
                }else{
                    currDate = (filteredCalcs[indexPath.row - 1].numMonthSet, filteredCalcs[indexPath.row - 1].numYearSet) as! (Int, Int)
                }
                calcs.forEach {
                    if ($0.numMonthSet == currDate.0 && $0.numYearSet == currDate.1) {
                        debt += ($0.sumDebt ?? 0.00)
                    }
                }
                //                if UserDefaults.standard.string(forKey: "typeBuilding") != ""{
                var year = ""
                if (Double((self.debt!.sumPay)!) < 0.00){
                    year = "\(filteredCalcs[indexPath.row - 2].numYearSet ?? 0)"
                }else{
                    year = "\(filteredCalcs[indexPath.row - 1].numYearSet ?? 0)"
                }
                if (Double((self.debt!.sumPay)!) < 0.00){
                    if receipts[safe: indexPath.row - 2]!.numYear! > 2000{
                        year.removeFirst()
                        year.removeFirst()
                    }
                }else{
                    if receipts[safe: indexPath.row - 1]!.numYear! > 2000{
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
                    if (Double((self.debt!.sumPay)!) < 0.00){
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
                                     desc: "Оплачено")
                    }else{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: "Оплачено")
                    }
                }else if debt > 0.00{
                    if (Double((self.debt!.sumPay)!) < 0.00){
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
                                     desc: "Задолженность " + sum)
                    }else{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: "Задолженность " + sum)
                    }
                }else{
                    if Double((self.debt!.sumPay)!) < 0.00{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
                                     desc: sum)
                    }else{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: debt != 0.0 ? "- \(debt.formattedWithSeparator)" : "")
                    }
                }
                //                }else{
                //                    cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " \(filteredCalcs[indexPath.row - 1].numYearSet ?? 0)",
                //                        desc: debt != 0.0 ? "Долг \(debt.formattedWithSeparator)" : "")
                //                }
                
                cell.contentView.backgroundColor = backColor
            }
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCommCell", for: indexPath) as! FinanceCommCell
            cell.display(title: "История оплат", desc: "")
            cell.contentView.backgroundColor = .white
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if receipts.count == 0 {
                return 0
                
            } else if receipts.count < 3 {
                return receipts.count + 2
                
            } else {
                return 5
            }
            
        } else if section == 2 {
            if filteredCalcs.count == 0 {
                if debt?.sumPay != nil && Double((debt?.sumPay)!) < 0.00{
                    return 1
                }else{
                    return 0
                }
            } else if filteredCalcs.count < 3 {
                if debt?.sumPay != nil && Double((debt?.sumPay)!) < 0.00{
                    return filteredCalcs.count + 3
                }else{
                    return filteredCalcs.count + 2
                }
                
            } else {
                if debt?.sumPay != nil && Double((debt?.sumPay)!) < 0.00{
                    return 6
                }else{
                    return 5
                }
            }
            
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        
        if state == .willExpand {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceSectionCommCell
            cell.expand(true)
            
        } else if state == .willCollapse {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceSectionCommCell
            cell.expand(false)
        }
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        if section == 0 || section == 3 {
            return false
            
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            if UserDefaults.standard.bool(forKey: "denyTotalOnlinePayments") {
                return 160
            }
            return 220.0
            
        } else {
            if view.frame.size.width == 320 && indexPath.section == 2 && indexPath.row != 0{
                return 60.0
            }
            return 50.0
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            guard indexPath.row != 0 else { return }
            
            if indexPath.row == receipts.count + 1 || indexPath.row == 4 {
                performSegue(withIdentifier: Segues.fromFinanceVC.toReceiptArchive, sender: self)
                return
            }
            index = indexPath.row - 1
            performSegue(withIdentifier: Segues.fromFinanceVC.toReceipts, sender: self)
            
        } else if indexPath.section == 2 {
            guard indexPath.row != 0 else { return }
            if Double((self.debt!.sumPay)!) < 0.00{
                if indexPath.row == 5 {
                    performSegue(withIdentifier: Segues.fromFinanceVC.toCalcsArchive, sender: self)
                    return
                }
                index = indexPath.row - 2
                if indexPath.row != 1{
                    performSegue(withIdentifier: Segues.fromFinanceVC.toCalcs, sender: self)
                }
            }else{
                if indexPath.row == 4 {
                    performSegue(withIdentifier: Segues.fromFinanceVC.toCalcsArchive, sender: self)
                    return
                }
                index = indexPath.row - 1
                performSegue(withIdentifier: Segues.fromFinanceVC.toCalcs, sender: self)
            }
            
        } else if indexPath.section == 3 {
            performSegue(withIdentifier: Segues.fromFinanceVC.toHistory, sender: self)
        }
    }
    
    private func getAccountDebt() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_DEBT + "login=" + login + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.table.reloadData()
                    self.stopAnimation()
                }
            }
            #if DEBUG
            print(String(data: data!, encoding: .utf8)!)
            #endif
            guard data != nil else { return }
            if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
                self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
            }
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
                    //                    self.present(alert, animated: true, completion: nil)
                }
                
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.debt = AccountDebtData(json: json!)?.data
                //                self.debt?.sumPay = -12345.00
            }
            
            }.resume()
    }
    
    private func startAnimation() {
        loader.startAnimating()
        loader.isHidden = false
        table.isHidden  = true
    }
    
    private func stopAnimation() {
        loader.stopAnimating()
        loader.isHidden = true
        table.isHidden  = false
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceVC.toBarcode {
            let vc = segue.destination as! FinanceBarCodeVC
            vc.data_ = debt
            
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
        } else if segue.identifier == Segues.fromFinanceVC.toReceipts {
            let vc = segue.destination as! FinanceDebtVCComm
            vc.data_ = receipts[safe: index]
            
        } else if segue.identifier == Segues.fromFinanceVC.toReceiptArchive {
            let vc = segue.destination as! FinanceDebtArchiveVCComm
            vc.data_ = receipts
            
        } else if segue.identifier == Segues.fromFinanceVC.toCalcs {
            let vc = segue.destination as! FinanceCalcVCComm
            let date = (filteredCalcs[index].numMonthSet, filteredCalcs[index].numYearSet)
            vc.data_ = calcs.filter {
                return date.0 == $0.numMonthSet && date.1 == $0.numYearSet
            }
            
        } else if segue.identifier == Segues.fromFinanceVC.toCalcsArchive {
            let vc = segue.destination as! FinanceCalcsArchiveVCComm
            vc.debt = debt
            vc.data_ = calcs
            
        } else if segue.identifier == Segues.fromFinanceVC.toPay {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.accountData_ = debt
        }
    }
}

final class FinanceSectionCommCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var img:     UIImageView!
    
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


final class FinanceHeaderCommCell: UITableViewCell {
    
    @IBOutlet weak var heigth_cell: NSLayoutConstraint!
    
    @IBOutlet private weak var amount: UILabel!
    @IBOutlet private weak var amountDrob: UILabel!
    @IBOutlet private weak var date: UILabel!
    
    @IBOutlet weak var pay_button: UIButton!
    @IBOutlet weak var pay_QR: UIButton!
    @IBOutlet weak var pay_QR_image: UIImageView!
    
    @IBOutlet weak var isPayed: NSLayoutConstraint!
    @IBOutlet weak var heigthPayed: NSLayoutConstraint!
    
    @IBAction private func barcodePressed(_ sender: UIButton) {
    }
    
    func display(amount: String, date: String) {
        print("SUM = ", amount)
        var am = amount
        var am2 = amount
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
        self.amount.text    = am
        self.amountDrob.text = ", " + am2
        self.date.text      = date
        
        let defaults = UserDefaults.standard
        
        if (defaults.bool(forKey: "denyTotalOnlinePayments")) {
            pay_button.isHidden   = true
            
            isPayed.constant      = 15
            heigthPayed.constant  = 150
            
        } else if (defaults.bool(forKey: "denyOnlinePayments")) {
            pay_button.isHidden   = defaults.bool(forKey: "denyOnlinePayments")
            isPayed.constant      = 15
            heigthPayed.constant  = 150
        }
        //        print(isPayed.constant, heigthPayed.constant)
        // Выводить или нет кнопку QR-код
        if defaults.bool(forKey: "denyQRCode"){
            pay_QR.isHidden           = true
            pay_QR_image.isHidden     = true
        }
        
    }
}


final class FinanceCommCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet weak var img: UIImageView!
    
    func display(title: String, desc: String) {
        self.title.text = title
        self.desc.text  = desc
        if title == "Аванс" || desc.contains(find: "-"){
            self.desc.textColor = .green
            self.desc.alpha = 1
        }else{
            self.desc.textColor = .darkText
            self.desc.alpha = 0.5
        }
        if (title == "" || title == "Аванс") {
            img.image = nil
        }else{
            img.image = UIImage(named: "arrow_right")
        }
        
    }
}
