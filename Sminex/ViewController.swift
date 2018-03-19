//
//  ViewController.swift
//  DemoUC
//
//  Created by Роман Тузин on 16.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import FirebaseMessaging

class ViewController: UIViewController, UITextFieldDelegate {
    
    // Картинка вверху
    @IBOutlet weak var fon_top: UIImageView!
    @IBOutlet weak var new_face: UIImageView!
    @IBOutlet weak var new_zamoc: UIImageView!
    
    // какая регистрация будет
    var role_reg: String = ""
    
    let textForgot: String = ""
    var responseString:NSString = ""
    
    // долги - ДомЖилСервис
    var debt_date:String = "0"
    var debt_sum = 0.0
    var debt_over_sum = 0.0
    var debt_sum_all = 0.0

    @IBOutlet weak var edLogin: UITextField!
    @IBOutlet weak var edPass: UITextField!
    @IBOutlet weak var scroll: UIScrollView!
    @IBOutlet weak var btnReg: UIButton!
    @IBOutlet weak var btnEnter: UIButton!
    @IBOutlet weak var btnForgot: UIButton!

    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var lineForgot: UILabel!
    @IBOutlet weak var lineReg: UILabel!
    
    var ls:String = ""
    // признак того, вводим мы телефон или нет
    var itsPhone: Bool = false
    
    @IBAction func enter(_ sender: UIButton) {
        // Проверка на заполнение
        var ret: Bool = false;
        var message: String = ""
        if (edLogin.text == "") {
            message = "Не указан логин. "
            ret = true;
        }
        if (edPass.text == "") {
            message = message + "Не указан пароль."
            ret = true
        }
        if ret {
            let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Сохраним значения
        saveUsersDefaults()
        
        // Запрос - получение данных !!!
        enter()
    }
    
    // Анимация перехода
    var transitionManager = TransitionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edLogin.delegate = self
        
        StopIndicator()
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        scroll.addGestureRecognizer(theTap)
        loadUsersDefaults()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            fon_top.image               = UIImage(named: "fon_top_gkrzs")
            new_face.image              = UIImage(named: "new_face_gkrzs")
            new_zamoc.image             = UIImage(named: "new_zamok_gkrzs")
            btnEnter.backgroundColor    = server.hexStringToUIColor(hex: "#1f287f")
            btnReg.tintColor            = server.hexStringToUIColor(hex: "#c0c0c0")
            btnForgot.tintColor         = server.hexStringToUIColor(hex: "#c0c0c0")
        #else
            // Оставим текущуий интерфейс
        #endif
        
        // Анимация перехода
        transitionManager = TransitionManager()
        
    }
    
    func ViewTapped(recognizer: UIGestureRecognizer) {
        scroll.endEditing(true)
    }
    
