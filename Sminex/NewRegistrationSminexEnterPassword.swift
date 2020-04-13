//
//  NewRegistrationSminexEnterPassword.swift
//  Sminex
//
//  Created by Sergey Ivanov on 19/02/2020.
//

import UIKit
import DeviceKit
import FirebaseMessaging
import Arcane
import Gloss

final class NewRegistrationSminexEnterPassword: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var didntEnter: UILabel!
    @IBOutlet private weak var sprtTop:         NSLayoutConstraint!
    @IBOutlet private weak var saveButton:      UIButton!
    @IBOutlet private weak var passTextField:   UITextField!
    @IBOutlet private weak var descTxt:         UILabel!
    @IBOutlet private weak var showpswrd:       UIButton!
    @IBOutlet private weak var waitView:        UIActivityIndicatorView!
    @IBOutlet private weak var lsText:          UILabel!
    @IBOutlet private weak var lsDesc:          UILabel!
    
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
    
    @IBAction private func saveButtonPressed(_ sender: UIButton!) {
        
        guard (passTextField.text?.count ?? 0) > 0 else {

            descTxt.textColor = mainOrangeColor
            descTxt.text = "Заполните поле"

            return
        }

        startAnimation()

        var request = URLRequest(url: URL(string: Server.SERVER + Server.CHANGE_PASSWRD + "login=" + login_ + "&pwd=" + (passTextField.text ?? ""))!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) {
            data, response, error in

            if error != nil {

                DispatchQueue.main.async(execute: {
                    self.stopAnimation()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                })
                return
            }

            self.responseString = String(data: data!, encoding: .utf8) ?? ""

            #if DEBUG
                print("responseString = \(self.responseString)")
            #endif

            DispatchQueue.main.async {

                if self.responseString.contains(find: "error") {
                    self.stopAnimation()
                    self.descTxt.text = self.responseString.replacingOccurrences(of: "error:", with: "")
                    self.descTxt.textColor = mainOrangeColor

                } else {
//                    if !self.isReg_ {
//                        self.performSegue(withIdentifier: "toAuth", sender: self)
//                    }else{
                        self.saveUsersDefaults()
                        self.makeAuth()
//                    }
                }
            }
        }.resume()
    }
    
    @objc private func backButtonPressed(_ sender: UITapGestureRecognizer?) {
        let viewControllers = navigationController?.viewControllers
        navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
    }
    
    @IBAction private func backButtonTapped(_ sender: UIBarButtonItem) {
        backButtonPressed(nil)
    }
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if passTextField.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            showpswrd.tintColor = mainGreenColor
            passTextField.textColor = mainGreenColor
            passTextField.isSecureTextEntry = false
        } else {
            showpswrd.tintColor = mainGrayColor
            passTextField.textColor = mainGrayColor
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            passTextField.isSecureTextEntry = true
        }
    }
    
    public var isReg_     = false
    public var isNew      = false
    public var login_     = "1234public"
    public var phone_     = "1234567890"
    
    private var responseString  = ""
    private var const: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = navigationGrayColor
        updateUserInterface()
        stopAnimation()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
        passTextField.isSecureTextEntry = true
        if isNew{
            didntEnter.text = "Не можете добавить ЛС?"
        }
        lsText.text = login_
        if !phone_.contains(find: "+") && phone_.prefix(1) != "8"{
            phone_ = "+" + phone_
        }
        print("PHONE: ", phone_)
        lsDesc.text = lsDesc.text! + " " + phone_
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
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
        tabBarController?.tabBar.isHidden = true
        navigationController?.isNavigationBarHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden  = true
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // Двигаем view вверх при показе клавиатуры
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
    
    // Вычисляем соленый хэш пароля
    private func getHash(pass: String, salt: Data) -> String {
        
        if (String(data: salt, encoding: .utf8) ?? "Unauthorized").contains(find: "Unauthorized") {
            return ""
        }
        
        let btl = pass.data(using: .utf16LittleEndian)!
        let bSalt = Data(base64Encoded: salt)!
        
        var bAll = bSalt + btl
        
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        bAll.withUnsafeBytes {
            _ = CC_SHA1($0, CC_LONG(bAll.count), &digest)
        }
        
        let psw = Data(bytes: digest).base64String.replacingOccurrences(of: "\n", with: "")
        
        return psw.stringByAddingPercentEncodingForRFC3986()!
    }
    
    private func startAnimation() {
        
        saveButton.isHidden = true
        waitView.isHidden = false
        
        waitView.startAnimating()
    }
    
    private func stopAnimation() {
        
        saveButton.isHidden = false
        waitView.isHidden = true
        
        waitView.stopAnimating()
    }
    private var salt = Data()
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
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
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
    
    private func makeAuth() {
        DispatchQueue.main.async {
            // Авторизация пользователя
            let txtLogin = self.login_.stringByAddingPercentEncodingForRFC3986() ?? ""
            let txtPass = self.passTextField.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
            let pwd = self.getHash(pass: txtPass, salt: self.getSalt(login: txtLogin))
            let defaults = UserDefaults.standard
            defaults.setValue(pwd, forKey: "pwd")
            defaults.synchronize()
            var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + pwd + "&addBcGuid=1")!)
            request.httpMethod = "GET"
            
