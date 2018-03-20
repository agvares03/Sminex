//
//  ViewController.swift
//  DemoUC
//
//  Created by Роман Тузин on 16.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import FirebaseMessaging

final class ViewController: UIViewController, UITextFieldDelegate {
    
    // Картинка вверху
    @IBOutlet private weak var fon_top:     UIImageView!
    @IBOutlet private weak var new_face:    UIImageView!
    @IBOutlet private weak var new_zamoc:   UIImageView!
    
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var edLogin:     UITextField!
    @IBOutlet private weak var edPass:      UITextField!
    @IBOutlet private weak var btnReg:      UIButton!
    @IBOutlet private weak var btnEnter:    UIButton!
    @IBOutlet private weak var btnForgot:   UIButton!
    
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var lineForgot:  UILabel!
    @IBOutlet private weak var lineReg:     UILabel!
    
    // Признак того, вводим мы телефон или нет
    private var itsPhone = false
    
    // Какая регистрация будет
    open var roleReg_ = ""
    
    private let textForgot      = ""
    private var responseString  = ""
    
    // Долги - ДомЖилСервис
    private var debtDate       = "0"
    private var debtSum        = 0.0
    private var debtSumAll    = 0.0
    private var debtOverSum   = 0.0
    
    private var ls = ""
    
