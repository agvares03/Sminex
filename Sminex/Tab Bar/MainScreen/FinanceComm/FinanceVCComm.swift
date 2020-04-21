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
    @IBOutlet private weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var table:   ExpyTableView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
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
        if (UserDefaults.standard.bool(forKey: "denyTotalOnlinePayments")) {
            performSegue(withIdentifier: Segues.fromFinanceVC.toBillsArchive, sender: self)
        }else{
            performSegue(withIdentifier: Segues.fromFinanceVC.toPay, sender: self)
        }
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
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
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
        self.stopAnimation()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceSectionCommCell") as! FinanceSectionCommCell
        if section == 3 {
            cell.display("Квитанции", section: section, last: false)
        } else {
            cell.display("Взаиморасчеты", section: section, last: false)
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
                
                cell.display(amount: (debt?.sumPay ?? 0.0).formattedWithSeparator + " ₽", date: "До " + (datePay))
            }
            cell.contentView.backgroundColor = .clear
            return cell
            
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCommCell", for: indexPath) as! FinanceCommCell
            if indexPath.row == receipts.count + 1 || indexPath.row == 4 {
                cell.display(title: "Архив квитанции", desc: "")
                cell.contentView.backgroundColor = .white
                
            } else {
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
                cell.contentView.backgroundColor = backColor
            }
            return cell
        } else if indexPath.section == 4{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCommCell", for: indexPath) as! FinanceCommCell
            if (indexPath.row == filteredCalcs.count + 1 || indexPath.row == 4){
//                if (self.calcs.count == 0) {
//                    cell.display(title: "", desc: "")
//                } else {
                    cell.display(title: "История взаиморасчетов", desc: "")
                cell.botView.isHidden = true
                    cell.contentView.backgroundColor = .clear
//                }
            }else if (indexPath.row == filteredCalcs.count + 1 || indexPath.row == 5) { //} && (Double((debt?.sumPay)!) >= 0.00){
                if (self.calcs.count == 0) {
                    cell.display(title: "", desc: "")
                } else {
                    cell.display(title: "История оплат", desc: "")
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
//                if (Double((self.debt!.sumPay)!) < 0.00){
//                    currDate = (filteredCalcs[indexPath.row - 2].numMonthSet, filteredCalcs[indexPath.row - 2].numYearSet) as! (Int, Int)
//                }else{
                    currDate = (filteredCalcs[indexPath.row - 1].numMonthSet, filteredCalcs[indexPath.row - 1].numYearSet) as! (Int, Int)
//                }
                calcs.forEach {
                    if ($0.numMonthSet == currDate.0 && $0.numYearSet == currDate.1) {
                        debt += ($0.sumDebt ?? 0.00)
                    }
                }
                //                if UserDefaults.standard.string(forKey: "typeBuilding") != ""{
                var year = ""
//                if (Double((self.debt!.sumPay)!) < 0.00){
//                    year = "\(filteredCalcs[indexPath.row - 2].numYearSet ?? 0)"
//                }else{
                    year = "\(filteredCalcs[indexPath.row - 1].numYearSet ?? 0)"
//                }
//                if (Double((self.debt!.sumPay)!) < 0.00){
//                    if receipts[safe: indexPath.row - 2]!.numYear! > 2000{
//                        year.removeFirst()
//                        year.removeFirst()
//                    }
//                }else{
                    if receipts.count > 0 {
                        if receipts[safe: indexPath.row - 1]!.numYear! > 2000{
                            year.removeFirst()
                            year.removeFirst()
                        }
                    }
//                }
                var sum = String(format:"%.2f", debt)
                if Double(debt) > 999.00 || Double(debt) < -999.00{
                    let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
                }
                if sum.first == "-" {
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
                }
                if debt == 0.00{
//                    if (Double((self.debt!.sumPay)!) < 0.00){
//                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
//                                     desc: "Оплачено")
//                    }else{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: "Оплачено")
//                    }
                }else if debt > 0.00{
//                    if (Double((self.debt!.sumPay)!) < 0.00){
//                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
//                                     desc: "Задолженность " + sum)
//                    }else{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: "Задолженность " + sum)
//                    }
                }else{
//                    if Double((self.debt!.sumPay)!) < 0.00{
//                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 2].numMonthSet ?? 0) + " " + year,
//                                     desc: sum)
//                    }else{
                        cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " " + year,
                                     desc: debt != 0.0 ? "- \(debt.formattedWithSeparator)" : "")
//                    }
                }
                cell.contentView.backgroundColor = backColor
            }
            return cell
        }else if indexPath.section == 1{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceSectionCommCell", for: indexPath) as! FinanceSectionCommCell
            cell.display("Неоплаченные счета", section: indexPath.section, last: true)
            //            cell.display(title: "История оплат", desc: "")
            cell.contentView.backgroundColor = .clear
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceSectionCommCell", for: indexPath) as! FinanceSectionCommCell
            cell.display("История оплат", section: indexPath.section, last: true)
            //            cell.display(title: "История оплат", desc: "")
            cell.contentView.backgroundColor = .clear
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DispatchQueue.main.async {
            var height1: CGFloat = 0
            for cell in self.table.visibleCells {
                height1 += cell.bounds.height
            }
            self.tableHeight.constant = height1
        }
        if section == 3 {
            if receipts.count == 0 {
                return 2
            } else if receipts.count < 3 {
                return receipts.count + 2
            } else {
                return 5
            }
        } else if section == 4 {
            if filteredCalcs.count == 0 {
                return 2
            } else if filteredCalcs.count < 3 {
                return filteredCalcs.count + 2
            } else {
                return 5
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
        if section == 3 || section == 4 {
            return true
            
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
//            if UserDefaults.standard.bool(forKey: "denyTotalOnlinePayments") {
//                return 139 + 15.0
//            }else{
//                if UserDefaults.standard.bool(forKey: "denyQRCode"){
//                    return 224.0 + 15.0
//                }else{
                    return 229.0
//                }
//            }
        }else if indexPath.section == 2 {
            if view.frame.size.width == 320 && indexPath.section == 2 && indexPath.row != 0{
                return 70.0
            }
            return 60.0
        } else {
            if view.frame.size.width == 320 && indexPath.section == 2 && indexPath.row != 0{
                return 60.0
            }
            return 50.0
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 3 {
            guard indexPath.row != 0 && receipts.count != 0 else { return }
            if indexPath.row == receipts.count + 1 || indexPath.row == 4 || (receipts.count == 0) {
                performSegue(withIdentifier: Segues.fromFinanceVC.toReceiptArchive, sender: self)
                return
            }
            index = indexPath.row - 1
            performSegue(withIdentifier: Segues.fromFinanceVC.toReceipts, sender: self)
            
        } else if indexPath.section == 4 {
            guard indexPath.row != 0 && filteredCalcs.count != 0 else { return }
            self.startAnimation()
//            if Double((self.debt!.sumPay)!) < 0.00{
//                if indexPath.row == 5 || filteredCalcs.count == 0 || indexPath.row == filteredCalcs.count + 2{
//                    performSegue(withIdentifier: Segues.fromFinanceVC.toCalcsArchive, sender: self)
//                    return
//                }
//                index = indexPath.row - 2
//                if indexPath.row != 1{
//                    performSegue(withIdentifier: Segues.fromFinanceVC.toCalcs, sender: self)
//                }
//            }else{
                if indexPath.row == 4 || filteredCalcs.count == 0 || indexPath.row == filteredCalcs.count + 1{
                    performSegue(withIdentifier: Segues.fromFinanceVC.toCalcsArchive, sender: self)
                    return
                } else if (indexPath.row == 5) {
                    performSegue(withIdentifier: Segues.fromFinanceVC.toHistory, sender: self)
                    return
                }
                index = indexPath.row - 1
                performSegue(withIdentifier: Segues.fromFinanceVC.toCalcs, sender: self)
//            }
        } else if indexPath.section == 2 {
            performSegue(withIdentifier: Segues.fromFinanceVC.toHistory, sender: self)
        } else if indexPath.section == 1 {
            performSegue(withIdentifier: Segues.fromFinanceVC.toBillsArchive, sender: self)
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
        self.table.isHidden  = true
        self.loader.isHidden = false
        self.loader.startAnimating()
    }
    
    private func stopAnimation() {
        self.loader.stopAnimating()
        self.loader.isHidden = true
        self.table.isHidden  = false
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
            var dat: [AccountBillsJson] = []
            dat.append(receipts[safe: index]!)
            vc.data_ = dat
            vc.allData_ = receipts
        } else if segue.identifier == Segues.fromFinanceVC.toReceiptArchive {
            let vc = segue.destination as! FinanceDebtArchiveVCComm
            vc.data_ = receipts
            
        } else if segue.identifier == Segues.fromFinanceVC.toBillsArchive {
            let vc = segue.destination as! FinanceDebtArchiveVCComm
            var bills = receipts
            bills.removeAll()
            receipts.forEach{
                if $0.payment_name == "Не оплачен"{
                    bills.append($0)
                }
            }
            vc.title = "Неоплаченные счета"
            vc.data_ = bills
        } else if segue.identifier == Segues.fromFinanceVC.toCalcs {
            let vc = segue.destination as! FinanceCalcVC3Comm
            let date = (filteredCalcs[index].numMonthSet, filteredCalcs[index].numYearSet)
            vc.debt = debt
            vc.dataDebt = receipts
            vc.index = index
            vc.date = date
            vc.filteredCalcs = filteredCalcs
            vc.calcs = calcs
            vc.data_ = self.calcs.filter {
                return date.0 == $0.numMonthSet && date.1 == $0.numYearSet
            }
        } else if segue.identifier == Segues.fromFinanceVC.toHistory {
//            let vc = segue.destination as! FinanceHistoryPayController
            
        } else if segue.identifier == Segues.fromFinanceVC.toCalcsArchive {
            let vc = segue.destination as! FinanceCalcsArchiveVCComm
            vc.debt = debt
            vc.dataDebt = receipts
            vc.data_ = calcs
            
        } else if segue.identifier == Segues.fromFinanceVC.toPay {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.accountData_ = debt
            vc.billsData_ = receipts[0]
        }
    }
}

final class FinanceSectionCommCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var img:     UIImageView!
    @IBOutlet private weak var imgHeight: NSLayoutConstraint!
    @IBOutlet private weak var imgWidth: NSLayoutConstraint!
    @IBOutlet private weak var botConst1: NSLayoutConstraint!
    @IBOutlet private weak var botConst2: NSLayoutConstraint!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var botView: UIView!
    var section = 0
    func display(_ title: String, section: Int, last: Bool) {
        self.section = section
        self.title.text     = title
        self.img.image = UIImage(named: "expand")
        imgHeight.constant = 10
        imgWidth.constant = 16
        botConst1.constant = 0
        botConst2.constant = 0
        if section == 1{
            topView.isHidden = true
            botView.isHidden = false
        }else if section == 2{
            topView.isHidden = false
            botView.isHidden = true
            botConst1.constant = 10
            botConst2.constant = 10
        }else if section == 3{
            topView.isHidden = true
            botView.isHidden = false
        }else if section == 4{
            topView.isHidden = false
            botView.isHidden = true
        }
        if title == "История оплат"{
            self.img.image = UIImage(named: "arrow_right")
            imgHeight.constant = 16
            imgWidth.constant = 10
        }else if title == "Неоплаченные счета"{
            self.img.image = UIImage(named: "arrow_right")
            imgHeight.constant = 16
            imgWidth.constant = 10
        }
    }
    
    func expand(_ isExpanded: Bool) {
        if !isExpanded {
            self.img.image = UIImage(named: "expand")
            if section == 4{
                botView.isHidden = true
            }
        } else {
            self.img.image = UIImage(named: "expanded")
            if section == 4{
                botView.isHidden = false
            }
        }
    }
}


final class FinanceHeaderCommCell: UITableViewCell {
    
    @IBOutlet private weak var amount: UILabel!
    @IBOutlet private weak var titlePay: UILabel!
    
    @IBOutlet weak var pay_button: UIButton!
    @IBOutlet weak var fonIMG: UIImageView!
    @IBOutlet weak var fonIMG2: UIImageView!
    @IBOutlet weak var fonHeight: NSLayoutConstraint!
    @IBOutlet weak var heightPayed: NSLayoutConstraint!
    
    @IBAction private func barcodePressed(_ sender: UIButton) {
    }
    
    func display(amount: String, date: String) {
        if amount.contains(find: "-"){
            titlePay.text = "Переплата"
            self.amount.text = amount.replacingOccurrences(of: "-", with: "")
        }else{
            titlePay.text = "Оплатите"
            self.amount.text = amount
        }
//        self.date.text      = date
        
        let defaults = UserDefaults.standard
        
        if (defaults.bool(forKey: "denyTotalOnlinePayments")) {
//            pay_button.isHidden   = true
        } else if (defaults.bool(forKey: "denyOnlinePayments")) {
//            pay_button.isHidden   = defaults.bool(forKey: "denyOnlinePayments")
        }
//        if pay_button.isHidden{
//            fonIMG.image = UIImage(named: "greenPay_fon")!
//            fonIMG2.isHidden = true
//            heightPayed.constant = 0
//            fonHeight.constant  = 0
//        }else{
            fonIMG.image = UIImage(named: "mainPay_fon")!
//            fonIMG2.isHidden        = false
//            fonHeight.constant      = 15
            heightPayed.constant    = 48
//        }
        //        print(isPayed.constant, heigthPayed.constant)
        // Выводить или нет кнопку QR-код
        
    }
}


final class FinanceCommCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var botView: UIView!
    
    func display(title: String, desc: String) {
        self.title.text = title
        self.desc.text  = desc.replacingOccurrences(of: ".", with: ",")
        if title == "Аванс" || desc.contains(find: "-"){
            self.desc.textColor = mainGreenColor
        }else{
            self.desc.textColor = .lightGray
        }
        if (title == "" || title == "Аванс") {
            img.image = nil
        }else{
            img.image = UIImage(named: "arrow_right")
        }
        if title == "История взаиморасчетов"{
            botView.isHidden = true
        }else{
            botView.isHidden = false
        }
    }
}
