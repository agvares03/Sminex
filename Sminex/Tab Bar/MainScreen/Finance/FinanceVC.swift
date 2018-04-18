//
//  FinanceVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/12/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import ExpyTableView

final class FinanceVC: UIViewController, ExpyTableViewDataSource, ExpyTableViewDelegate {

    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBOutlet private weak var table:   ExpyTableView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func barcodePreesed(_ sender: UIButton) {
        if debt?.codPay != "" && debt?.codPay != nil {
            performSegue(withIdentifier: Segues.fromFinanceVC.toBarcode, sender: self)
        
        } else {
            showToast(message: "Нет данных по штрихкоду")
        }
    }
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        requestPay()
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
        
        automaticallyAdjustsScrollViewInsets = false
        startAnimation()
        table.dataSource    = self
        table.delegate      = self
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.getCalculations()
            self.getAccountDebt()
            self.getBills()
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceSectionCell") as! FinanceSectionCell
        if section == 1 {
            cell.display("Квитанции")
        
        } else {
            cell.display("Взаиморасчёты")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceHeaderCell") as! FinanceHeaderCell
            cell.selectionStyle = .none
            if debt != nil {
                var datePay = self.debt?.datePay
                datePay?.removeLast(9)
                cell.display(amount: String(debt?.sumPay ?? 0.0) + " ₽", date: "До " + (datePay ?? ""))
            }
            cell.contentView.backgroundColor = backColor
            return cell
            
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCell", for: indexPath) as! FinanceCell
            if indexPath.row == 4 {
                cell.display(title: "Архив квитанции", desc: ">")
            
            } else {
                cell.display(title: getNameAndMonth(receipts[indexPath.row].numMonth ?? 0) + " \(receipts[indexPath.row].numYear ?? 0)",
                    desc: (String(receipts[indexPath.row].sum ?? 0.0)) + " >")
            }
            cell.contentView.backgroundColor = backColor
            return cell
        
        } else if indexPath.section == 3 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCell", for: indexPath) as! FinanceCell
            cell.display(title: "История взаиморасчетов", desc: ">")
            cell.contentView.backgroundColor = .white
            return cell
        
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "FinanceCell", for: indexPath) as! FinanceCell
            var debt = 0.0
            let currDate = (filteredCalcs[indexPath.row - 1].numMonthSet, filteredCalcs[indexPath.row - 1].numYearSet)
            calcs.forEach {
                if ($0.numMonthSet, $0.numYearSet) == currDate {
                    debt += ($0.sumDebt ?? 0.0)
                }
            }
            cell.display(title: getNameAndMonth(filteredCalcs[indexPath.row - 1].numMonthSet ?? 0) + " \(filteredCalcs[indexPath.row - 1].numYearSet ?? 0)",
                desc: debt != 0.0 ? "Долг " + String(debt) + " >" : ">")
            cell.contentView.backgroundColor = backColor
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
                return 0
            
            } else if filteredCalcs.count < 3 {
                return filteredCalcs.count + 1
            
            } else {
                return 4
            }
        
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        
        if state == .willExpand {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceSectionCell
            cell.expand(true)
        
        } else if state == .willCollapse {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! FinanceSectionCell
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
            return 210.0
        
        } else {
            return 50.0
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            guard indexPath.row != 0 else { return }
            
            if indexPath.row == 4 {
                performSegue(withIdentifier: Segues.fromFinanceVC.toReceiptArchive, sender: self)
            }
            index = indexPath.row - 1
            performSegue(withIdentifier: Segues.fromFinanceVC.toReceipts, sender: self)
        
        } else if indexPath.section == 2 {
            guard indexPath.row != 0 else { return }
            
            if indexPath.row == 4 {
                performSegue(withIdentifier: Segues.fromFinanceVC.toCalcsArchive, sender: self)
            }
            index = indexPath.row - 1
            performSegue(withIdentifier: Segues.fromFinanceVC.toCalcs, sender: self)
        
        } else if indexPath.section == 3 {
            if filteredCalcs.count != 0 {
                performSegue(withIdentifier: Segues.fromFinanceVC.toCalcsArchive, sender: self)
            }
        }
    }
    
    private func getAccountDebt() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_DEBT + "login=" + login + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.table.reloadData()
                    self.stopAnimation()
                }
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.debt = AccountDebtData(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)?.data!
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8)!)
            #endif
        
        }.resume()
    }
    
    private func getBills() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        let url = Server.SERVER + Server.GET_BILLS + "login=" + (login.stringByAddingPercentEncodingForRFC3986() ?? "")
        var request = URLRequest(url: URL(string: url + "&pwd=" + pwd)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else {
                return
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.receipts = AccountBillsData(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)!.data!
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            DispatchQueue.main.sync {
                self.table.reloadData()
            }
        
        }.resume()
    }
    
    private func getCalculations() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        let url = Server.SERVER + Server.CALCULATIONS + "login=" + (login.stringByAddingPercentEncodingForRFC3986() ?? "")
        var request = URLRequest(url: URL(string: url + "&pwd=" + pwd)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        
            self.calcs = AccountCalculationsData(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)!.data!.reversed()
            var currMonth = 0
            self.filteredCalcs = self.calcs.filter {
                if ($0.numMonthSet ?? 0) != currMonth {
                    currMonth = ($0.numMonthSet ?? 0)
                    return true
                }
                return false
            }
            DispatchQueue.main.sync {
                self.table.reloadData()
            }
            
        }.resume()
    }
    
    private func requestPay() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let password = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + password + "&amount=" + String(debt?.sumPay ?? 0.0))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: String(data: data!, encoding: .utf8)?.replacingOccurrences(of: "error: ", with: "") ?? "", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.url = URLRequest(url: URL(string: String(data: data!, encoding: .utf8) ?? "")!)
            
            DispatchQueue.main.sync {
                self.performSegue(withIdentifier: Segues.fromFinanceVC.toPay, sender: self)
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        
        }.resume()
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        request.httpMethod = "GET"
        
        queue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            defer {
                queue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            
            #if DEBUG
            print("salt is = \(String(describing: String(data: data!, encoding: .utf8)))")
            #endif
            
            }.resume()
        
        queue.wait()
        return salt ?? Data()
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
            return "Январь"
        } else if number_month == 2 {
            return "Февраль"
        } else if number_month == 3 {
            return "Март"
        } else if number_month == 4 {
            return "Апрель"
        } else if number_month == 5 {
            return "Май"
        } else if number_month == 6 {
            return "Июнь"
        } else if number_month == 7 {
            return "Июль"
        } else if number_month == 8 {
            return "Август"
        } else if number_month == 9 {
            return "Сентябрь"
        } else if number_month == 10 {
            return "Октябрь"
        } else if number_month == 11 {
            return "Ноябрь"
        } else {
            return "Декабрь"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceVC.toBarcode {
            let vc = segue.destination as! FinanceBarCodeVC
            vc.data_ = debt
        
        } else if segue.identifier == Segues.fromFinanceVC.toReceipts {
            let vc = segue.destination as! FinanceDebtVC
            vc.data_ = receipts[index]
        
        } else if segue.identifier == Segues.fromFinanceVC.toReceiptArchive {
            let vc = segue.destination as! FinanceDebtArchiveVC
            vc.data_ = receipts
        
        } else if segue.identifier == Segues.fromFinanceVC.toCalcs {
            let vc = segue.destination as! FinanceCalcVC
            let date = (filteredCalcs[index].numMonthSet, filteredCalcs[index].numYearSet)
            vc.data_ = calcs.filter {
                return date == ($0.numMonthSet, $0.numYearSet)
            }
        
        } else if segue.identifier == Segues.fromFinanceVC.toCalcsArchive {
            let vc = segue.destination as! FinanceCalcsArchiveVC
            vc.data_ = calcs
        
        } else if segue.identifier == Segues.fromFinanceVC.toPay {
            let vc = segue.destination as! FinancePayVC
            vc.url_ = url
        }
    }
}

