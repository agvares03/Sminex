//
//  FirstController.swift
//  DemoUC
//
//  Created by Роман Тузин on 14.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import FirebaseMessaging

class FirstController: UIViewController {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var window: UIWindow?
    var responseString:NSString = ""
    
    var role_reg = "2"
    var name_uk: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // запустим индикатор
        self.indicator.startAnimating()
        
        let defaults = UserDefaults.standard
        let name_uk_let = defaults.string(forKey: "name_uk")
        if (name_uk_let != nil) {
            name_uk = String(describing: name_uk_let)
        }

        // Если необходимо - покажем окно выбора управляющей компании
        #if isGKRZS
            var site: String? = ""
            do {
                site = try UserDefaults.standard.string(forKey: "SiteSM")
            } catch {
                let defaults = UserDefaults.standard
                defaults.setValue("", forKey: "SiteSM")
                defaults.synchronize()
            }
            if (site == nil) {
                let defaults = UserDefaults.standard
                defaults.setValue("", forKey: "SiteSM")
                defaults.synchronize()
            }
        #endif
        startActivity()
    }
    
    func startActivity() {
        
        let urlPath = Server.SERVER + Server.CHECK_REGISTRATION
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    DispatchQueue.main.async(execute: {
                                                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                                                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                                                        
                                                            exit(0)
                                                        
                                                        }
                                                        alert.addAction(cancelAction)
                                                        self.present(alert, animated: true, completion: nil)
                                                    })
                                                    return
                                                }
                                                
                                                self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                                                print("responseString = \(self.responseString)")
                                                
                                                self.choice()
        })
        task.resume()
    }
    
    func choice() {
        if (responseString != "xxx") {
            DispatchQueue.main.async(execute: {
                var answer = self.responseString.components(separatedBy: ";")
                let getUK = answer[0]
                self.role_reg = answer[1]
                
                if (getUK == "1") {
                    
                    if (self.name_uk == "") {
                        let vc  = self.storyboard?.instantiateViewController(withIdentifier: "choice_uk") as!  Choice_UK
                        vc.role_reg = self.role_reg
                        self.present(vc, animated: true, completion: nil)
                    } else {
                        let vc  = self.storyboard?.instantiateViewController(withIdentifier: "login_activity_uk") as!  ViewController_UK
                        vc.role_reg = self.role_reg
                        self.present(vc, animated: true, completion: nil)
                    }
                    
                } else {
                    
                    // Если в памяти есть логин и пароль, сразу зайдем в приложение
                    self.go_to_apps();
                    
                }
                
            })
        } else {
            
        }
    }
    
    func go_to_apps() {
        
        let defaults = UserDefaults.standard
        let login = defaults.string(forKey: "login")
        let pass = defaults.string(forKey: "pass")
        
        if (login != nil) && (login != "") {
            if (pass != nil) && (login != "") {
                enter(login: login!, pass: pass!)
            } else {
                let vc  = self.storyboard?.instantiateViewController(withIdentifier: "login_activity") as!  ViewController
                vc.role_reg = self.role_reg
                self.present(vc, animated: true, completion: nil)
            }
        } else {
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "login_activity") as!  ViewController
            vc.role_reg = self.role_reg
            self.present(vc, animated: true, completion: nil)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if (segue.identifier == "login_UK") {
            let Login = segue.destination as! ViewController_UK
            Login.role_reg = self.role_reg
        } else if (segue.identifier == "login") {
            let Login = segue.destination as! ViewController
            Login.role_reg = self.role_reg
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // ВХОД В ПРИЛОЖЕНИЕ - ДУБЛЬ ФУНКЦИЙ ИЗ ViewController
    // зайдем в приложение прям отсюда
    func enter(login: String, pass: String) {
        // Авторизация пользователя
        let txtLogin = login.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtPass = pass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        let urlPath = Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + txtPass;
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    DispatchQueue.main.async(execute: {
                                                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                                                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                                                        alert.addAction(cancelAction)
                                                        self.present(alert, animated: true, completion: nil)
                                                    })
                                                    return
                                                }
                                                
                                                self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                                                print("responseString = \(self.responseString)")
                                                
                                                self.go_to_App(login: login, pass: pass)
        })
        task.resume()
    }
    
    func go_to_App(login: String, pass: String) {
        if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                let vc  = self.storyboard?.instantiateViewController(withIdentifier: "login_activity") as!  ViewController
                vc.role_reg = self.role_reg
                self.present(vc, animated: true, completion: nil)
            })
        } else if (responseString == "2") {
            DispatchQueue.main.async(execute: {
                let vc  = self.storyboard?.instantiateViewController(withIdentifier: "login_activity") as!  ViewController
                vc.role_reg = self.role_reg
                self.present(vc, animated: true, completion: nil)
            })
        } else {
            DispatchQueue.main.async(execute: {
                
                // авторизация на сервере - получение данных пользователя
                var answer = self.responseString.components(separatedBy: ";")
                
                // сохраним значения в defaults
                self.save_global_data(date1: answer[0], date2: answer[1], can_count: answer[2], mail: answer[3], id_account: answer[4], isCons: answer[5], name: answer[6], history_counters: answer[7], strah: "0")
                
                // отправим на сервер данные об ид. устройства для отправки уведомлений
                let token = Messaging.messaging().fcmToken
                if (token != nil) {
                    self.send_id_app(id_account: answer[4], token: token!)
                }
                
                // Экземпляр класса DB
                let db = DB()
                
                // Если пользователь - окно пользователя, если консультант - другое окно
                if (answer[5] == "1") {          // консультант
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Comments")
                    db.del_db(table_name: "Applications")
                    db.parse_Apps(login: login, pass: pass, isCons: "1")
                    
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
                    
                    self.performSegue(withIdentifier: "AppsUserNow", sender: self)
                    
                }

            })
        }
    }
    
    // сохранениеи глобальных значений
    func save_global_data(date1: String, date2: String, can_count: String, mail: String, id_account: String, isCons: String, name: String, history_counters: String, strah: String) {
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
    func send_id_app(id_account: String, token: String) {
        let urlPath = Server.SERVER + Server.SEND_ID_GOOGLE +
            "cid=" + id_account +
            "&did=" + token +
            "&os=" + "iOS" +
            "&version=" + UIDevice.current.systemVersion +
            "&model=" + UIDevice.current.model
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                                                print("token (add) = \(String(describing: self.responseString))")
                                                
        })
        task.resume()
    }
    
}