//            print(request.url)
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if error != nil || data == nil {
                    DispatchQueue.main.sync {
                        
                        self.stopAnimation()
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                self.responseString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
                    print("responseString = \(self.responseString)")
                #endif
                
                DispatchQueue.main.async {
                    self.choice()
                }
                
                }.resume()
        }
    }
    var auth = false
    private func choice() {
        
        DispatchQueue.main.async {
            self.stopAnimation()
            
            if self.responseString == "1" {
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "2" || self.responseString.contains("error") {
                let alert = UIAlertController(title: "Ошибка", message: "Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            } else {
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
                    db.parse_Apps(login: self.login_, pass: self.getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: self.salt) , isCons: "1")
                    
                    // Дома, квартиры, лицевые счета
                    db.del_db(table_name: "Houses")
                    db.del_db(table_name: "Flats")
                    db.del_db(table_name: "Ls")
                    db.parse_Houses()
                    
                    self.performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toAppCons, sender: self)
                    
                } else {
                    // УВЕДОМЛЕНИЯ
                    db.del_db(table_name: "Notifications")
                    db.parse_Notifications(id_account: answer[safe: 4]  ?? "")
                    // ПОКАЗАНИЯ СЧЕТЧИКОВ
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Counters")
                    db.del_db(table_name: "TypesCounters")
                    // Получим данные в базу данных
                    db.parse_Countrers(login: self.login_, pass: self.getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: self.salt), history: answer[7])
                    
                    // ВЕДОМОСТЬ (Пока данные тестовые)
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Saldo")
                    // Получим данные в базу данных
                    db.parse_OSV(login: self.login_, pass: self.passTextField.text ?? "")
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Applications")
                    db.del_db(table_name: "Comments")
                    db.parse_Apps(login: self.login_, pass: self.passTextField.text ?? "", isCons: "0")
                    
                    if !self.isReg_ {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        self.present(storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq"), animated: true, completion: nil)
//                        self.performSegue(withIdentifier: "toAppsUser", sender: self)
//                        self.performSegue(withIdentifier: "toAuth", sender: self)
                    } else {
                        self.performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toComplete, sender: self)
                    }
                }
            }
        }
    }
    
    private func choiseSMS() {
        
        DispatchQueue.main.async {
            
            if self.responseString.contains(find: "error") {
                self.descTxt.text       = self.responseString.replacingOccurrences(of: "error:", with: "")
                self.descTxt.textColor  = mainOrangeColor
                
            } else {
                self.descTxt.textColor  = mainGrayColor
                
            }
            
            self.stopAnimation()
        }
    }
    