    func enter() {
        
        StartIndicator()
        
        // Авторизация пользователя
        let txtLogin: String = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtPass: String = edPass.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        let urlPath = Server.SERVER + Server.ENTER + "login=" + txtLogin + "&pwd=" + txtPass;
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    DispatchQueue.main.async(execute: {
                                                        self.StopIndicator()
                                                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                                                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
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
        if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "2") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Неверный логин или пароль", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else {
            DispatchQueue.main.async(execute: {

                // авторизация на сервере - получение данных пользователя
                var answer = self.responseString.components(separatedBy: ";")
                
                // сохраним значения в defaults
                #if isDJ
                    self.save_global_data(date1: answer[0], date2: answer[1], can_count: answer[2], mail: answer[3], id_account: answer[4], isCons: answer[5], name: answer[6], history_counters: answer[7], strah: answer[8])
                #else
                    self.save_global_data(date1: answer[0], date2: answer[1], can_count: answer[2], mail: answer[3], id_account: answer[4], isCons: answer[5], name: answer[6], history_counters: answer[7], strah: "0")
                #endif
                
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
                    db.parse_Apps(login: self.edLogin.text!, pass: self.edPass.text!, isCons: "1")
                    
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
                    db.parse_Countrers(login: self.edLogin.text!, pass: self.edPass.text!, history: answer[7])
                    
                    // ВЕДОМОСТЬ (Пока данные тестовые)
                    // Удалим данные из базы данных
                    db.del_db(table_name: "Saldo")
                    // Получим данные в базу данных
                    db.parse_OSV(login: self.edLogin.text!, pass: self.edPass.text!)
                    
                    // Если это ДомЖилСервис - получим информацию о долгах отдельно
                    #if isDJ
                        self.get_debt(login: self.edLogin.text!)
                    #endif
                    
                    // ЗАЯВКИ С КОММЕНТАРИЯМИ
                    db.del_db(table_name: "Applications")
                    db.del_db(table_name: "Comments")
                    db.parse_Apps(login: self.edLogin.text!, pass: self.edPass.text!, isCons: "0")
                    
                    self.performSegue(withIdentifier: "AppsUsers", sender: self)
                    
                }
                
                self.StopIndicator()
            })
        }
        
    }
    
    // Получим данные о долгах (ДомЖилСервис)
    func get_debt(login: String) {
        let urlPath = Server.SERVER + Server.GET_DEBT + "ident=" + login
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                // распарсим полученный json с долгами, загоним его в память
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    if let j_object = json["data"] {
                                                        if let j_date = j_object["Date"] {
                                                            self.debt_date = j_date as! String
                                                        }
                                                        if let j_sum = j_object["Sum"] {
                                                            self.debt_sum = Double(j_sum as! NSNumber)
                                                        }
                                                        if let j_over_sum = j_object["SumOverhaul"] {
                                                            self.debt_over_sum = Double(j_over_sum as! NSNumber)
                                                        }
                                                        if let j_sum_all = j_object["SumAll"] {
                                                            self.debt_sum_all = Double(j_sum_all as! NSNumber)
                                                        }
                                                    }
                                                    
                                                    self.put_to_brain_debt()
                                                    
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
        })
        task.resume()
    }
    
    func put_to_brain_debt() {
        let defaults = UserDefaults.standard
        defaults.setValue(debt_date, forKey: "debt_date")
        defaults.setValue(debt_sum, forKey: "debt_sum")
        defaults.setValue(debt_over_sum, forKey: "debt_over_sum")
        defaults.setValue(debt_sum_all, forKey: "debt_sum_all")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if (segue.identifier == Optional("goForget")) {
//            let ForgotVC: ForgotPass = segue.destination as! ForgotPass
//            ForgotVC.letter = edLogin.text!
//        } else if (segue.identifier == Optional("goRegistration")) {
//            let RegVC: Registration = segue.destination as! Registration
//            RegVC.letter = edLogin.text!
//        } else if (segue.identifier == Optional("goForget_uk")) {
//            let ForgotVC: ForgotPass = segue.destination as! ForgotPass
//            ForgotVC.letter = edLogin.text!
//        } else if (segue.identifier == Optional("goRegistration_uk")) {
//            let RegVC: Registration = segue.destination as! Registration
//            RegVC.letter = edLogin.text!
//        } else if (segue.identifier == Optional("goRegistration2")) {
//            let RegVC: Registration = segue.destination as! Registration
//            RegVC.letter = edLogin.text!
//        }
//        else if (segue.identifier == Optional("goRegistration3")) {
//            let RegVC: Registration = segue.destination as! Registration
//            RegVC.letter = edLogin.text!
//        }
        
        let toViewController = segue.destination as UIViewController
        toViewController.transitioningDelegate = self.transitionManager
        
    }
    
    func StartIndicator(){
        self.btnEnter.isHidden = true
        self.btnForgot.isHidden = true
        self.btnReg.isHidden = true
        self.lineForgot.isHidden = true
        self.lineReg.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator(){
        self.btnEnter.isHidden = false
        self.btnForgot.isHidden = false
        self.btnReg.isHidden = false
        self.lineForgot.isHidden = false
        self.lineReg.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    func saveUsersDefaults() {
        let defaults = UserDefaults.standard
        defaults.setValue(edLogin.text!, forKey: "login")
        defaults.setValue(edPass.text!, forKey: "pass")
        defaults.synchronize()
    }
    
    func loadUsersDefaults() {
        let defaults = UserDefaults.standard
        let login = defaults.string(forKey: "login")
        let pass = defaults.string(forKey: "pass")
        
        edLogin.text = login
        edPass.text = pass
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        
        if (string == "") {
            let ls_ind = ls.index(ls.endIndex, offsetBy: -1)
            let ls_end = ls.substring(to: ls_ind)
            ls = ls_end
            if (ls_end == "") {
                itsPhone = false
            }
        } else {
            ls = ls + string
        }
        
        // определим телефон это или нет
        var first: Bool = true
        var ls_1_end = ""
        if (ls.characters.count < 1) {
            ls_1_end = ""
        } else {
            let ls_1 = ls.index(ls.startIndex, offsetBy: 1)
            ls_1_end = ls.substring(to: ls_1)
        }
        
        var ls_12_end = ""
        if (ls.characters.count < 2) {
            ls_12_end = ""
        } else {
            let ls_12 = ls.index(ls.startIndex, offsetBy: 2)
            ls_12_end = ls.substring(to: ls_12)
        }
        if (ls_1_end == "+") {
            itsPhone = true
        }
        if (!itsPhone) {
            if (ls_12_end == "89") || (ls_12_end == "79") {
                itsPhone = true
            }
        }
        
        var new_ls: String = ""
        first = true
        var j: Int = 1
        for character in ls {
            if (first) {
                new_ls = String(character)
                first = false
            } else {
                if (itsPhone) {
                    if (ls_1_end == "+") {
                        if (j == 2) {
                            new_ls = new_ls + String(character)
                        } else if (j == 3) {
                            new_ls = new_ls + "(" + String(character)
                        } else if (j == 4) {
                            new_ls = new_ls + String(character)
                        } else if (j == 5) {
                            new_ls = new_ls + String(character) + ")"
                        } else if (j == 6) {
                            new_ls = new_ls + String(character)
                        } else if (j == 7) {
                            new_ls = new_ls + String(character)
                        } else if (j == 8) {
                            new_ls = new_ls + String(character)
                        } else if (j == 9) {
                            new_ls = new_ls + "-" + String(character)
                        } else if (j == 10) {
                            new_ls = new_ls + String(character)
                        } else if (j == 11) {
                            new_ls = new_ls + "_" + String(character)
                        } else if (j == 12) {
                            new_ls = new_ls + String(character)
                        } else {
                            new_ls = new_ls + String(character)
                        }
                    } else {
                        if (j == 2) {
                            new_ls = new_ls + "(" + String(character)
                        } else if (j == 3) {
                            new_ls = new_ls + String(character)
                        } else if (j == 4) {
                            new_ls = new_ls + String(character) + ")"
                        } else if (j == 5) {
                            new_ls = new_ls + String(character)
                        } else if (j == 6) {
                            new_ls = new_ls + String(character)
                        } else if (j == 7) {
                            new_ls = new_ls + String(character)
                        } else if (j == 8) {
                            new_ls = new_ls + "-" + String(character)
                        } else if (j == 9) {
                            new_ls = new_ls + String(character)
                        } else if (j == 10) {
                            new_ls = new_ls + "-" + String(character)
                        } else if (j == 11) {
                            new_ls = new_ls + String(character)
                        } else {
                            new_ls = new_ls + String(character)
                        }
                    }
                } else {
                    new_ls = new_ls + String(character)
                }
            }
            j = j + 1
        }
        
        if (itsPhone) {
            if (ls_1_end == "+") {
                if (j == 2) {
                    new_ls = new_ls + "*(***)***-**-**"
                } else if (j == 3) {
                    new_ls = new_ls + "(***)***-**-**"
                } else if (j == 4) {
                    new_ls = new_ls + "**)***-**-**"
                } else if (j == 5) {
                    new_ls = new_ls + "*)***-**-**"
                } else if (j == 6) {
                    new_ls = new_ls + "***-**-**"
                } else if (j == 7) {
                    new_ls = new_ls + "**-**-**"
                } else if (j == 8) {
                    new_ls = new_ls + "*-**-**"
                } else if (j == 9) {
                    new_ls = new_ls + "-**-**"
                } else if (j == 10) {
                    new_ls = new_ls + "*-**"
                } else if (j == 11) {
                    new_ls = new_ls + "-**"
                } else if (j == 12) {
                    new_ls = new_ls + "*"
                }
            } else {
                if (j == 3) {
                    new_ls = new_ls + "**)***-**-**"
                } else if (j == 4) {
                    new_ls = new_ls + "*)***-**-**"
                } else if (j == 5) {
                    new_ls = new_ls + "***-**-**"
                } else if (j == 6) {
                    new_ls = new_ls + "**-**-**"
                } else if (j == 7) {
                    new_ls = new_ls + "*-**-**"
                } else if (j == 8) {
                    new_ls = new_ls + "-**-**"
                } else if (j == 9) {
                    new_ls = new_ls + "*-**"
                } else if (j == 10) {
                    new_ls = new_ls + "-**"
                } else if (j == 11) {
                    new_ls = new_ls + "*"
                }
            }
        }
        
        textField.text = new_ls
        
        // Установим курсор, если это телефон
        if (itsPhone) {
            var jj = j
            if (ls_1_end == "+") {
                if (j == 2) {
                    jj = 1
                }
                if (j > 5) {
                    jj = j + 1
                }
                if (j > 8) {
                    jj = j + 2
                }
                if (j > 10) {
                    jj = j + 3
                }
            } else {
                if (j > 4) {
                    jj = j + 1
                }
                if (j > 7) {
                    jj = j + 2
                }
                if (j > 9) {
                    jj = j + 3
                }
            }
            if let newPosition = textField.position(from: textField.beginningOfDocument, offset: jj) {
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
        }
        
        // Установим тип - для номера телефона - только цифры
        if (itsPhone) {
            textField.keyboardType = UIKeyboardType.phonePad
        } else {
            textField.keyboardType = UIKeyboardType.default
        }
        textField.reloadInputViews()
        
        return false
        
    }

}

