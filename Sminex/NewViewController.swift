//
//  ViewController.swift
//  DemoUC
//
//  Created by Роман Тузин on 16.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import FirebaseMessaging
import Arcane
import DeviceKit
import Gloss

final class NewViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var heigth_top_logo: NSLayoutConstraint!
    @IBOutlet private weak var sprtBtm:     NSLayoutConstraint!
    @IBOutlet private weak var sprtTop:     NSLayoutConstraint!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet weak var edLogin:     UITextField!
    @IBOutlet weak var edPass:      UITextField!
//    @IBOutlet private weak var btnReg:      UIButton!
    @IBOutlet private weak var btnEnter:    UIButton!
    @IBOutlet private weak var btnForgot:   UIButton!
    @IBOutlet private weak var showpswrd:   UIButton!
    
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    
//    @IBOutlet private weak var sprtLabel:   UILabel!
//    @IBOutlet private weak var lsLabel:     UILabel!
//    @IBOutlet private weak var lineForgot:  UILabel!
//    @IBOutlet private weak var lineReg:     UILabel!
    @IBOutlet private weak var errorLabel:  UILabel!
    
    // Признак того, вводим мы телефон или нет
    var edLog = ""
    var edPas = ""
    private var itsPhone = false
    private var LoginText = ""
    private var ls2:[String] = []
    
    // Какая регистрация будет
    public var roleReg_ = ""
    public var isFromSettings_ = false
    
    private let textForgot      = ""
    private var responseString  = ""
    
    // Долги - ДомЖилСервис
    private var debtDate       = "0"
    private var debtSum        = 0.0
    private var debtSumAll     = 0.0
    private var debtOverSum    = 0.0
    
//    private vals = ""
    
    @IBAction private func enter(_ sender: UIButton) {
        
        errorLabel.isHidden = true
        view.endEditing(true)
        auth = true
        // Проверка на заполнение
        var ret     = false;
        var message = ""
        self.errorLabel.text = "НЕПРАВИЛЬНЫЙ ЛОГИН ИЛИ ПАРОЛЬ"
        if edLogin.text == "" {
            message = "НЕ УКАЗАН ЛОГИН. "
            ret     = true
        }
        if edPass.text == "" {
            message = message + "НЕ УКАЗАН ПАРОЛЬ."
            ret     = true
        }
        if edLogin.text == "disp" && edPass.text == "1" {
            saveUsersDefaults()
            self.performSegue(withIdentifier: Segues.fromViewController.toAppsDisp, sender: self)
        }else if ret {
            
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
//            print("PHONE = ", edLogin.text?.count, itsPhone)
            if (itsPhone && (edLogin.text?.count == 10 || edLogin.text?.count == 11 || edLogin.text?.count == 12)) || (edLogin.text?.first == "9" && edLogin.text?.count == 10){
                self.getLSforNumber()
            }else{
                // Сохраним значения
                saveUsersDefaults()
                
                // Запрос - получение данных !!!
                enter()
            }
        }
    }
    
    private func getLSforNumber(){
        
        var phone = self.edLogin.text!
        let ls_1 = self.edLogin.text!.index(self.edLogin.text!.startIndex, offsetBy: 1)
        let ls_1_end = String(self.edLogin.text![..<ls_1])
        if ls_1_end == "9"{
            phone = "+7" + self.edLogin.text!
        }
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_PHONE + "phone=" + phone)!)
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
                }
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                        print("ArrLS = \(self.responseString)")
            #endif
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                // Получим список ЛС
                self.ls2 = json["data"] as! [String]
                if self.ls2.count > 1{
                    self.showLS()
                }else if self.ls2.count == 0{
                    // Сохраним значения
                    DispatchQueue.main.async {
//                        self.LoginText = self.edLogin.text!
//                        self.saveUsersDefaults()
                        self.errorLabel.text = "Л/сч не найден"
                        self.errorLabel.isHidden = false
                    }
//                    // Запрос - получение данных !!!
//                    self.enter()
                }else{
                    self.ls2.forEach {
                        let text = $0
                        DispatchQueue.main.async {
                            self.LoginText = text
                            self.edLogin.text = text
                        // Сохраним значения
                            self.saveUsersDefaults()
                        }
                        // Запрос - получение данных !!!
                        self.enter()
                    }
                }
            } catch let error {
                
                #if DEBUG
                print(error)
                #endif
            }
            }.resume()
    }
    
    private func showLS(){
        DispatchQueue.main.async{
            let action = UIAlertController(title: nil, message: "Выберите привязанный лицевой счет", preferredStyle: .actionSheet)
            self.ls2.forEach {
                let text = $0
                action.addAction(UIAlertAction(title: $0, style: .default, handler: { (_) in
                    self.LoginText = text
    //                self.edLogin.text = text
                    // Сохраним значения
    //                self.itsPhone = false
                    self.saveUsersDefaults()
                    
                    // Запрос - получение данных !!!
                    self.enter()
                }))
            }
            action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
            self.present(action, animated: true, completion: nil)
        }
    }
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if edPass.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            showpswrd.tintColor = mainGreenColor
            edPass.textColor = mainGreenColor
            edPass.isSecureTextEntry = false
        } else {
            showpswrd.tintColor = mainGrayColor
            edPass.textColor = mainGrayColor
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            edPass.isSecureTextEntry = true
        }
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
    
    // Анимация перехода
    private var transitionManager = TransitionManager()
    private var sprtTopConst: CGFloat = 0.0
    private var salt = Data()
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black 
        if #available(iOS 12, *) {
            // Disables the password autoFill accessory view.
            edLogin.textContentType = UITextContentType.oneTimeCode
            edPass.textContentType = UITextContentType.oneTimeCode
        }else{
            edLogin.textContentType = UITextContentType.nickname
            edPass.textContentType = UITextContentType.nickname
        }
        self.errorLabel.isHidden = true
