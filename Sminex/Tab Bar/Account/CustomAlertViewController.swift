//
//  CustomAlertViewController.swift
//  Sminex
//
//  Created by Sergey Ivanov on 07.09.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit
import Gloss
import DeviceKit
import FirebaseMessaging

private protocol MainDataProtocol:  class {}

class CustomAlertViewController: UIViewController {
    private var data: [AllLsData] = []
    open var tapped: AllLsData?
    private var index = 0
    var edLoginText = String()
    var edPassText = String()
    
    private var responseString  = ""
    
    // Долги - ДомЖилСервис
    private var debtDate       = "0"
    private var debtSum        = 0.0
    private var debtSumAll     = 0.0
    private var debtOverSum    = 0.0

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var viewConst: NSLayoutConstraint!
    @IBOutlet weak var tableConst: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func addLSBtnPressed(_ sender: UIButton) {
    }
    @IBAction func cancelBtnPressed(_ sender: UIButton) {
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(tapGestureRecognizer:)))
//        self.view.isUserInteractionEnabled = true
//        self.view.addGestureRecognizer(tapGestureRecognizer)
//        if tapped != nil {
//            performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
//        }
        TemporaryHolder.instance.allLS.removeAll()
        self.data.removeAll()
        self.startAnimation()
        getAllLS()
    }
    
    @objc func viewTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let tappedView = tapGestureRecognizer.view as! UIView
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    
    func tappedCell() {
        let login1 = UserDefaults.standard.string(forKey: "login")
        tapped = data[index]
        let ident: String = (tapped?.ident)! as String
        if login1 != ident{
            self.startAnimation()
            var request = URLRequest(url: URL(string: Server.SERVER + "GetPwdHashByIdent.ashx?" + "ident=" + ident)!)
            request.httpMethod = "GET"
            print(request)
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if error != nil {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                        self.stopAnimation()
                    }
                    return
                }
                
                let responseString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
                print("responseString = \(responseString)")
                #endif
                self.edLoginText = ident
                self.edPassText = responseString
                self.enter()
                }.resume()
        }
    }
    
    private func getAllLS(){
        TemporaryHolder.instance.allLS.removeAll()
        self.data.removeAll()
        let lsList      : [String] = UserDefaults.standard.stringArray(forKey: "allLS")!
        let addressList : [String] = UserDefaults.standard.stringArray(forKey: "allAddress")!
            if lsList.count != 0 {
                var i = 0
                lsList.forEach(){
                    TemporaryHolder.instance.allLS.append(AllLsData(ident: $0, address: addressList[i]))
                    i += 1
                }
                self.data = TemporaryHolder.instance.allLS
                self.stopAnimation()
                self.tableView.reloadData()
            }
    }
    
    private func exit() {
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let deviceId = UserDefaults.standard.string(forKey: "googleToken") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.DELETE_CLIENT + "login=\(login)&pwd=\(pwd)&deviceid=\(deviceId)")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            }.resume()
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "pass"), forKey: "exitPass")
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "login"), forKey: "exitLogin")
        UserDefaults.standard.removeObject(forKey: "accountIcon")
        UserDefaults.standard.removeObject(forKey: "googleToken")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "DealsImg")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "newsLastId")
        UserDefaults.standard.set(true, forKey: "backBtn")
        UserDefaults.standard.synchronize()
        self.choice()
        self.saveUsersDefaults()
    }
    
    private func deleteLS(code: String) {
        var lsList      : [String] = []
        var addressList : [String] = []
        var imageList   : [String:Data] = [:]
        
        lsList = UserDefaults.standard.stringArray(forKey: "allLS")!
        addressList = UserDefaults.standard.stringArray(forKey: "allAddress")!
        if UserDefaults.standard.dictionary(forKey: "allIcon") != nil{
            imageList = UserDefaults.standard.dictionary(forKey: "allIcon") as! [String : Data]
        }
        let k = lsList.firstIndex(of: code)
        
        lsList.remove(at: k!)
        addressList.remove(at: k!)
        if let l = imageList.keys.firstIndex(of: code){
            imageList.remove(at: l)
        }
        let defaults = UserDefaults.standard
        defaults.setValue(lsList, forKey: "allLS")
        defaults.setValue(addressList, forKey: "allAddress")
        defaults.setValue(imageList, forKey: "allIcon")
        defaults.synchronize()
    }
    
    func enter(login: String? = nil, pass: String? = nil) {
        
        // Авторизация пользователя
        DispatchQueue.main.async {
            let txtLogin = login == nil ? self.edLoginText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : login?.stringByAddingPercentEncodingForRFC3986() ?? ""
            let txtPass = pass == nil ? self.edPassText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : pass ?? ""
            var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + txtPass.stringByAddingPercentEncodingForRFC3986()! + "&addBcGuid=1")!)
            request.httpMethod = "GET"
            print(request)
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in

                if error != nil {
                    DispatchQueue.main.sync {
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                        self.stopAnimation()
                    }
                    return
                }
                
                self.responseString = String(data: data!, encoding: .utf8) ?? ""
                
