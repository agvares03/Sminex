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

final class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var heigth_top_logo: NSLayoutConstraint!
    @IBOutlet private weak var sprtBtm:     NSLayoutConstraint!
    @IBOutlet private weak var sprtTop:     NSLayoutConstraint!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet weak var edLogin:     UITextField!
    @IBOutlet weak var edPass:      UITextField!
    @IBOutlet private weak var btnReg:      UIButton!
    @IBOutlet private weak var btnEnter:    UIButton!
    @IBOutlet private weak var btnForgot:   UIButton!
    @IBOutlet private weak var showpswrd:   UIButton!
    
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    
    @IBOutlet private weak var sprtLabel:   UILabel!
    @IBOutlet private weak var lsLabel:     UILabel!
    @IBOutlet private weak var lineForgot:  UILabel!
    @IBOutlet private weak var lineReg:     UILabel!
    @IBOutlet private weak var errorLabel:  UILabel!
    
    // Признак того, вводим мы телефон или нет
    var edLog = ""
    var edPas = ""
    private var itsPhone = false
    private var LoginText = ""
    private var ls2:[String] = []
    
    // Какая регистрация будет
    open var roleReg_ = ""
    open var isFromSettings_ = false
    
    private let textForgot      = ""
    private var responseString  = ""
    
    // Долги - ДомЖилСервис
    private var debtDate       = "0"
    private var debtSum        = 0.0
    private var debtSumAll     = 0.0
    private var debtOverSum    = 0.0
    