    @IBAction private func enter(_ sender: UIButton) {
        
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
            
            // Сохраним значения
            saveUsersDefaults()
            
            // Запрос - получение данных !!!
            enter()
        }
    }
    
    // Анимация перехода
    private var transitionManager = TransitionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edLogin.delegate = self
        
        stopIndicator()
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        scroll.addGestureRecognizer(theTap)
        loadUsersDefaults()
        
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        scroll.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Скроем верхний бар при появлении
        
        navigationController?.isNavigationBarHidden = true
    }
    
    private func enter() {
        
        startIndicator()
        
        // Авторизация пользователя
        let txtLogin = edLogin.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass = edPass.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + getHash(pass: txtPass, salt: getSalt(login: txtLogin)))!)
        request.httpMethod = "GET"
        
        #if DEBUG
            print(request.url!)
        #endif
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    self.stopIndicator()
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
            
            self.choice()
            
            }.resume()
    }
    
    private func getHash(pass: String, salt: String) -> String {
        
        let btl = pass.data(using: .utf16LittleEndian)
        let bSalt = salt.data(using: .utf16LittleEndian)
        var bAll = btl! + bSalt!
        bAll.append(bSalt!)
        bAll.append(btl!)
        
        return bAll.base64EncodedString().sha1().replacingOccurrences(of: "\n", with: "")
    }
    
    private func getSalt(login: String) -> String {
        
        var salt = ""
        let queue = DispatchGroup()
        
        var soleRequest = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        soleRequest.httpMethod = "GET"
        
        queue.enter()
        URLSession.shared.dataTask(with: soleRequest) {
            data, response, error in
        
            defer {
                queue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    self.stopIndicator()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = String(data: data!, encoding: .utf8) ?? ""
            }.resume()
        
        queue.wait()
        return salt
    }
    
    private func choice() {
        
        DispatchQueue.main.async {
            
            if self.responseString == "1" {
                
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "2" || self.responseString.contains("error") {
                
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Неверный логин или пароль", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else {
                
                // авторизация на сервере - получение данных пользователя
                var answer = self.responseString.components(separatedBy: ";")
                
                // сохраним значения в defaults
                self.saveGlobalData(date1: answer[0], date2: answer[1], can_count: answer[2], mail: answer[3], id_account: answer[4], isCons: answer[5], name: answer[6], history_counters: answer[7], strah: "0")
                
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
                    
                    self.performSegue(withIdentifier: "AppsCons", sender: self)
                    
                } else {                         // пользователь
                    
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
                    
                    self.performSegue(withIdentifier: "AppsUsers", sender: self)
                    
                }
                self.stopIndicator()
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
            
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Optional("goForget") {
            
            let regVC = segue.destination as! Registration_Sminex
            regVC.isReg_ = false
        
        } else if segue.identifier == Optional("goRegister") {
            
            let regVC = segue.destination as! Registration_Sminex
            regVC.isReg_ = true
        }
        
    }
    
    private func startIndicator() {
        self.btnEnter.isHidden      = true
        self.btnForgot.isHidden     = true
        self.btnReg.isHidden        = true
        self.lineForgot.isHidden    = true
        self.lineReg.isHidden       = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden     = false
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
        defaults.setValue(edLogin.text!, forKey: "login")
        defaults.setValue(edPass.text!, forKey: "pass")
        defaults.synchronize()
    }
    
    private func loadUsersDefaults() {
        let defaults    = UserDefaults.standard
        let login       = defaults.string(forKey: "login")
        let pass        = defaults.string(forKey: "pass")
        
        edLogin.text    = login
        edPass.text     = pass
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        
        if string == "" {

            let ls_ind  = ls.index(ls.endIndex, offsetBy: -1)
            let ls_end  = ls.substring(to: ls_ind)
            ls          = ls_end

            if ls_end == "" {
                itsPhone = false
            }
        } else {
            ls = ls + string
        }
//
//        // Определим телефон это или нет
//        var first       = true
//        var ls_1_end    = ""
//
//        if ls.count < 1 {
//            ls_1_end = ""
//
//        } else {
//            let ls_1 = ls.index(ls.startIndex, offsetBy: 1)
//            ls_1_end = ls.substring(to: ls_1)
//        }
//
//        var ls_12_end = ""
//        if ls.count < 2 {
//            ls_12_end = ""
//        } else {
//            let ls_12 = ls.index(ls.startIndex, offsetBy: 2)
//            ls_12_end = ls.substring(to: ls_12)
//        }
//        if ls_1_end == "+" {
//            itsPhone = true
//        }
//        if !itsPhone {
//            if ls_12_end == "89" || ls_12_end == "79" {
//                itsPhone = true
//            }
//        }
//
//        var new_ls: String = ""
//        first = true
//        var j: Int = 1
//
//        ls.forEach {
//
//            if first {
//                new_ls = String($0)
//                first = false
//
//            } else {
//                if itsPhone {
//                    if ls_1_end == "+" {
//                        if j == 2 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 3 {
//                            new_ls = new_ls + "(" + String($0)
//                        } else if j == 4 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 5 {
//                            new_ls = new_ls + String($0) + ")"
//                        } else if j == 6 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 7 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 8 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 9 {
//                            new_ls = new_ls + "-" + String($0)
//                        } else if j == 10 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 11 {
//                            new_ls = new_ls + "_" + String($0)
//                        } else if j == 12 {
//                            new_ls = new_ls + String($0)
//                        } else {
//                            new_ls = new_ls + String($0)
//                        }
//                    } else {
//                        if j == 2 {
//                            new_ls = new_ls + "(" + String($0)
//                        } else if j == 3 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 4 {
//                            new_ls = new_ls + String($0) + ")"
//                        } else if j == 5 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 6 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 7 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 8 {
//                            new_ls = new_ls + "-" + String($0)
//                        } else if j == 9 {
//                            new_ls = new_ls + String($0)
//                        } else if j == 10 {
//                            new_ls = new_ls + "-" + String($0)
//                        } else if j == 11 {
//                            new_ls = new_ls + String($0)
//                        } else {
//                            new_ls = new_ls + String($0)
//                        }
//                    }
//                } else {
//                    new_ls = new_ls + String($0)
//                }
//            }
//            j = j + 1
//        }
//
//        if itsPhone {
//            if ls_1_end == "+" {
//                if j == 2 {
//                    new_ls = new_ls + "*(***)***-**-**"
//                } else if j == 3 {
//                    new_ls = new_ls + "(***)***-**-**"
//                } else if j == 4 {
//                    new_ls = new_ls + "**)***-**-**"
//                } else if j == 5 {
//                    new_ls = new_ls + "*)***-**-**"
//                } else if j == 6 {
//                    new_ls = new_ls + "***-**-**"
//                } else if j == 7 {
//                    new_ls = new_ls + "**-**-**"
//                } else if j == 8 {
//                    new_ls = new_ls + "*-**-**"
//                } else if j == 9 {
//                    new_ls = new_ls + "-**-**"
//                } else if j == 10 {
//                    new_ls = new_ls + "*-**"
//                } else if j == 11 {
//                    new_ls = new_ls + "-**"
//                } else if j == 12 {
//                    new_ls = new_ls + "*"
//                }
//            } else {
//                if j == 3 {
//                    new_ls = new_ls + "**)***-**-**"
//                } else if j == 4 {
//                    new_ls = new_ls + "*)***-**-**"
//                } else if j == 5 {
//                    new_ls = new_ls + "***-**-**"
//                } else if j == 6 {
//                    new_ls = new_ls + "**-**-**"
//                } else if j == 7 {
//                    new_ls = new_ls + "*-**-**"
//                } else if j == 8 {
//                    new_ls = new_ls + "-**-**"
//                } else if j == 9 {
//                    new_ls = new_ls + "*-**"
//                } else if j == 10 {
//                    new_ls = new_ls + "-**"
//                } else if j == 11 {
//                    new_ls = new_ls + "*"
//                }
//            }
//        }
//
//        textField.text = new_ls
//
//        // Установим курсор, если это телефон
//        if itsPhone {
//            var jj = j
//            if ls_1_end == "+" {
//                if j == 2 {
//                    jj = 1
//                }
//                if j > 5 {
//                    jj = j + 1
//                }
//                if j > 8 {
//                    jj = j + 2
//                }
//                if j > 10 {
//                    jj = j + 3
//                }
//            } else {
//                if j > 4 {
//                    jj = j + 1
//                }
//                if j > 7 {
//                    jj = j + 2
//                }
//                if j > 9 {
//                    jj = j + 3
//                }
//            }
//            if let newPosition = textField.position(from: textField.beginningOfDocument, offset: jj) {
//                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
//            }
//        }
//
//        // Установим тип - для номера телефона - только цифры
//        if itsPhone {
//            textField.keyboardType = UIKeyboardType.phonePad
//        } else {
//            textField.keyboardType = UIKeyboardType.default
//        }
//        textField.reloadInputViews()
        
        return true
        
    }
}