//                #if DEBUG
                    print("responseString = \(self.responseString)")
//                #endif
                if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                    self.responseString = self.responseString.replacingOccurrences(of: "error: ", with: "")
                    let alert = UIAlertController(title: "Ошибка", message: self.responseString, preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                    DispatchQueue.main.async {
                        self.stopAnimation()
                        self.present(alert, animated: true, completion: nil)
                    }
                }else{
                   self.exit()
                }
                }.resume()
        }
    }
    
    private func choice() {
        
        DispatchQueue.main.async {
//            print("responseString = \(self.responseString)")
            if self.responseString != "1"{
                
                // авторизация на сервере - получение данных пользователя
                var answer = self.responseString.components(separatedBy: ";")
                //                print(answer)
                
                getBCImage(id: answer[safe: 17] ?? "")
                // сохраним значения в defaults
                saveGlobalData(date1:               answer[safe: 0]  ?? "",
                               date2:               answer[safe: 1]  ?? "",
                               can_count:           answer[safe: 2]  ?? "",
                               mail:                answer[safe: 3]  ?? "",
                               id_account:          answer[safe: 4]  ?? "",
                               isCons:              answer[safe: 5]  ?? "",
                               name:                answer[safe: 6]  ?? "",
                               history_counters:    answer[safe: 7]  ?? "",
                               phone:               answer[safe: 14] ?? "",
                               contactNumber:       answer[safe: 18] ?? "",
                               adress:              answer[safe: 10] ?? "",
                               roomsCount:          answer[safe: 11] ?? "",
                               residentialArea:     answer[safe: 12] ?? "",
                               totalArea:           answer[safe: 13] ?? "",
                               strah:               "0",
                               buisness:            answer[safe: 9]  ?? "",
                               lsNumber:            answer[safe: 16] ?? "",
                               desc:                answer[safe: 15] ?? "")
                
                TemporaryHolder.instance.getFinance()
                // отправим на сервер данные об ид. устройства для отправки уведомлений
                let token = Messaging.messaging().fcmToken
                if token != nil {
                    self.sendAppId(id_account: answer[4], token: token!)
                }
                
                // Экземпляр класса DB
                let db = DB()
                
                // Если пользователь - окно пользователя, если консультант - другое окно
                if answer[5] == "1" {          // консультант
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Comments")
                    db.del_db(table_name: "Applications")
                    db.parse_Apps(login: self.edLoginText, pass: self.edPassText, isCons: "1")
                    
                    // Дома, квартиры, лицевые счета
                    db.del_db(table_name: "Houses")
                    db.del_db(table_name: "Flats")
                    db.del_db(table_name: "Ls")
                    db.parse_Houses()
                    self.stopAnimation()
                    self.performSegue(withIdentifier: Segues.fromViewController.toAppsCons, sender: self)
                    
                } else {                         // пользователь
                    // ПОКАЗАНИЯ СЧЕТЧИКОВ
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Counters")
                    // Получим данные в базу данных
                    db.parse_Countrers(login: self.edLoginText, pass: self.edPassText, history: answer[7])
                    
                    // ВЕДОМОСТЬ (Пока данные тестовые)
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Saldo")
                    // Получим данные в базу данных
                    db.parse_OSV(login: self.edLoginText, pass: self.edPassText)
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Applications")
                    db.del_db(table_name: "Comments")
                    db.parse_Apps(login: self.edLoginText, pass: self.edPassText, isCons: "0")
                    
                    var imageList   : [String:Data] = [:]
                    
                    let login = UserDefaults.standard.string(forKey: "login")!
                    if UserDefaults.standard.dictionary(forKey: "allIcon") != nil{
                        imageList = UserDefaults.standard.dictionary(forKey: "allIcon") as! [String : Data]
                    }
                    
                    if imageList.keys.firstIndex(of: login) != nil{
                        let image = imageList[login]
                        UserDefaults.standard.setValue(image, forKey: "accountIcon")
                        
                    }else{
                        UserDefaults.standard.removeObject(forKey: "accountIcon")
                        
                    }
                    
                    self.stopAnimation()
                    self.tabBarController?.selectedIndex = 1
                    self.tabBarController?.selectedIndex = 2
                    self.removeFromParentViewController()
                    self.view.removeFromSuperview()
                }
            }
            else if self.responseString == "1" {
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.stopAnimation()
                self.present(alert, animated: true, completion: nil)

            }
        }
    }
    
    // Получим данные о долгах (ДомЖилСервис)
    private func getDebt(login: String) {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_DEBT + "ident=" + login)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil || data == nil {
                return
            }
            
            // распарсим полученный json с долгами, загоним его в память
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                
                if let j_object = json["data"] {
                    if let j_date = j_object["Date"] {
                        self.debtDate = j_date as! String
                    }
                    if let j_sum = j_object["Sum"] {
                        self.debtSum = Double(truncating: j_sum as! NSNumber)
                    }
                    if let j_over_sum = j_object["SumOverhaul"] {
                        self.debtOverSum = Double(truncating: j_over_sum as! NSNumber)
                    }
                    if let j_sum_all = j_object["SumAll"] {
                        self.debtSumAll = Double(truncating: j_sum_all as! NSNumber)
                    }
                }
                
                self.saveToStorageDebt()
                
            } catch let error {
                
                #if DEBUG
                print(error)
                #endif
            }
            
            }.resume()
    }
    
    private func saveToStorageDebt() {
        let defaults = UserDefaults.standard
        defaults.setValue(debtDate, forKey: "debt_date")
        defaults.setValue(debtSum, forKey: "debt_sum")
        defaults.setValue(debtOverSum, forKey: "debt_over_sum")
        defaults.setValue(debtSumAll, forKey: "debt_sum_all")
        defaults.synchronize()
    }
    
    // Отправка ид для оповещений
    private func sendAppId(id_account: String, token: String) {
        let urlPath = Server.SERVER + Server.SEND_ID_GOOGLE +
            "cid=" + id_account +
            "&did=" + token +
            "&os=" + "iOS" +
            "&version=" + UIDevice.current.systemVersion +
            "&model=" + UIDevice.current.model
        let url = URL(string: urlPath)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8)!
            
            #if DEBUG