//    private vals = ""
    
    @IBAction private func enter(_ sender: UIButton) {
        
        view.endEditing(true)
        // Проверка на заполнение
        var ret     = false;
        var message = ""
        
        if edLogin.text == "" {
            message = "Не указан логин. "
            ret     = true
        }
        if edPass.text == "" {
            message = message + "Не указан пароль."
            ret     = true
        }
        if ret {
            
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            if itsPhone{
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
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_PHONE + "phone=" + self.edLogin.text!)!)
        request.httpMethod = "GET"
        
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
            //            print("responseString = \(self.responseString)")
            #endif
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                // Получим список ЛС
                self.ls2 = json["data"] as! [String]
            } catch let error {
                
                #if DEBUG
                print(error)
                #endif
            }
            }.resume()
        if self.ls2.count > 1{
            self.showLS()
        }else{
            self.ls2.forEach {
                let text = $0
                self.LoginText = text
                self.edLogin.text = text
                // Сохраним значения
                self.saveUsersDefaults()
                // Запрос - получение данных !!!
                self.enter()
            }
        }
    }
    
    private func showLS(){
        let action = UIAlertController(title: nil, message: "Выберите привязанный лицевой счёт", preferredStyle: .actionSheet)
        self.ls2.forEach {
            let text = $0
            action.addAction(UIAlertAction(title: $0, style: .default, handler: { (_) in
                self.LoginText = text
                self.edLogin.text = text
                // Сохраним значения
                self.itsPhone = false
                self.saveUsersDefaults()
                
                // Запрос - получение данных !!!
                self.enter()
            }))
        }
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if edPass.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            edPass.isSecureTextEntry = false
        } else {
            
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            edPass.isSecureTextEntry = true
        }
    }
    
    @IBAction private func callSupportButtonPressed(_ sender: UIButton) {
        view.endEditing(true)
        if let url = URL(string: "tel://+74951911774") {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(TemporaryHolder.instance.log, TemporaryHolder.instance.pas)
        sprtTopConst = sprtLabel.frame.origin.y
        edLogin.delegate = self
        edPass.delegate  = self
        
        edLogin.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        edPass.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
        edPass.isSecureTextEntry = true
        
        stopIndicator()
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        scroll.addGestureRecognizer(theTap)
        
        if (TemporaryHolder.instance.log != ""){
            edLogin.text = TemporaryHolder.instance.log
            edPass.text  = TemporaryHolder.instance.pas
        }else{
            edLogin.text = UserDefaults.standard.string(forKey: "exitLogin")
            edPass.text  = UserDefaults.standard.string(forKey: "exitPass")
        }
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent         = true
        navigationController?.navigationBar.backgroundColor       = .white
        navigationController?.navigationBar.tintColor             = .white
        navigationController?.navigationBar.barTintColor          = .white
        navigationController?.navigationBar.layer.shadowColor     = UIColor.lightGray.cgColor
        navigationController?.navigationBar.layer.shadowOpacity   = 0.5
        navigationController?.navigationBar.layer.shadowOffset    = CGSize(width: 0, height: 1.0)
        navigationController?.navigationBar.layer.shadowRadius    = 1
        
        if edLogin.text == "" {
            btnEnter.isEnabled = false
            btnEnter.alpha = 0.5
            lsLabel.isHidden = true
        
        } else {
            lsLabel.isHidden = false
        }
        
        edLogin.becomeFirstResponder()
        if (TemporaryHolder.instance.log != ""){
            self.enter2()
        }
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        scroll.endEditing(true)
    }
    func enter2() {
        DispatchQueue.global(qos: .background).async {
            sleep(1)
            self.saveUsersDefaults()
            // Запрос - получение данных !!!
            self.enter()
        }
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        var height_top:CGFloat = 370// высота верхних элементов
        if (UIDevice.current.modelName.contains(find: "iPhone 4")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 4s")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5c")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5s")) ||
            (UIDevice.current.modelName.contains(find: "iPhone SE")) {
            height_top = 345
        } else if (UIDevice.current.modelName.contains(find: "iPhone 6")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 6 Plus")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 6s")) ||
            (UIDevice.current.modelName.contains(find: "Phone 6s Plus")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 7")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 7 Plus")) {
            height_top = 355
        } else if UIDevice.current.modelName.contains(find: "iPhone X") {
            height_top = 385
        }
        else if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) || Device() == .iPhone4s || Device() == .simulator(.iPhone4s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) {
            height_top = 345
        }
        
        
        let userInfo = sender?.userInfo
        let kbFrameSize = (userInfo?[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let numb_to_move:CGFloat = kbFrameSize.height
//        scroll.contentOffset = CGPoint(x: 0, y: kbFrameSize.height)

        if !isNeedToScrollMore() {
            sprtTop.constant = view.frame.size.height - numb_to_move - height_top//getPoint() - numb_to_move

        } else {
            sprtTop.constant = getPoint() - 100
            sprtBtm.constant += 200
        }

        if isNeedToScroll() {

            if isNeedToScrollMore() {
                scroll.contentOffset = CGPoint(x: 0, y: 100)
                scroll.contentSize.height += 50

            } else {
//                view.frame.origin.y = -60
            }
        }
        
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        var numb_to_move:CGFloat = 240;
        if (UIDevice.current.modelName.contains(find: "iPhone 4")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 4s")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5c")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5s")) ||
            (UIDevice.current.modelName.contains(find: "Simulator")) {
            numb_to_move = 200;
        }

        if !isNeedToScrollMore() {
            sprtTop.constant = getPoint()

        } else {
            sprtTop.constant = getPoint()
            sprtBtm.constant -= numb_to_move
        }

        if isNeedToScroll() {
            view.frame.origin.y = 0

            if isNeedToScrollMore() {
                scroll.contentOffset = CGPoint(x: 0, y: 0)
                scroll.contentSize.height -= 50
            }
        }
        
//        scroll.contentOffset = CGPoint.zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sprtTop.constant = getPoint()
        
        // Скроем верхний бар при появлении
        navigationController?.isNavigationBarHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func enter(login: String? = nil, pass: String? = nil) {
        
        if !isFromSettings_ {
            startIndicator()
        }
        // Авторизация пользователя
        DispatchQueue.main.async {
        let txtLogin = login == nil ? self.edLogin.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : login?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let txtPass = pass == nil ? self.edPass.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? "" : pass ?? ""
        
            var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + getHash(pass: txtPass, salt: (login == nil ? self.getSalt(login: txtLogin) : Sminex.getSalt())) + "&addBcGuid=1")!)
        request.httpMethod = "GET"
        
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
            
//            #if DEBUG
//                print("responseString = \(self.responseString)")
//
//            #endif
            
            self.choice()
            
            }.resume()
        }
    }
    
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
                self.errorLabel.isHidden = false
                
            } else {
                if !self.isFromSettings_ {
                    self.errorLabel.isHidden = true
                }
                
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
                    db.parse_Apps(login: self.edLogin.text ?? "", pass: self.edPass.text ?? "", isCons: "1")
                    
                    // Дома, квартиры, лицевые счета
                    db.del_db(table_name: "Houses")
                    db.del_db(table_name: "Flats")
                    db.del_db(table_name: "Ls")
                    db.parse_Houses()
                    
                    if !self.isFromSettings_ {
                        self.performSegue(withIdentifier: Segues.fromViewController.toAppsCons, sender: self)
                    }
                    
                } else {                         // пользователь
                    
                    if !self.isFromSettings_ {
                        // ПОКАЗАНИЯ СЧЕТЧИКОВ
                        // Удалим данные из базы данных
                        db.del_db(table_name: "Counters")
                        // Получим данные в базу данных
                        db.parse_Countrers(login: self.edLogin.text ?? "", pass: self.edPass.text ?? "", history: answer[7])
                        
                        // ВЕДОМОСТЬ (Пока данные тестовые)
                        // Удалим данные из базы данных
                        db.del_db(table_name: "Saldo")
                        // Получим данные в базу данных
                        db.parse_OSV(login: self.edLogin.text ?? "", pass: self.edPass.text ?? "")
                        
                        // ЗАЯВКИ С КОММЕНТАРИЯМИ
                        db.del_db(table_name: "Applications")
                        db.del_db(table_name: "Comments")
                        db.parse_Apps(login: self.edLogin.text ?? "", pass: self.edPass.text ?? "", isCons: "0")
                        
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
                print("token (add) = \(String(describing: self.responseString))")
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
            print(String(data: data!, encoding: .utf8) ?? "")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        view.endEditing(true)
        
        if segue.identifier == Segues.fromViewController.toForget {
            
            let regVC = segue.destination as! Registration_Sminex
            regVC.isReg_ = false
        
        } else if segue.identifier == Segues.fromViewController.toRegister {
            
            let regVC = segue.destination as! Registration_Sminex
            regVC.isReg_ = true
        
        } else if segue.identifier == Segues.fromViewController.toAppsUser {
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            getContacts(login: login, pwd: getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login)))
        }
        
    }
    
    private func startIndicator() {
        DispatchQueue.main.async {
            self.btnEnter.isHidden      = true
            self.btnForgot.isHidden     = true
            self.btnReg.isHidden        = true
            self.lineForgot.isHidden    = true
            self.lineReg.isHidden       = true
            
            self.indicator.startAnimating()
            self.indicator.isHidden     = false
        }
    }
    
    private func stopIndicator() {
        self.btnEnter.isHidden      = false
        self.btnForgot.isHidden     = false
        self.btnReg.isHidden        = false
        self.lineForgot.isHidden    = false
        self.lineReg.isHidden       = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden     = true
    }
    
    private func saveUsersDefaults() {
        let defaults = UserDefaults.standard
//        defaults.setValue(edLogin.text!, forKey: "login")
        DispatchQueue.main.async {
            defaults.setValue(self.edPass.text!, forKey: "pass")
            defaults.synchronize()
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if edLogin.text == "" {
            lsLabel.isHidden = true
        
        } else {
            lsLabel.isHidden = false
        }
        
        if edLogin.text == "" || edPass.text == "" {
            btnEnter.isEnabled = false
            btnEnter.alpha = 0.5
            
        } else {
            btnEnter.isEnabled = true
            btnEnter.alpha = 1
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
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
//
        // определим телефон это или нет
        var ls_1_end = ""
        if (LoginText.count < 1) {
            ls_1_end = ""
        } else {
            let ls_1 = LoginText.index(LoginText.startIndex, offsetBy: 1)
            ls_1_end = LoginText.substring(to: ls_1)
        }

        var ls_12_end = ""
        if (LoginText.count < 2) {
            ls_12_end = ""
        } else {
            let ls_12 = LoginText.index(LoginText.startIndex, offsetBy: 2)
            ls_12_end = LoginText.substring(to: ls_12)
        }
        if (ls_1_end == "+") {
            itsPhone = true
        }
        if (!itsPhone) {
            if (ls_12_end == "89") || (ls_12_end == "79") {
                itsPhone = true
            }
        }
//
        return true
        
    }
}

