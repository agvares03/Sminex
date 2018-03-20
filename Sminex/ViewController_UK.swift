//
//  ViewController_UK.swift
//  DemoUC
//
//  Created by Роман Тузин on 14.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import FirebaseMessaging

class ViewController_UK: UIViewController {
    
    // Картинки для разных версий
    @IBOutlet private weak var fon_top:     UIImageView!
    @IBOutlet private weak var new_face:    UIImageView!
    @IBOutlet private weak var new_zamoc:   UIImageView!
    
    @IBOutlet private weak var nameUK: UILabel!
    
    @IBOutlet private weak var edLogin: UITextField!
    @IBOutlet private weak var edPass:  UITextField!
    @IBOutlet private weak var scroll:  UIScrollView!
    
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var btnEnter:  UIButton!
    @IBOutlet private weak var btnForgot: UIButton!
    @IBOutlet private weak var btnUK:     UIButton!
    @IBOutlet private weak var btnReg:    UIView!
    
    // какая регистрация будет
    open var roleReg_                = ""
    private var responseString = ""
    
    @IBAction private func choice_uk(_ sender: UIButton) {
        
        // Для Оплата ЖКУ - форма выбора с улицей
        performSegue(withIdentifier: "choice_uk", sender: self)
    }
    
    @IBAction private func btnRegGo(_ sender: UIButton) {
        
        if roleReg_ == "1" {
            performSegue(withIdentifier: "registration_uk", sender: self)
            
        } else if roleReg_ == "4" {
            performSegue(withIdentifier: "registration_uk4", sender: self)
            
        } else {
            performSegue(withIdentifier: "registration", sender: self)
        }
    }
    
    @IBAction private func btnEnter(_ sender: UIButton) {
        
        // Проверка на заполнение
        var ret             = false
        var message: String = ""
        
        if edLogin.text == "" {
            message = "Не указан логин. "
            ret     = true;
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopIndicator()
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        scroll.addGestureRecognizer(theTap)
        loadUsersDefaults()
        
        // Растянем программно
        nameUK.numberOfLines = 0
        nameUK.sizeToFit()
        var myFrame: CGRect = nameUK.frame;
        myFrame = CGRect(x: myFrame.origin.x, y: myFrame.origin.y, width: 280, height: myFrame.size.height)
        nameUK.frame = myFrame
        
        if nameUK.text == "" {
            performSegue(withIdentifier: "choice_uk", sender: self)
        }
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        scroll.endEditing(true)
    }
    
    private func enter() {
        
        startIndicator()
        
        // Авторизация пользователя
        let txtLogin    = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass     = edPass.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + txtPass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
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
    
    private func choice() {
        
        DispatchQueue.main.async {
            
            if self.responseString == "1" {
                
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "2" || self.responseString.contains(find: "error") {
                
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
                    db.parse_Apps(login: self.edLogin.text!, pass: self.edPass.text!, isCons: "1")
                    
                    // Дома, квартиры, лицевые счета
                    //                    db.del_db(table_name: "Houses")
                    //                    db.del_db(table_name: "Flats")
                    //                    db.del_db(table_name: "Ls")
                    //                    db.parse_Houses()
                    
                    self.performSegue(withIdentifier: "AppsCons_uk", sender: self)
                    
                } else {                         // пользователь
                    
                    // ПОКАЗАНИЯ СЧЕТЧИКОВ
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Counters")
                    // Получим данные в базу данных
                    db.parse_Countrers(login: self.edLogin.text!, pass: self.edPass.text!, history: answer[7])
                    
                    // ВЕДОМОСТЬ (Пока данные тестовые)
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Saldo")
                    // Получим данные в базу данных
                    db.parse_OSV(login: self.edLogin.text!, pass: self.edPass.text!)
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Applications")
                    db.del_db(table_name: "Comments")
                    db.parse_Apps(login: self.edLogin.text!, pass: self.edPass.text!, isCons: "0")
                    
                    self.performSegue(withIdentifier: "AppsUsers_uk", sender: self)
                    
                }
                self.stopIndicator()
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
        
        var request = URLRequest(url: URL(string: urlPath)!)
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
    
    private func startIndicator() {
        self.btnEnter.isHidden  = true
        self.btnForgot.isHidden = true
        self.btnReg.isHidden    = true
        self.btnUK.isHidden     = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator(){
        self.btnEnter.isHidden  = false
        self.btnForgot.isHidden = false
        self.btnReg.isHidden    = false
        self.btnUK.isHidden     = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    private func saveUsersDefaults() {
        let defaults = UserDefaults.standard
        defaults.setValue(edLogin.text!, forKey: "login")
        defaults.setValue(edPass.text!, forKey: "pass")
        defaults.setValue(nameUK.text, forKey: "name_uk")
        defaults.synchronize()
    }
    
    private func loadUsersDefaults() {
        let defaults = UserDefaults.standard
        let login = defaults.string(forKey: "login")
        let pass = defaults.string(forKey: "pass")
        let uk = defaults.string(forKey: "name_uk")
        
        edLogin.text    = login
        edPass.text     = pass
        nameUK.text     = uk
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Optional("goForget") {
            let forgotVC: ForgotPass = segue.destination as! ForgotPass
            forgotVC.letter = edLogin.text ?? ""
            
        } else if segue.identifier == Optional("goRegistration") {
            let regVC: Registration = segue.destination as! Registration
            regVC.letter = edLogin.text ?? ""
            
        } else if segue.identifier == Optional("goForget_uk") {
            let forgotVC: ForgotPass = segue.destination as! ForgotPass
            forgotVC.letter = edLogin.text ?? ""
            
        } else if segue.identifier == Optional("goRegistration_uk") {
            let regVC: Registration = segue.destination as! Registration
            regVC.letter = edLogin.text ?? ""
            
        } else if segue.identifier == Optional("goRegistration2") {
            let regVC: Registration = segue.destination as! Registration
            regVC.letter = edLogin.text ?? ""
            
        } else if segue.identifier == Optional("goRegistration3") {
            let regVC: RegistrationAdress = segue.destination as! RegistrationAdress
            regVC.letter = edLogin.text ?? ""
            
        } else if segue.identifier == Optional("choice_uk_street") {
            let choiseUKStreetVC = segue.destination as! Choice_UK_Street
            choiseUKStreetVC.roleReg_ = roleReg_
            
        } else if segue.identifier == Optional("choice_uk") {
            let choiseUKVC = segue.destination as! Choice_UK
            choiseUKVC.roleReg_ = roleReg_
        }
    }
}