//            print("token (add) = \(String(describing: self.responseString))")
            #endif
            UserDefaults.standard.setValue(self.responseString, forKey: "googleToken")
            UserDefaults.standard.synchronize()
            
            }.resume()
    }
    
    private func getContacts(login: String, pwd: String) {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_CONTACTS + "login=" + login + "&pwd=" + pwd)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                //                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                //                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                //                DispatchQueue.main.sync {
                //                    self.present(alert, animated: true, completion: nil)
                //                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                TemporaryHolder.instance.contactsList = ContactsDataJson(json: json!)!.data!
            }
            
            #if DEBUG
            //            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            }.resume()
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        request.httpMethod = "GET"
        
        TemporaryHolder.instance.SaltQueue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            defer {
                TemporaryHolder.instance.SaltQueue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    //                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    //                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    //                    alert.addAction(cancelAction)
                    //                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            TemporaryHolder.instance.salt = data
            }.resume()
        
        TemporaryHolder.instance.SaltQueue.wait()
        return salt ?? Data()
    }
    
    private func saveUsersDefaults() {
        let defaults = UserDefaults.standard
        //        defaults.setValue(edLogin.text!, forKey: "login")
        DispatchQueue.main.async {
//            defaults.setValue(self.edPassText, forKey: "pass")
            defaults.setValue(self.edPassText.stringByAddingPercentEncodingForRFC3986()!, forKey: "pwd")
            defaults.synchronize()
        }
    }
    
    private func startAnimation() {
        indicator.isHidden = false
        indicator.startAnimating()
    }
    
    private func stopAnimation() {
        indicator.isHidden = true
        indicator.stopAnimating()
    }
}

