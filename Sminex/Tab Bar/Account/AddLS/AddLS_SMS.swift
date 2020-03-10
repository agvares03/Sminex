//
//  Registration_Sminex_SMS.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit
import Gloss
import FirebaseMessaging

final class AddLS_SMS: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet private weak var sprtTop:     NSLayoutConstraint!
    @IBOutlet private weak var txtNameLS:   UILabel!
    @IBOutlet private weak var NameLS:      UILabel!
    @IBOutlet private weak var descTxt:     UILabel!
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    @IBOutlet private weak var btn_go:      UIButton!
    @IBOutlet private weak var smsField:    UITextField!
    @IBOutlet private weak var againLabel:  UIButton!
    
    
    
    @IBAction private func btn_go_touch(_ sender: UIButton) {
        
        guard (smsField.text?.count ?? 0) >= 0 else {
            descTxt.text = "Введите код доступа"
            return
        }
        
        view.endEditing(true)
        //        self.performSegue(withIdentifier: Segues.fromRegistrationSminexSMS.toEnterPassword, sender: self)
        startLoading()
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let code = self.code.stringByAddingPercentEncodingForRFC3986() ?? ""
        let address = UserDefaults.standard.string(forKey: "adress") ?? ""
        let smsCode = smsField.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ADD_NEW_LS + "login=\(login.stringByAddingPercentEncodingForRFC3986() ?? "")&pwd=\(pwd)&code=\(code.stringByAddingPercentEncodingForRFC3986() ?? "")&address=\(address.stringByAddingPercentEncodingForRFC3986() ?? "")&smsCode=\(smsCode.stringByAddingPercentEncodingForRFC3986() ?? "")")!)
        print(request)
        
        request.httpMethod = "GET"        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil || data == nil /*|| (String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false)*/ {
                
                DispatchQueue.main.async {
                    self.endLoading()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Обратитесь в тех. поддержку", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
            print(self.responseString)
            #endif
            
            self.choise()
            
            }.resume()
    }
    
    @IBAction private func callSupportButtonPressed(_ sender: UIButton) {
        view.endEditing(true)
        if let url = URL(string: "tel://+74957266791") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func retryLabelPressed(_ sender: UIButton) {
                
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let code = self.code.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.NEW_ACCOUNT_SMS + "login=\(login.stringByAddingPercentEncodingForRFC3986() ?? "")&pwd=\(pwd)&code=\(code)")!)
        //        print(request)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    self.endLoading()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            }.resume()
        self.againLabel.isHidden    = true
        self.startTimer()
    }
    
    @objc private func btn_cancel(_ sender: UITapGestureRecognizer?) {
        navigationController?.popViewController(animated: true)
    }
    
//    @IBAction private func retryLabelPressed(_ sender: UIButton) {
//        self.startLoading()
//        addNewLS()
//    }
    var edLoginText = String()
    var edPassText = String()
    // Долги - ДомЖилСервис
    private var debtDate       = "0"
    private var debtSum        = 0.0
    private var debtSumAll     = 0.0
    private var debtOverSum    = 0.0
    
    public var phone_       = ""
    public var code         = ""
    
    private var responseString  = ""
    private var descText        = ""
    private var topConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endLoading()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        txtNameLS.text  = "Номер лицевого счета"
        NameLS.text     = code
        descTxt.text    = "Отправлен на телефон \(phone_) (действует в течение 10 минут). Запросить новый код можно через минуту"
        
        descText = descTxt.text ?? ""
        
        btn_go.isEnabled = false
        btn_go.alpha = 0.5
        
        smsField.delegate = self
        startTimer()
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        navigationController?.isNavigationBarHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = true
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
    //        sprtTop.constant = 20
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            if Server().biometricType() == "face"{
                sprtTop.constant = 0 + keyboardHeight - 34
            }else{
                sprtTop.constant = 0 + keyboardHeight
            }
        }
    }
    
    @objc func keyboardWillHide(sender: NSNotification?) {
        sprtTop.constant = 0
    }
    
    private func startTimer() {
        DispatchQueue.global(qos: .userInteractive).async {
            sleep(60)
            
            DispatchQueue.main.async {
                self.againLabel.isHidden    = false
                self.descTxt.text = self.descTxt.text?.replacingOccurrences(of: "Запросить новый код можно через минуту", with: "")
            }
        }
    }
    
    private func choise() {
        
        DispatchQueue.main.sync {
            
            if self.responseString.contains(find: "error") {
                var txt = self.responseString.replacingOccurrences(of: "error: ", with: "")
                if txt.first == " "{
                    txt.removeFirst()
                }
                self.descTxt.text = txt
                self.descTxt.textColor  = mainOrangeColor
            } else {
                
                let ident: String = self.code
                let alert = UIAlertController(title: "Лицевой счет \(ident) добавлен", message: "", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    self.auth() }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            }
            
            self.endLoading()
        }
    }
    
    func auth() {
        let login1 = UserDefaults.standard.string(forKey: "login")
        
        let ident: String = self.code as String
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
                               desc:                answer[safe: 15] ?? "",
                               typeОfBuildings:     answer[safe: 19] ?? "")
                
                TemporaryHolder.instance.getFinance()
                // отправим на сервер данные об ид. устройства для отправки уведомлений
                let token = Messaging.messaging().fcmToken
                if token != nil {
                    self.sendAppId(id_account: answer[4], token: token!)
                }
                
                // Экземпляр класса DB
                let db = DB()
                var lsList      : [String] = []
                var addressList : [String] = []
                
                lsList = UserDefaults.standard.stringArray(forKey: "allLS")!
                addressList = UserDefaults.standard.stringArray(forKey: "allAddress")!
                var i = 0
                lsList.forEach{
                    if $0 == self.code{
                        i = 1
                    }
                }
                if i == 0{
                    lsList.append(self.code)
                    addressList.append(answer[safe: 10] ?? "")
                }
                
                let defaults = UserDefaults.standard
                defaults.setValue(lsList, forKey: "allLS")
                defaults.setValue(addressList, forKey: "allAddress")
                defaults.synchronize()
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
                    self.stopAnimation()
                    self.tabBarController?.selectedIndex = 1
                    self.tabBarController?.selectedIndex = 2
                    self.performSegue(withIdentifier: "completeAdd", sender: self)
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
        //var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login.suffix(4))!)
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
    
    private func startLoading() {
        
        indicator.isHidden = false
        indicator.startAnimating()
        
        btn_go.isHidden = true
    }
    
    private func endLoading() {
        
        indicator.isHidden = true
        indicator.stopAnimating()
        
        btn_go.isHidden = false
    }
    
    private func choiceReg() {
        
        DispatchQueue.main.async {
            self.endLoading()
            
            if self.responseString.contains("error") {
                let alert = UIAlertController(title: "Ошибка", message: self.responseString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { (_) -> Void in self.navigationController?.popViewController(animated: true) }))
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString.contains("ok") {
                self.descTxt.text           = self.descText
                self.againLabel.isHidden    = true
                self.startTimer()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if smsField.text != "" {
            btn_go.isEnabled = true
            btn_go.alpha = 1
            
        } else {
            btn_go.isEnabled = false
            btn_go.alpha = 0.5
        }
        return true
    }
    
    private func getPoint() -> CGFloat {
        if Device() == .iPhoneX && Device() == .simulator(.iPhoneX) {
            return (view.frame.size.height - topConstant) - 220
            
        } else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            return (view.frame.size.height - topConstant) - 135
        } else {
            return (view.frame.size.height - topConstant) - 120
        }
    }
}