final class FinanceSectionCell: UITableViewCell {
    
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


final class FinanceHeaderCell: UITableViewCell {
    
    @IBOutlet private weak var amount: UILabel!
    @IBOutlet private weak var date: UILabel!
    
    @IBAction private func barcodePressed(_ sender: UIButton) {
    }
    
    func display(amount: String, date: String) {
        self.amount.text    = amount
        self.date.text      = date
    }
}


final class FinanceCell: UITableViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    func display(title: String, desc: String) {
        self.title.text = title
        self.desc.text  = desc
        
    }
}

struct AccountDebtData: JSONDecodable {
    
    let data: AccountDebtJson?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct AccountDebtJson: JSONDecodable {
    
    let datePay:    String?
    let codPay:     String?
    let descPay:    String?
    let sumPay:     Double?
    
    init?(json: JSON) {
        
        datePay = "date_pay"    <~~ json
        codPay  = "cod_pay"     <~~ json
        descPay = "desc_pay"    <~~ json
        sumPay  = "sum_pay"     <~~ json
    }
}

struct AccountBillsData: JSONDecodable {
    
    let data: [AccountBillsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct AccountBillsJson: JSONDecodable {
    
    let idReceipts: String?
    let datePayed:  String?
    let datePay:    String?
    let codPay:     String?
    let desc:       String?
    let sum:        Double?
    let numMonth:   Int?
    let numYear: 	Int?
    
    init?(json: JSON) {
        idReceipts  = "id_receipts" <~~ json
        datePayed   = "date_payed"  <~~ json
        datePay     = "date_pay"    <~~ json
        codPay      = "cod_pay"     <~~ json
        desc        = "desc"        <~~ json
        sum         = "sum"         <~~ json
        numMonth    = "num_month"   <~~ json
        numYear     = "num_year"    <~~ json
    }
}

struct AccountCalculationsData: JSONDecodable {
    
    let data: [AccountCalculationsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct AccountCalculationsJson: JSONDecodable {
    
    let descSet:        String?
    let type:           String?
    let sumAccrued:     Double?
    let sumDebt:        Double?
    let sumPay:         Double?
    let numMonthSet:    Int?
    let numYearSet:     Int?
    
    init?(json: JSON) {
        
        numMonthSet = "num_month_set"   <~~ json
        numYearSet  = "num_year_set"    <~~ json
        sumAccrued  = "sum_accrued"     <~~ json
        sumDebt     = "sum_debt"        <~~ json
        descSet     = "desc_set"        <~~ json
        sumPay      = "sum_pay"         <~~ json
        type        = "type"            <~~ json
    }
    
    init(type: String,
         sumAccrued: Double?,
         sumDebt: Double?,
         sumPay: Double?,
         descSet: String? = nil,
         numMonthSet: Int? = nil,
         numYearSet: Int? = nil) {
        
        self.type           = type
        self.sumAccrued     = sumAccrued
        self.sumDebt        = sumDebt
        self.sumPay         = sumPay
        self.descSet        = descSet
        self.numMonthSet    = numMonthSet
        self.numYearSet     = numYearSet
    }
}