//        sprtTopConst = sprtLabel.frame.origin.y
        edLogin.delegate = self
        edPass.delegate  = self
        
        edLogin.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        edPass.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
        edPass.isSecureTextEntry = true
        
        stopIndicator()
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        edLogin.text = UserDefaults.standard.string(forKey: "exitLogin")
        edPass.text  = UserDefaults.standard.string(forKey: "exitPass")
        
        if edLogin.text == "" {
            btnEnter.isEnabled = false
//            btnEnter.alpha = 0.5
//            lsLabel.isHidden = true
        
        } else {
//            lsLabel.isHidden = false
        }
        
        edLogin.becomeFirstResponder()
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification) {
//        var height_top:CGFloat = 370// высота верхних элементов
//        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) || Device() == .iPhone4s || Device() == .simulator(.iPhone4s) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .iPhone4 || Device() == .simulator(.iPhone4) {
//            height_top = 345
//        } else if Device() == .iPhone6 || Device() == .simulator(.iPhone6) || Device() == .iPhone6s || Device() == .simulator(.iPhone6s) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone7 || Device() == .simulator(.iPhone7) || Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus){
//            height_top = 355
//        } else if Device() == .iPhoneX || Device() == .simulator(.iPhoneX) {
//            height_top = 385
//        }
//
//
//        let userInfo = sender?.userInfo
//        let kbFrameSize = (userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
//        let numb_to_move:CGFloat = kbFrameSize.height
////        scroll.contentOffset = CGPoint(x: 0, y: kbFrameSize.height)
//
//        if !isNeedToScrollMore() {
//            sprtTop.constant = view.frame.size.height - numb_to_move - height_top//getPoint() - numb_to_move
//
//        } else {
//            sprtTop.constant = getPoint() - 100
//            sprtBtm.constant += 200
//        }
//
//        if isNeedToScroll() {
//
//            if isNeedToScrollMore() {
//                scroll.contentOffset = CGPoint(x: 0, y: 100)
//                scroll.contentSize.height += 50
//
//            } else {
////                view.frame.origin.y = -60
//            }
//        }
        sprtTop.constant = 20
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            if Server().biometricType() == "face"{
                sprtBtm.constant = 0 + keyboardHeight - 34
            }else{
                sprtBtm.constant = 0 + keyboardHeight
            }
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
//        var numb_to_move:CGFloat = 240;
//        if Device() == .iPhone4 || Device() == .simulator(.iPhone4) ||
//            Device() == .iPhone4s || Device() == .simulator(.iPhone4s) ||
//            Device() == .iPhone5 || Device() == .simulator(.iPhone5) ||
//            Device() == .iPhone5c || Device() == .simulator(.iPhone5c) ||
//            Device() == .iPhone5s || Device() == .simulator(.iPhone5s) ||
//            Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) {
//            numb_to_move = 200;
//        }
//        if !isNeedToScrollMore() {
//            sprtTop.constant = getPoint()
//        } else {
//            sprtTop.constant = getPoint()
//            sprtBtm.constant -= numb_to_move
//        }
//
//        if isNeedToScroll() {
//            view.frame.origin.y = 0
//
//            if isNeedToScrollMore() {
//                scroll.contentOffset = CGPoint(x: 0, y: 0)
//                scroll.contentSize.height -= 50
//            }
//        }
        sprtTop.constant = 100
        sprtBtm.constant = 0
//        scroll.contentOffset = CGPoint.zero
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.updateUserInterface()
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
//        sprtTop.constant = getPoint()
        
        // Скроем верхний бар при появлении
        navigationController?.isNavigationBarHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func enter(login: String? = nil, pass: String? = nil, pwdE: String? = nil){
        
        if !isFromSettings_ {
            startIndicator()
        }
        // Авторизация пользователя
        if !itsPhone && !isFromSettings_{
            DispatchQueue.main.async {
                self.LoginText = self.edLogin.text!
            }
        }
        DispatchQueue.main.async {
        let txtLogin = login == nil ? self.LoginText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : login?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let txtPass = pass == nil ? self.edPass.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : pass ?? ""
        var pwd = getHash(pass: txtPass, salt: (login == nil ? self.getSalt(login: txtLogin) : Sminex.getSalt()))
            if pwdE != nil{
                pwd = pwdE ?? ""
            }
        let defaults = UserDefaults.standard
        defaults.setValue(pwd, forKey: "pwd")
        defaults.synchronize()
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + pwd + "&addBcGuid=1")!)
        request.httpMethod = "GET"
            print(request)
            
            URLSession.shared.dataTask(with: request) {
            data, response, error in
        
            if error != nil {
                DispatchQueue.main.sync {
                    
                    if !self.isFromSettings_ {
                        self.stopIndicator()
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                print("responseString = \(self.responseString)")
            #endif
            self.choice()
            }.resume()
        }
    }
    var auth = false
    private func choice() {
        
        DispatchQueue.main.async {
            if !self.isFromSettings_ {
                self.stopIndicator()
            }
            
            if self.responseString == "1" {
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "2" || self.responseString.contains("error") {
                if !self.isFromSettings_ {
                    self.errorLabel.isHidden = false
                }
            } else {
                if !self.isFromSettings_ {
                    self.errorLabel.isHidden = true
                }
//                if self.auth{
//                    self.saveUsersDefaults()
//                }
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
                               residentialArea:     answer[safe: 13] ?? "",
                               totalArea:           answer[safe: 12] ?? "",
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
                
                // Если пользователь - окно пользователя, если консультант - другое окно
                if answer[5] == "1" {          // консультант
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Comments")
                    db.del_db(table_name: "Applications")
                    db.parse_Apps(login: self.LoginText, pass: getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: self.salt) , isCons: "1")
                    
                    // Дома, квартиры, лицевые счета
                    db.del_db(table_name: "Houses")
                    db.del_db(table_name: "Flats")
                    db.del_db(table_name: "Ls")
                    db.parse_Houses()
                    
                    if !self.isFromSettings_ {
                        self.navigationController?.isNavigationBarHidden = true
                        self.performSegue(withIdentifier: Segues.fromViewController.toAppsCons, sender: self)
                    }
                    
                } else {                         // пользователь
                    
                    if !self.isFromSettings_ {
                        // УВЕДОМЛЕНИЯ
                        db.del_db(table_name: "Notifications")
                        db.parse_Notifications(id_account: answer[safe: 4]  ?? "")
                        // ПОКАЗАНИЯ СЧЕТЧИКОВ
                        // Удалим данные из базы данных
                        db.del_db(table_name: "Counters")
                        db.del_db(table_name: "TypesCounters")
                        // Получим данные в базу данных
                        db.parse_Countrers(login: self.LoginText, pass: getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: self.salt), history: answer[7])
                        
                        // ВЕДОМОСТЬ (Пока данные тестовые)
                        // Удалим данные из базы данных
                        db.del_db(table_name: "Saldo")
                        // Получим данные в базу данных
                        db.parse_OSV(login: self.LoginText, pass: self.edPass.text ?? "")
                        
                        // ЗАЯВКИ С КОММЕНТАРИЯМИ
                        db.del_db(table_name: "Applications")
                        db.del_db(table_name: "Comments")
                        db.parse_Apps(login: self.LoginText, pass: self.edPass.text ?? "", isCons: "0")
                        self.navigationController?.isNavigationBarHidden = true
                        self.performSegue(withIdentifier: Segues.fromViewController.toAppsUser, sender: self)
                    }
                }
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
//                print("token (add) = \(String(describing: self.responseString))")
            #endif
            let UUID = UIDevice.current.identifierForVendor?.uuidString
            UserDefaults.standard.setValue(UUID, forKey: "uuId")
            UserDefaults.standard.setValue(token, forKey: "googleToken")
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
    
    private func getPoint() -> CGFloat {
        if Device() != .iPhoneX && Device() != .simulator(.iPhoneX) {
            return (view.frame.size.height - sprtTopConst) - 80
            
        } else {
            return (view.frame.size.height - sprtTopConst) - 170
        }
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        //var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login.suffix(4))!)
        request.httpMethod = "GET"
        print(request)
        TemporaryHolder.instance.SaltQueue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            //            print(String(data: data!, encoding: .utf8))
            
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
            self.salt = data!
            salt = data
            TemporaryHolder.instance.salt = data
            }.resume()
        
        TemporaryHolder.instance.SaltQueue.wait()
        return salt ?? Data()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        view.endEditing(true)
        
        if segue.identifier == Segues.fromViewController.toForget {
            
            let regVC = segue.destination as! NewRegistration_Sminex
            regVC.isReg_ = false
        
        } else if segue.identifier == Segues.fromViewController.toRegister {
            
            let regVC = segue.destination as! NewRegistration_Sminex
            regVC.isReg_ = true
        
        } else if segue.identifier == Segues.fromViewController.toAppsUser {
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            getContacts(login: login, pwd: getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: self.salt))
        }
        
    }
    
    private func startIndicator() {
        DispatchQueue.main.async {
            self.btnEnter.isHidden      = true
            self.btnForgot.isHidden     = true
//            self.btnReg.isHidden        = true
//            self.lineForgot.isHidden    = true
//            self.lineReg.isHidden       = true
            
            self.indicator.startAnimating()
            self.indicator.isHidden     = false
        }
    }
    
    private func stopIndicator() {
        self.btnEnter.isHidden      = false
        self.btnForgot.isHidden     = false
//        self.btnReg.isHidden        = false
//        self.lineForgot.isHidden    = false
//        self.lineReg.isHidden       = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden     = true
    }
    
    private func saveUsersDefaults() {
//        let txtLogin = self.LoginText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass = self.edPass.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let pwd = getHash(pass: txtPass, salt: self.salt)
        let defaults = UserDefaults.standard
        defaults.setValue(edLogin.text!, forKey: "login")
        DispatchQueue.main.async {
            defaults.setValue(self.edPass.text!, forKey: "pass")
            defaults.setValue(pwd, forKey: "pwd")
            defaults.synchronize()
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if edLogin.text == "" {
//            lsLabel.isHidden = true
        
        } else {
//            lsLabel.isHidden = false
        }
        
        if edLogin.text == "" || edPass.text == "" {
            btnEnter.isEnabled = false
//            btnEnter.alpha = 0.5
            
        } else {
            btnEnter.isEnabled = true
            btnEnter.alpha = 1
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        if textField == edLogin{
            LoginText = edLogin.text!
            //        if string == "" {
            //
            //            let ls_ind = LoginText.index(LoginText.endIndex, offsetBy: -1)
            //            let ls_end = LoginText.substring(to: ls_ind)
            //            LoginText = ls_end
            //            if (ls_end == "") {
            //                itsPhone = false
            //            }
            //        } else {
            //
            //            LoginText = LoginText + string
            //        }
            // определим телефон это или нет
            var ls_1_end = ""
            
            if (LoginText.count < 1) {
                ls_1_end = ""
            } else {
                let ls_1 = LoginText.index(LoginText.startIndex, offsetBy: 1)
                ls_1_end = String(LoginText[..<ls_1])
            }
            var ls_12_end = ""
            if (LoginText.count < 2) {
                ls_12_end = ""
            } else {
                let ls_12 = LoginText.index(LoginText.startIndex, offsetBy: 2)
                ls_12_end = String(LoginText[..<ls_12])
            }
            if (ls_1_end == "+") {
                itsPhone = true
            }else if (string.count == 10 || string.count == 11 || string.count == 12){
                itsPhone = true
            }else if (ls_12_end == "89") || (ls_12_end == "79") {
                itsPhone = true
            }else if (ls_1_end == "9") && (LoginText.count == 10 || LoginText.count == 9) {
                itsPhone = true
            }else{
                itsPhone = false
            }
        }
        return true
        
    }
}

public var mainGreenColor: UIColor = UIColor(red: 95/255, green: 165/255, blue: 17/255, alpha: 1.0)
public var mainGrayColor: UIColor = UIColor(red: 89/255, green: 102/255, blue: 112/255, alpha: 1.0)
public var navigationGrayColor: UIColor = UIColor(red: 77/255, green: 86/255, blue: 97/255, alpha: 1.0)
public var mainOrangeColor: UIColor = UIColor(red: 229/255, green: 135/255, blue: 10/255, alpha: 1.0)
public var mainBeigeColor: UIColor = UIColor(red: 212/255, green: 209/255, blue: 196/255, alpha: 1.0)