//    private func choice() {
//
//        self.stopAnimation()
//
//        if responseString == "1" {
//
//            let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
//            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
//            alert.addAction(cancelAction)
//            present(alert, animated: true, completion: nil)
//
//        } else if responseString == "2" || responseString.contains("error") {
//
//            let alert = UIAlertController(title: "Ошибка", message: "Попробуйте позже", preferredStyle: .alert)
//            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
//            alert.addAction(cancelAction)
//            present(alert, animated: true, completion: nil)
//
//        } else {
//
//            UserDefaults.standard.setValue(passTextField.text ?? "", forKey: "pass")
//            UserDefaults.standard.synchronize()
//            // авторизация на сервере - получение данных пользователя
//            var answer = responseString.components(separatedBy: ";")
//
//            getBCImage(id: answer[safe: 17] ?? "")
//            // сохраним значения в defaults
//            saveGlobalData(date1:               answer[safe: 0]  ?? "",
//                           date2:               answer[safe: 1]  ?? "",
//                           can_count:           answer[safe: 2]  ?? "",
//                           mail:                answer[safe: 3]  ?? "",
//                           id_account:          answer[safe: 4]  ?? "",
//                           isCons:              answer[safe: 5]  ?? "",
//                           name:                answer[safe: 6]  ?? "",
//                           history_counters:    answer[safe: 7]  ?? "",
//                           phone:               answer[safe: 14] ?? "",
//                           contactNumber:       answer[safe: 18] ?? "",
//                           adress:              answer[safe: 10] ?? "",
//                           roomsCount:          answer[safe: 11] ?? "",
//                           residentialArea:     answer[safe: 12] ?? "",
//                           totalArea:           answer[safe: 13] ?? "",
//                           strah:               "0",
//                           buisness:            answer[safe: 9]  ?? "",
//                           lsNumber:            answer[safe: 16] ?? "",
//                           desc:                answer[safe: 15] ?? "",
//                           typeОfBuildings:     answer[safe: 19] ?? "")
//
//            TemporaryHolder.instance.getFinance()
//            // отправим на сервер данные об ид. устройства для отправки уведомлений
//            let token = Messaging.messaging().fcmToken
//            if token != nil {
//                sendAppId(id_account: answer[4], token: token!)
//            }
//
//            // Экземпляр класса DB
//            let db = DB()
//
//            // Если пользователь - окно пользователя, если консультант - другое окно
//            if answer[5] == "1" {          // консультант
//
//                // ЗАЯВКИ С КОММЕНТАРИЯМИ
//                db.del_db(table_name: "Comments")
//                db.del_db(table_name: "Applications")
//                db.parse_Apps(login: login_, pass: passTextField.text ?? "", isCons: "1")
//
//                // Дома, квартиры, лицевые счета
//                db.del_db(table_name: "Houses")
//                db.del_db(table_name: "Flats")
//                db.del_db(table_name: "Ls")
//                db.parse_Houses()
//
//                self.performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toAppCons, sender: self)
//
//            } else {                         // пользователь
//                // УВЕДОМЛЕНИЯ
//                db.del_db(table_name: "Notifications")
//                db.parse_Notifications(id_account: answer[safe: 4]  ?? "")
//                // ПОКАЗАНИЯ СЧЕТЧИКОВ
//                // Удалим данные из базы данных
//                db.del_db(table_name: "Counters")
//                db.del_db(table_name: "TypesCounters")
//                // Получим данные в базу данных
//                db.parse_Countrers(login: login_, pass: self.pwdHash, history: answer[7])
//
//                // ВЕДОМОСТЬ (Пока данные тестовые)
//                // Удалим данные из базы данных
//                db.del_db(table_name: "Saldo")
//                // Получим данные в базу данных
//                db.parse_OSV(login: login_, pass: self.passTextField.text ?? "")
//
//                // ЗАЯВКИ С КОММЕНТАРИЯМИ
//                db.del_db(table_name: "Applications")
//                db.del_db(table_name: "Comments")
//                db.parse_Apps(login: login_, pass: passTextField.text ?? "", isCons: "0")
//
//                if !isReg_ {
////                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
////                    self.present(storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq"), animated: true, completion: nil)
//                    self.performSegue(withIdentifier: "toAppsUser", sender: self)
//                } else {
//                    performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toComplete, sender: self)
//                }
//
//            }
//        }
//    }
    
    private func saveUsersDefaults() {
//        let txtLogin = login_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass = passTextField.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let pwd = getHash(pass: txtPass, salt: self.salt)
        print(pwd)
        
        let defaults = UserDefaults.standard
        defaults.setValue(login_, forKey: "login")
        DispatchQueue.main.async {
            defaults.setValue(self.passTextField.text ?? "", forKey: "pass")
            defaults.setValue(pwd, forKey: "pwd")
            defaults.synchronize()
        }
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
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        view.endEditing(true)
        UserDefaults.standard.synchronize()
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        getContacts(login: login, pwd: getHash(pass: login, salt: getSalt(login: login)))
        if segue.identifier == "toAppsUser" {
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            getContacts(login: login, pwd: getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: self.salt))
        }
        if segue.identifier == Segues.fromRegistrationSminexEnterPassword.toComplete {
            let vc = (segue.destination as! UINavigationController).topViewController as! AccountSettingsVC
            vc.isReg_          = true
            vc.login_          = login_
            vc.pass_           = passTextField.text ?? ""
            vc.responceString_ = responseString
        }
    }
    
    private func getConst() -> CGFloat {
        if Device() == .iPhoneX && Device() == .simulator(.iPhoneX) {
            return (view.frame.size.height - const) - 200
            
        } else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            return (view.frame.size.height - const) - 135
        } else if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .iPhone5 || Device() == .simulator(.iPhone5){
            return (view.frame.size.height - const) - 105
        } else {
            return (view.frame.size.height - const) - 105
        }
    }
}
