//
//  FinanceHistoryPayController.swift
//  Sminex
//
//  Created by Sergey Ivanov on 16/07/2019.
//

import UIKit

class FinanceHistoryPayController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBAction func backClick(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var allPaysBtn: UIButton!
    @IBOutlet weak var mobilePaysBtn: UIButton!
    @IBOutlet weak var selectAllPay: UILabel!
    @IBOutlet weak var selectMobilePay: UILabel!
    
    @IBOutlet weak var dateConst2: NSLayoutConstraint!
    @IBOutlet weak var dateConst: NSLayoutConstraint!
    @IBOutlet weak var sumConst2: NSLayoutConstraint!
    @IBOutlet weak var back: UIBarButtonItem!
    @IBOutlet private weak var tableView:       UITableView!
    @IBOutlet private weak var headerView:      UIView!
    @IBOutlet private weak var dateLabel:       UILabel!
    @IBOutlet private weak var sumLabel:        UILabel!
    
    private var values: [HistoryPayCellData] = []
    
    var paysType = 0
    @IBAction func allPaysAction(_ sender: UIButton) {
        paysType = 0
        parse_all(login: login, pass: pass)
        allPaysBtn.tintColor = mainGreenColor
        selectAllPay.backgroundColor = mainGreenColor
        mobilePaysBtn.tintColor = mainGrayColor
        selectMobilePay.backgroundColor = mainGrayColor
    }
    
    @IBAction func mobilePaysAction(_ sender: UIButton) {
        paysType = 1
        parse_Mobile(login: login, pass: pass)
        allPaysBtn.tintColor = mainGrayColor
        selectAllPay.backgroundColor = mainGrayColor
        mobilePaysBtn.tintColor = mainGreenColor
        selectMobilePay.backgroundColor = mainGreenColor
    }
    
    var login = ""
    var pass  = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isHidden = false
        headerView.isHidden = false
        allPaysBtn.isHidden = false
        mobilePaysBtn.isHidden = false
        selectMobilePay.isHidden = false
        selectAllPay.isHidden = false
        login = UserDefaults.standard.string(forKey: "login")!
        pass  = UserDefaults.standard.string(forKey: "pass")!
        parse_all(login: login, pass: pass)
        mobilePaysBtn.isHidden = true
        selectMobilePay.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        allPaysBtn.tintColor = mainGreenColor
        selectAllPay.backgroundColor = mainGreenColor
        mobilePaysBtn.tintColor = mainGrayColor
        selectMobilePay.backgroundColor = mainGrayColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func parse_all(login: String, pass: String) {
        values.removeAll()
        let urlPath = Server.SERVER + Server.GET_PAYS + "accID=" + UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986()!
        
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        print(request)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                //                                                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                //                                                print("responseString = \(responseString)")
                                                if error != nil {
                                                    return
                                                } else {
                                                    do {
                                                        var bill_date    = ""
                                                        var bill_id      = ""
                                                        var bill_ident   = ""
                                                        var bill_period  = ""
                                                        var bill_sum     = ""
                                                        var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                        print(json)
                                                        if let json_bills = json["data"] {
                                                            let int_end = (json_bills.count)!-1
                                                            if (int_end < 0) {
                                                                
                                                            } else {
                                                                
                                                                for index in 0...int_end {
                                                                    let json_bill = json_bills.object(at: index) as! [String:AnyObject]
                                                                    for obj in json_bill {
                                                                        if obj.key == "Date" {
                                                                            bill_date = obj.value as! String
                                                                        }
                                                                        if obj.key == "ID" {
                                                                            bill_id = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Ident" {
                                                                            bill_ident = obj.value as! String
                                                                        }
                                                                        if obj.key == "Period" {
                                                                            bill_period = obj.value as! String
                                                                        }
                                                                        if obj.key == "Sum" {
                                                                            bill_sum = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                    }
                                                                    var width: CGFloat = 0
                                                                    DispatchQueue.main.async{
                                                                        width = self.view.frame.size.width
                                                                    }
                                                                    self.values.append(HistoryPayCellData(date: bill_date, id: bill_id, ident: bill_ident, period: bill_period, sum: bill_sum, width: width, payType: 0))
                                                                }
                                                            }
                                                            
                                                        }
                                                        DispatchQueue.main.async(execute: {
                                                            self.tableView.reloadData()
                                                        })
                                                        
                                                    } catch let error as NSError {
                                                        print(error)
                                                    }
                                                    
                                                }
                                                
        })
        task.resume()
        
    }
    
    func parse_Mobile(login: String, pass: String) {
        values.removeAll()
        let urlPath = Server.SERVER + "MobileAPI/GetPays.ashx?" + "phone=" + login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!;
        
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        //        print(request)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                //                                                let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                //                                                print("responseString = \(responseString)")
                                                var idPay = ""
                                                var idSum = ""
                                                if error != nil {
                                                    return
                                                } else {
                                                    do {
                                                        var bill_date    = ""
                                                        var bill_id      = ""
                                                        var bill_ident   = ""
                                                        var bill_idPay   = ""
                                                        var bill_status  = ""
//                                                        var bill_desc    = ""
                                                        var bill_sum     = ""
                                                        var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                        //                                                        print(json)
                                                        if let json_bills = json["data"] {
                                                            let int_end = (json_bills.count)!-1
                                                            if (int_end < 0) {
                                                                
                                                            } else {
                                                                
                                                                for index in 0...int_end {
                                                                    let json_bill = json_bills.object(at: index) as! [String:AnyObject]
                                                                    for obj in json_bill {
                                                                        if obj.key == "Date" {
                                                                            bill_date = obj.value as! String
                                                                        }
                                                                        if obj.key == "ID" {
                                                                            bill_id = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                        if obj.key == "Ident" {
                                                                            bill_ident = obj.value as! String
                                                                        }
                                                                        if obj.key == "ID_Pay" {
                                                                            bill_idPay = obj.value as! String
                                                                        }
                                                                        if obj.key == "Status" {
                                                                            bill_status = obj.value as! String
                                                                        }
//                                                                        if obj.key == "Desc" {
//                                                                            bill_desc = obj.value as! String
//                                                                        }
                                                                        if obj.key == "Sum" {
                                                                            bill_sum = String(describing: obj.value as! NSNumber)
                                                                        }
                                                                    }
                                                                    var width: CGFloat = 0
                                                                    DispatchQueue.main.async{
                                                                        width = self.view.frame.size.width
                                                                    }
                                                                    if bill_idPay != idPay{
                                                                        self.values.append(HistoryPayCellData(date: bill_date, id: bill_id, ident: bill_ident, period: bill_status, sum: bill_sum, width: width, payType: 1))
                                                                        idPay = bill_idPay
                                                                        idSum = bill_sum
                                                                    }else{
                                                                        if bill_sum < idSum{
                                                                            self.values.removeLast()
                                                                            self.values.append(HistoryPayCellData(date: bill_date, id: bill_id, ident: bill_ident, period: bill_status, sum: bill_sum, width: width, payType: 1))
                                                                            idPay = bill_id
                                                                            idSum = bill_sum
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                            
                                                        }
                                                        DispatchQueue.main.async(execute: {
                                                            self.tableView.reloadData()
                                                        })
                                                        
                                                    } catch let error as NSError {
                                                        print(error)
                                                    }
                                                    
                                                }
                                                
        })
        task.resume()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryPayCell", for: indexPath) as! HistoryPayCell
        cell.display(values[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, layout tableViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 44.0)
    }
}

class HistoryPayCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var datePay: UILabel!
    @IBOutlet weak var summ: UILabel!
    
    fileprivate func display(_ item: HistoryPayCellData) {
        if item.payType == 0{
//            let date1: String = item.date.substring(to: item.date.index(item.date.endIndex, offsetBy: -9))
            let date1: String = String(item.date[..<item.date.index(item.date.endIndex, offsetBy: -9)])
            if !item.sum.contains("."){
                self.summ.text = item.sum + ".00"
            }else{
                let sum: Double = Double(item.sum)!
                self.summ.text = String(format:"%.2f", sum)
            }
            self.datePay.text = date1
        }else{
            //            let date1: String = item.date.substring(to: item.date.index(item.date.endIndex, offsetBy: -9))
            if !item.sum.contains("."){
                self.summ.text = item.sum + ".00"
            }else{
                let sum: Double = Double(item.sum)!
                self.summ.text = String(format:"%.2f", sum)
            }
            self.datePay.text = item.date
        }
        
    }
    
    
    
}

final class HistoryPayCellData {
    
    let date:           String
    let id:             String
    let ident:          String
    let period:         String
    let sum:            String
    let width:          CGFloat
    let payType:        Int
    
    init(date: String?, id: String?, ident: String?, period: String?, sum: String?, width: CGFloat, payType: Int) {
        
        self.date   = date   ?? ""
        self.id     = id     ?? ""
        self.ident  = ident  ?? ""
        self.period = period ?? ""
        self.sum    = sum    ?? ""
        self.width  = width
        self.payType = payType
    }
}
