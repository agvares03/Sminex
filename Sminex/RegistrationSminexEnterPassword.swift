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

final class RegistrationSminexEnterPassword: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var saveButton:      UIButton!
    @IBOutlet private weak var passTextField:   UITextField!
    @IBOutlet private weak var descTxt:         UILabel!
    @IBOutlet private weak var showpswrd:       UIButton!
    @IBOutlet private weak var waitView:        UIActivityIndicatorView!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var backView:        UIView!
    
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
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if passTextField.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            passTextField.isSecureTextEntry = false
        } else {
            
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            passTextField.isSecureTextEntry = true
        }
    }
    
    open var login_ = ""
    
    private var responseString  = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopAnimation()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
        passTextField.isSecureTextEntry = true
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(backButtonPressed(_:)))
        recognizer.delegate = self
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(recognizer)
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        if isNeedToScroll() {
            
            if isNeedToScrollMore() {
                scroll.contentSize.height += 30
                scroll.contentOffset = CGPoint(x: 0, y: 50)
            
            } else {
                view.frame.origin.y = -50
            }
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if isNeedToScroll() {
            
            if isNeedToScrollMore() {
                scroll.contentSize.height -= 30
                scroll.contentOffset = CGPoint(x: 0, y: 0)
                
            } else {
                view.frame.origin.y = 0
            }
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
                           strah: "0")
            
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
                
                performSegue(withIdentifier: Segues.fromRegistrationSminexEnterPassword.toAppsUser, sender: self)
                
            }
        }
    }
    
    // сохранениеи глобальных значений
    private func saveGlobalData(date1:              String,
                                date2:              String,
                                can_count:          String,
                                mail:               String,
                                id_account:         String,
                                isCons:             String,
                                name:               String,
                                history_counters:   String,
                                strah:              String) {
        
        let defaults = UserDefaults.standard
        defaults.setValue(date1, forKey: "date1")
        defaults.setValue(date2, forKey: "date2")
        defaults.setValue(can_count, forKey: "can_count")
        defaults.setValue(mail, forKey: "mail")
        defaults.setValue(id_account, forKey: "id_account")
        defaults.setValue(isCons, forKey: "isCons")
        defaults.setValue(name, forKey: "name")
        defaults.setValue(strah, forKey: "strah")
        defaults.setValue(history_counters, forKey: "history_counters")
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
            
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Поправим текущий UI перед переходом
        keyboardWillHide(sender: nil)
    }
}
