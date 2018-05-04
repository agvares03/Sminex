//
//  RegistrationSminexEnterPassword.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit
import FirebaseMessaging
import Arcane
import Gloss

final class RegistrationSminexEnterPassword: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var sprtBtm:         NSLayoutConstraint!
    @IBOutlet private weak var sprtTop:         NSLayoutConstraint!
    @IBOutlet private weak var saveButtonTop:   NSLayoutConstraint!
    @IBOutlet private weak var saveButton:      UIButton!
    @IBOutlet private weak var passTextField:   UITextField!
    @IBOutlet private weak var descTxt:         UILabel!
    @IBOutlet private weak var showpswrd:       UIButton!
    @IBOutlet private weak var waitView:        UIActivityIndicatorView!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var backView:        UIView!
    @IBOutlet private weak var lsText:          UILabel!
    @IBOutlet private weak var lsDesc:          UILabel!
    @IBOutlet private weak var sprtLabel:       UILabel!
    
    @IBAction private func callSupportButtonPressed(_ sender: UIButton) {
        view.endEditing(true)
        if let url = URL(string: "tel://74951911774") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction private func saveButtonPressed(_ sender: UIButton!) {
        
        guard (passTextField.text?.count ?? 0) > 0 else {

            descTxt.textColor = .red
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
                    self.descTxt.textColor = .red

                } else {
                    self.makeAuth()
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
            passTextField.isSecureTextEntry = false
        } else {
            
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            passTextField.isSecureTextEntry = true
        }
    }
    
    open var isReg_     = false
    open var login_     = ""
    open var phone_     = ""
    
    private var responseString  = ""
    private var const: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        const = sprtLabel.frame.origin.y
        stopAnimation()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
        passTextField.isSecureTextEntry = true
        
        lsText.text = login_
        lsDesc.text = lsDesc.text! + " " + phone_
        
        if isNeedToScrollMore() {
            saveButtonTop.constant = 30
        }
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(backButtonPressed(_:)))
        recognizer.delegate = self
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(recognizer)
        
        sprtTop.constant = getConst()
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isNavigationBarHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.isNavigationBarHidden  = false
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        if !isNeedToScrollMore() {
            sprtTop.constant = getConst() - 215

        } else {
            sprtTop.constant = getConst() - 100
            sprtBtm.constant += 220
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if !isNeedToScrollMore() {
            sprtTop.constant = getConst()
            
        } else {
            sprtTop.constant = getConst()
            sprtBtm.constant -= 220
        }
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
                    
                    self.stopAnimation()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            }.resume()
        
        queue.wait()
        return salt!
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
    
    private func makeAuth() {
        
        // Авторизация пользователя
        let txtLogin = login_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass = passTextField.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + getHash(pass: txtPass, salt: getSalt(login: txtLogin)))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
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
    
    private func choiseSMS() {
        
        DispatchQueue.main.async {
            
            if self.responseString.contains(find: "error") {
                self.descTxt.text       = self.responseString.replacingOccurrences(of: "error:", with: "")
                self.descTxt.textColor  = .red
                
            } else {
                self.descTxt.textColor  = .gray
                
            }
            
            self.stopAnimation()
        }
    }
    
    private func choice() {
        
        self.stopAnimation()
        
        if responseString == "1" {
            
            let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
            
        } else if responseString == "2" || responseString.contains("error") {
            
            let alert = UIAlertController(title: "Ошибка", message: "Попробуйте позже", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            present(alert, animated: true, completion: nil)
            
        } else {
            
            // авторизация на сервере - получение данных пользователя
            var answer = responseString.components(separatedBy: ";")
            
            // сохраним значения в defaults
            saveGlobalData(date1: answer[0],
                           date2: answer[1],
                           can_count: answer[2],
                           mail: answer[3],
                           id_account: answer[4],
                           isCons: answer[5],
                           name: answer[6],
                           history_counters: answer[7],
                           contactNumber: answer[answer.count - 3],
                           adress: answer[10],
                           roomsCount: answer[11],
                           residentialArea: answer[12],
                           totalArea: answer[13],
                           strah: "0",
                           buisness: answer[9],
                           lsNumber: answer.last ?? "")
            
            // отправим на сервер данные об ид. устройства для отправки уведомлений
            let token = Messaging.messaging().fcmToken
            if token != nil {
                sendAppId(id_account: answer[4], token: token!)
            }
            
            // Экземпляр класса DB
            let db = DB()
            
            // Если пользователь - окно пользователя, если консультант - другое окно
            if answer[5] == "1" {          // консультант
                
                // ЗАЯВКИ С КОММЕНТАРИЯМИ
                db.del_db(table_name: "Comments")
                db.del_db(table_name: "Applications")
                db.parse_Apps(login: login_, pass: passTextField.text ?? "", isCons: "1")
                
                // Дома, квартиры, лицевые счета
                db.del_db(table_name: "Houses")
                db.del_db(table_name: "Flats")
                db.del_db(table_name: "Ls")
                db.parse_Houses()
                
                self.performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toAppCons, sender: self)
                
            } else {                         // пользователь
                
                // ПОКАЗАНИЯ СЧЕТЧИКОВ
                // Удалим данные из базы данных
                db.del_db(table_name: "Counters")
                // Получим данные в базу данных
                db.parse_Countrers(login: login_, pass: passTextField.text ?? "", history: answer[7])
                
                // ВЕДОМОСТЬ (Пока данные тестовые)
                // Удалим данные из базы данных
                db.del_db(table_name: "Saldo")
                // Получим данные в базу данных
                db.parse_OSV(login: login_, pass: self.passTextField.text ?? "")
                
                // ЗАЯВКИ С КОММЕНТАРИЯМИ
                db.del_db(table_name: "Applications")
                db.del_db(table_name: "Comments")
                db.parse_Apps(login: login_, pass: passTextField.text ?? "", isCons: "0")
                
                if !isReg_ {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    self.present(storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq"), animated: true, completion: nil)
                
                } else {
                    performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toComplete, sender: self)
                }
                
            }
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
            
            TemporaryHolder.instance.contactsList = ContactsDataJson(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)!.data!
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        view.endEditing(true)
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        getContacts(login: login, pwd: getHash(pass: login, salt: getSalt(login: login)))
        
        if segue.identifier == Segues.fromRegistrationSminexEnterPassword.toComplete {
            let vc = (segue.destination as! UINavigationController).topViewController as! AccountSettingsVC
            vc.isReg_          = true
            vc.login_          = login_
            vc.pass_           = passTextField.text ?? ""
            vc.responceString_ = responseString
        }
    }
    
    private func getConst() -> CGFloat {
        
        if Device() != .iPhoneX && Device() != .simulator(.iPhoneX) {
            return (view.frame.size.height - const) - 100
            
        } else {
            return (view.frame.size.height - const) - 200
        }
    }
}
