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
    @IBOutlet weak var fon_top: UIImageView!
    @IBOutlet weak var new_face: UIImageView!
    @IBOutlet weak var new_zamoc: UIImageView!
    
    // какая регистрация будет
    var role_reg: String = ""
    var responseString:NSString = ""

    @IBOutlet weak var nameUK: UILabel!
    
    @IBOutlet weak var edLogin: UITextField!
    @IBOutlet weak var edPass: UITextField!
    @IBOutlet weak var scroll: UIScrollView!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var btnEnter: UIButton!
    @IBOutlet weak var btnForgot: UIButton!
    @IBOutlet weak var btnReg: UIView!
    @IBOutlet weak var btnUK: UIButton!
    
    @IBAction func choice_uk(_ sender: UIButton) {
        // Для Оплата ЖКУ - форма выбора с улицей
        #if isGKRZS
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "choice_uk_street") as!  Choice_UK_Street
            vc.role_reg = self.role_reg
            self.present(vc, animated: true, completion: nil)
        #else
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "choice_uk") as!  Choice_UK
            vc.role_reg = self.role_reg
            self.present(vc, animated: true, completion: nil)
        #endif
    }
    
    @IBAction func btnRegGo(_ sender: UIButton) {
        if (role_reg == "1") {
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "registration_uk") as!  RegistrationAdress
            vc.letter = edLogin.text!
            self.present(vc, animated: true, completion: nil)
        } else if (role_reg == "4") {
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "registration_uk4") as!  RegistrationAdress4
            vc.letter = edLogin.text!
            self.present(vc, animated: true, completion: nil)
        } else {
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "registration") as!  Registration
            vc.letter = edLogin.text!
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnEnter(_ sender: UIButton) {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        StopIndicator()
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        scroll.addGestureRecognizer(theTap)
        loadUsersDefaults()
        
        // Растянем программно
        nameUK.numberOfLines = 0
        nameUK.sizeToFit()
        var myFrame: CGRect = nameUK.frame;
        myFrame = CGRect(x: myFrame.origin.x, y: myFrame.origin.y, width: 280, height: myFrame.size.height)
        nameUK.frame = myFrame
        
        if (nameUK.text == "") {
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "choice_uk") as!  Choice_UK
            vc.opener = self
            self.present(vc, animated: true, completion: nil)
        }
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            fon_top.image               = UIImage(named: "fon_top_gkrzs")
            new_face.image              = UIImage(named: "new_face_gkrzs")
            new_zamoc.image             = UIImage(named: "new_zamok_gkrzs")
            btnEnter.backgroundColor    = server.hexStringToUIColor(hex: "#1f287f")
            btnReg.tintColor            = server.hexStringToUIColor(hex: "#c0c0c0")
            btnForgot.tintColor         = server.hexStringToUIColor(hex: "#c0c0c0")
            btnUK.tintColor             = server.hexStringToUIColor(hex: "#c0c0c0")
        #else
            // Оставим текущуий интерфейс
        #endif
        
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
                
                self.StopIndicator()
            })
        }
        
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
    
    func StartIndicator(){
        self.btnEnter.isHidden = true
        self.btnForgot.isHidden = true
        self.btnReg.isHidden = true
        self.btnUK.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator(){
        self.btnEnter.isHidden = false
        self.btnForgot.isHidden = false
        self.btnReg.isHidden = false
        self.btnUK.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    func saveUsersDefaults() {
        let defaults = UserDefaults.standard
        defaults.setValue(edLogin.text!, forKey: "login")
        defaults.setValue(edPass.text!, forKey: "pass")
        defaults.setValue(nameUK.text, forKey: "name_uk")
        defaults.synchronize()
    }
    
    func loadUsersDefaults() {
        let defaults = UserDefaults.standard
        let login = defaults.string(forKey: "login")
        let pass = defaults.string(forKey: "pass")
        let uk = defaults.string(forKey: "name_uk")
        
        edLogin.text = login
        edPass.text = pass
        nameUK.text = uk
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == Optional("goForget")) {
            let ForgotVC: ForgotPass = segue.destination as! ForgotPass
            ForgotVC.letter = edLogin.text!
        } else if (segue.identifier == Optional("goRegistration")) {
            let RegVC: Registration = segue.destination as! Registration
            RegVC.letter = edLogin.text!
        } else if (segue.identifier == Optional("goForget_uk")) {
            let ForgotVC: ForgotPass = segue.destination as! ForgotPass
            ForgotVC.letter = edLogin.text!
        } else if (segue.identifier == Optional("goRegistration_uk")) {
            let RegVC: Registration = segue.destination as! Registration
            RegVC.letter = edLogin.text!
        } else if (segue.identifier == Optional("goRegistration2")) {
            let RegVC: Registration = segue.destination as! Registration
            RegVC.letter = edLogin.text!
        }
        else if (segue.identifier == Optional("goRegistration3")) {
            let RegVC: RegistrationAdress = segue.destination as! RegistrationAdress
            RegVC.letter = edLogin.text!
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

}
