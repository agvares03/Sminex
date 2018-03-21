//
//  FirstController.swift
//  DemoUC
//
//  Created by Роман Тузин on 14.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import FirebaseMessaging
import Arcane

class FirstController: UIViewController {
    
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    private var window: UIWindow?
    private var responseString = ""
    
    private var roleReg   = "2"
    private var nameUK    = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // запустим индикатор
        self.indicator.startAnimating()
        
        let defaults = UserDefaults.standard
        let name_uk_let = defaults.string(forKey: "name_uk")
        if name_uk_let != nil {
            nameUK = String(describing: name_uk_let)
        }
        
        // Если необходимо - покажем окно выбора управляющей компании
        startActivity()
    }
    
    private func startActivity() {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.CHECK_REGISTRATION)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                        
                        exit(0)
                        
                    }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
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
    
    private func choice() {
        
        if responseString != "xxx" {
            
            DispatchQueue.main.async {
                var answer = self.responseString.components(separatedBy: ";")
                let getUK = answer[0]
                self.roleReg = answer[1]
                
                if getUK == "1" {
                    
                    if self.nameUK == "" {
                        self.performSegue(withIdentifier: Segues.fromFirstController.toChooiseUk, sender: self)
                        
                    } else {
                        self.performSegue(withIdentifier: Segues.fromFirstController.toLoginUK, sender: self)
                    }
                    
                } else {
                    
                    // Если в памяти есть логин и пароль, сразу зайдем в приложение
                    self.goToApps();
                    
                }
            }
        }
    }
    
    private func goToApps() {
        
        let defaults    = UserDefaults.standard
        let login       = defaults.string(forKey: "login")
        let pass        = defaults.string(forKey: "pass")
        
        if login != nil && login != "" {
            if pass != nil && login != "" {
                enter(login: login!, pass: pass!)
                
            } else {
                performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
            }
        } else {
            performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromFirstController.toLoginUK {
            let login = segue.destination as! UINavigationController
            (login.viewControllers.first as! ViewController_UK).roleReg_ = self.roleReg
            
        } else if segue.identifier == Segues.fromFirstController.toLogin {
            let login = segue.destination as! ViewController
            login.roleReg_ = self.roleReg
            
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = roleReg
            
        } else if segue.identifier == Segues.fromFirstController.toChooiseUk {
            
            let vc = segue.destination as! Choice_UK
            vc.roleReg_ = roleReg
        }
        
    }
    
    // ВХОД В ПРИЛОЖЕНИЕ - ДУБЛЬ ФУНКЦИЙ ИЗ ViewController
    // зайдем в приложение прям отсюда
    private func enter(login: String, pass: String) {
        
        // Авторизация пользователя
        let txtLogin = login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass = pass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + getHash(pass: txtPass, salt: getSalt(login: txtLogin)))!)
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
                print("responseString = \(self.responseString)")
            #endif
            
            self.goToApp(login: login, pass: pass)
            }.resume()
    }
    
    
    private func getHash(pass: String, salt: Data) -> String {
        
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
            }.resume()
        
        queue.wait()
        return salt!
    }
    
    private func goToApp(login: String, pass: String) {
        DispatchQueue.main.async {
            
            if self.responseString == "1" {
                self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
                
            } else if self.responseString == "2" || self.responseString.contains("error") {
                self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
                
            } else {
                
                // авторизация на сервере - получение данных пользователя
                var answer = self.responseString.components(separatedBy: ";")
                
                // сохраним значения в defaults
                self.saveGlobalData(date1: answer[0], date2: answer[1], can_count: answer[2], mail: answer[3], id_account: answer[4], isCons: answer[5], name: answer[6], history_counters: answer[7], strah: "0")
                
                // отправим на сервер данные об ид. устройства для отправки уведомлений
                let token = Messaging.messaging().fcmToken
                if token != nil {
                    self.send_id_app(id_account: answer[4], token: token!)
                }
                
                // Экземпляр класса DB
                let db = DB()
                
                // Если пользователь - окно пользователя, если консультант - другое окно
                if answer[5] == "1" {          // консультант
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Comments")
                    db.del_db(table_name: "Applications")
                    db.parse_Apps(login: login, pass: pass, isCons: "1")
                    
                    // Дома, квартиры, лицевые счета
                    db.del_db(table_name: "Houses")
                    db.del_db(table_name: "Flats")
                    db.del_db(table_name: "Ls")
                    db.parse_Houses()
                    
                    self.performSegue(withIdentifier: Segues.fromFirstController.toAppsCons, sender: self)
                    
                } else {                         // пользователь
                    
                    // ПОКАЗАНИЯ СЧЕТЧИКОВ
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Counters")
                    // Получим данные в базу данных
                    db.parse_Countrers(login: login, pass: pass, history: answer[7])
                    
                    // ВЕДОМОСТЬ (Пока данные тестовые)
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Saldo")
                    // Получим данные в базу данных
                    db.parse_OSV(login: login, pass: pass)
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Applications")
                    db.del_db(table_name: "Comments")
                    db.parse_Apps(login: login, pass: pass, isCons: "0")
                    
                    self.performSegue(withIdentifier: Segues.fromFirstController.toAppsUserNow, sender: self)
                    
                }
            }
        }
    }
    
    // сохранениеи глобальных значений
    private func saveGlobalData(date1:            String,
                                date2:            String,
                                can_count:        String,
                                mail:             String,
                                id_account:       String,
                                isCons:           String,
                                name:             String,
                                history_counters: String,
                                strah:            String) {
        
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
    private func send_id_app(id_account: String, token: String) {
        let urlPath = Server.SERVER + Server.SEND_ID_GOOGLE +
            "cid=" + id_account +
            "&did=" + token +
            "&os=" + "iOS" +
            "&version=" + UIDevice.current.systemVersion +
            "&model=" + UIDevice.current.model
        
        var request = URLRequest(url: URL(string: urlPath)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                print("token (add) = \(String(describing: self.responseString))")
            #endif
            
            }.resume()
    }
}