extension CustomAlertViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .simulator(.iPhone5) || Device() == .iPhone4 || Device() == .simulator(.iPhone4) || Device() == .simulator(.iPhone4s) || Device() == .iPhone5c || Device() == .simulator(.iPhone4s){
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 110 + 5
                self.tableConst.constant = 110
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 41 + 5
                self.tableConst.constant = 41
            }else if data.count >= 3{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }else if Device() == .iPhoneX || Device() == .simulator(.iPhoneX){
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 207 + 87 + 5
                self.tableConst.constant = 207 + 87
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 138 + 87 + 5
                self.tableConst.constant = 138 + 87
            }else if data.count == 3{
                self.viewConst.constant = 69 + 87 + 5
                self.tableConst.constant = 69 + 87
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }else if data.count >= 4{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 207 + 69 + 5
                self.tableConst.constant = 207 + 69
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.tableConst.constant = 138 + 69
                self.viewConst.constant = 138 + 69 + 5
            }else if data.count == 3{
                self.tableConst.constant = 69 + 69
                self.viewConst.constant = 69 + 69 + 5
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }else if data.count == 4{
                self.tableConst.constant = 69
                self.viewConst.constant = 69 + 5
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }else if data.count >= 4{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }else{
            if data.count == 0{
                self.tableView.isHidden = true
                self.backView.isHidden = true
            }else if data.count == 1{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 207 + 5
                self.tableConst.constant = 207
            }else if data.count == 2{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 138 + 5
                self.tableConst.constant = 138
            }else if data.count == 3{
                self.tableView.isHidden = false
                self.backView.isHidden = false
                self.viewConst.constant = 69 + 5
                self.tableConst.constant = 69
            }else if data.count >= 4{
                self.tableView.isHidden = false
                self.backView.isHidden = false
            }
        }
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AllLsTableCell", for: indexPath) as! AllLsTableCell
        let news = data[indexPath.row]
        cell.configure(item: news)
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        index = indexPath.row
        self.tappedCell()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let item: AllLsData = data[indexPath.row]
        let ident: String = item.ident
        if ident != UserDefaults.standard.string(forKey: "login"){
            if editingStyle == .delete{
                let alert = UIAlertController(title: "Удалить лицевой счет «\(ident)»?", message: "", preferredStyle: UIAlertControllerStyle.alert)
                let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { (_) -> Void in }
                let deleteAction = UIAlertAction(title: "Удалить", style: .destructive) { (_) -> Void in
                    self.deleteLS(code: ident)
                    self.data.remove(at: indexPath.row)
                    TemporaryHolder.instance.allLS.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .bottom)
                }
                alert.addAction(cancelAction)
                alert.addAction(deleteAction)
                self.present(alert, animated: true, completion: nil)
            }
        }else{
            let alert = UIAlertController(title: "Невозможно отвязать используемый лицевой счет!", message: "", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .cancel) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}

class AllLsTableCell: UITableViewCell {
    
    // MARK: Outlets
    
    @IBOutlet private weak var title: UILabel!
    @IBOutlet private weak var desc: UILabel!
    @IBOutlet private var checkImg: UIImageView!
    
    func configure(item: AllLsData?) {
        checkImg.isHidden = true
        let login = UserDefaults.standard.string(forKey: "login")
        guard let item = item else { return }
        
        title.text = item.ident
        desc.text = item.address
        
        if item.ident == login {
            checkImg.isHidden = false
        }
    }
    
}

final class AllLsData: MainDataProtocol {
    
    let ident:  String
    let address:   String
    
    init(ident: String, address: String) {
        self.ident   = ident
        self.address = address
    }
}
