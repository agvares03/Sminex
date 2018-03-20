//
//  RegistrationAdress.swift
//  DemoUC
//
//  Created by Роман Тузин on 15.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class RegistrationAdress: UIViewController {
    // Картинки на подмену
    @IBOutlet weak var fon_top: UIImageView!
    @IBOutlet weak var home: UIImageView!
    @IBOutlet weak var flat: UIImageView!
    @IBOutlet weak var number_ls: UIImageView!
    @IBOutlet weak var new_phone: UIImageView!
    @IBOutlet weak var new_mail: UIImageView!
    
    var responseString:NSString = ""
    var letter:String = ""
    
    // Массивы для хранения данных
    var adress_names: [String] = []
    var adress_ids: [String] = []
    var teck_adress = -1
    
    var flats_names: [String] = []
    var flats_ids: [String] = []
    var teck_flat = -1

    @IBOutlet weak var edAdress: UITextField!
    @IBOutlet weak var edFlat: UITextField!
    @IBOutlet weak var edLogin: UITextField!
    @IBOutlet weak var edPhone: UITextField!
    @IBOutlet weak var edMail: UITextField!
    
    @IBOutlet weak var btnAdress: UIButton!
    @IBOutlet weak var indicatorAdress: UIActivityIndicatorView!
    @IBOutlet weak var btnFlat: UIButton!
    @IBOutlet weak var indicatorFlat: UIActivityIndicatorView!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnReg: UIButton!
    
    @IBAction func goCancel(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func goReg(_ sender: UIButton) {
        // Регистрация
        startIndicatorChoice(num_ind: "1")
        StartIndicator()
        
        var houseID: String = ""
        if (teck_adress != -1) {
            houseID = adress_ids[teck_adress].addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        }
        let premiseNumber = edFlat.text!.replacingOccurrences(of: " кв.", with: "", options: .literal, range: nil)
        let login = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let phone = edPhone.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let mail = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        let urlPath = Server.SERVER + Server.REGISTRATION + "houseID=" + houseID +
                                                            "&premiseNumber=" + premiseNumber +
                                                            "&login=" + login +
                                                            "&phone=" + phone +
                                                            "&email=" + mail
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                let answerString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                print("answer (reg) = \(String(describing: answerString))")
                                                
                                                self.answer_reg(answer: answerString)
                                                
        })
        task.resume()
        
    }
    
    func answer_reg(answer: String) {
        // введем переменную, которая сигнализирует о необходимости отправить письмо - неверная регистрация
        var send_letter: Bool = false
        let answer_for_send: String =
                "Регистрация в iOS! " +
                "Логин: "      + edLogin.text! + " " +
                "Адрес: "      + edAdress.text! + " " +
                "Номер кв: "  + edFlat.text! + " " +
                "Телефон: "    + edPhone.text! + " " +
                "Эл почта: "  + edMail.text!
        var reason_for_send: String = ""
        
        if (answer == "1") {
            send_letter = true
            reason_for_send = "Тестовый посыл."
            // Переданы некорректные данные
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Переданы некорректные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "2") {
            send_letter = true
            reason_for_send = "Лицевой счет на найден в базе данных"
            // Лицевой счет не найден в базе данных
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в базе данных", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "3") {
            send_letter = true
            reason_for_send = "Этот лицевой счет уже зарегистрирован"
            // Этот лицевой счет уже зарегистрирован
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Этот лицевой счет уже зарегистрирован", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "5") {
            send_letter = true
            reason_for_send = "Некорректный e-mail"
            // Некорректный e-mail
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Некорректный e-mail", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "7") {
            send_letter = true
            reason_for_send = "Лицевой счет не найден в указанной квартире"
            // Лицевой счет не найден в указанной квартире
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в указанной квартире", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "0") {
            // Регистрация прошла успешно
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Успешно", message: "Пароль выслан на указанный e-mail (" + self.edMail.text! + ")", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    
                    let defaults = UserDefaults.standard
                    defaults.setValue(self.edLogin.text!, forKey: "login")
                    defaults.setValue("", forKey: "pass")
                    defaults.synchronize()
                    
                    self.presentingViewController?.dismiss(animated: false, completion: nil)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else {
            send_letter = true
            reason_for_send = "Непонятная ошибка сервера. !!!!"
            // Ошибка - попробуйте позже
            DispatchQueue.main.async(execute: {
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        }
        
        if (send_letter) {
            // Отравим письмо на почту, что регистрация не удалась
            let login = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let mail = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var text_for_send: String = answer_for_send + " Причина ошибки: " + reason_for_send
            text_for_send = text_for_send.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let txt_login: String = login == "" ? "_" : login
            let txt_mail: String = mail == "" ? "_" : mail
            let urlPath = Server.SERVER + Server.SEND_MAIL +
                "login=" + txt_login +
                "&text=" + text_for_send +
                "&mail=" + txt_mail
            print("text (send) = \(String(describing: urlPath))")
            let url: NSURL = NSURL(string: urlPath)!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest,
                                                  completionHandler: {
                                                    data, response, error in
                                                    
                                                    if error != nil {
                                                        print("text (send) = \(String(describing: urlPath))")
                                                        return
                                                    }
                                                    
                                                    let answerString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                    print("text (send) = \(String(describing: urlPath))")
                                                    print("answer (send) = \(String(describing: answerString))")
                                                    
            })
            task.resume()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        edLogin.text = letter
        
        // Действия для подбора адреса
        indicatorAdress.startAnimating()
        indicatorFlat.startAnimating()
        startIndicatorChoice(num_ind: "1")
        StartIndicator()
        
        // Первый показ - загрузим адреса домов
        let urlPath = Server.SERVER + Server.GET_HOUSES_ONLY
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
//                                                     let regionString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
//                                                     print("token (add) = \(String(describing: regionString))")
                                                    
                                                    // Получим список домов
                                                    if let regions = json["Houses"] {
                                                        for index in 0...(regions.count)!-1 {
                                                            let obj_region = regions.object(at: index) as! [String:AnyObject]
                                                            for obj in obj_region {
                                                                if obj.key == "Address" {
                                                                    self.adress_names.append(obj.value as! String)
                                                                }
                                                                if obj.key == "ID" {
                                                                    self.adress_ids.append(String(describing: obj.value))
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    self.end_choice_adress()
                                                    
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
        })
        task.resume()
    }
    
    func end_choice_adress() {
        DispatchQueue.main.async(execute: {
            self.stopIndicatorChoice()
            self.StopIndicator()
            self.update_view()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "get_adress") {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = adress_names
            selectItemController.selectedIndex = teck_adress
            selectItemController.selectHandler = { selectedIndex in
                
                self.ClearFlats()
                
                self.teck_adress = selectedIndex
                let choice_id_adress   = self.adress_ids[selectedIndex]
                
                self.edAdress.text = self.appAdressString()
                
                self.AddFlats(id_house: choice_id_adress)
                
            }
        } else if (segue.identifier == "get_flat") {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = flats_names
            selectItemController.selectedIndex = teck_flat
            selectItemController.selectHandler = { selectedIndex in
                
                self.teck_flat = selectedIndex
                
                self.edFlat.text = self.appFlatString()
                
                
            }
        }
    }
    
    func ClearFlats() {
        flats_names = []
        flats_ids = []
        teck_flat = -1
    }
    
    // Процедуры отображения названий
    func appAdressString() -> String {
        if teck_adress == -1 {
            return ""
        }
        if teck_adress >= 0 && teck_adress < adress_names.count {
            return adress_names[teck_adress]
        }
        return ""
    }
    
    func appFlatString() -> String {
        if teck_flat == -1 {
            return ""
        }
        if teck_flat >= 0 && teck_flat < flats_names.count {
            return flats_names[teck_flat]
        }
        return ""
    }
    
    // Получение квартир по указанному дому
    func AddFlats(id_house: String) {
        self.startIndicatorChoice(num_ind: "2")
        
        let urlPath = Server.SERVER + Server.GET_HOUSES_FLATS + "id=" + id_house
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    // Получим список квартир по дому
                                                    if let raions = json["Premises"] {
                                                        if ((raions.count)! - 1) > 0 {
                                                            for index in 0...(raions.count)!-1 {
                                                                let obj_raion = raions.object(at: index) as! [String:AnyObject]
                                                                for obj in obj_raion {
                                                                    if obj.key == "Number" {
                                                                        var flat = obj.value as! String
                                                                        self.flats_names.append(flat + " кв.")
                                                                        if (flat.characters.count == 1) {
                                                                            flat = "000" + flat
                                                                        } else if (flat.characters.count == 2) {
                                                                            flat = "00" + flat
                                                                        } else if (flat.characters.count == 3) {
                                                                            flat = "0" + flat
                                                                        }
                                                                        self.flats_ids.append(flat)
                                                                    }
                                                                    //                                                                if obj.key == "ID" {
                                                                    //                                                                    self.flats_ids.append(String(describing: obj.value))
                                                                    //                                                                }
                                                                }
                                                            }
                                                        }
                                                        
                                                    }
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
                                                self.end_choice_adress()
                                                
        })
        task.resume()
    }
    
    @objc func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Общая процедура обновления всех данных на форме
    func update_view() {
        
        if (adress_names.count == 0) {
            btnAdress.isEnabled = false
        } else {
            btnAdress.isEnabled = true
        }
        
        if (flats_names.count == 0) {
            btnFlat.isEnabled = false
        } else {
            btnFlat.isEnabled = true
        }

    }
    
    func StartIndicator(){
        self.btnReg.isHidden = true
        self.btnCancel.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator(){
        self.btnReg.isHidden = false
        self.btnCancel.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    // Процедуры индикации
    func startIndicatorChoice(num_ind: String) {
        if (num_ind == "1") {
            indicatorAdress.isHidden = false
            indicatorFlat.isHidden   = false
            
            btnAdress.isHidden       = true
            btnFlat.isHidden         = true
            
            StartIndicator()
        } else if (num_ind == "2") {
            indicatorFlat.isHidden  = false
            
            btnFlat.isHidden         = true
            
            StartIndicator()
        }
    }
    
    func stopIndicatorChoice() {
        
        indicatorAdress.isHidden = true
        indicatorFlat.isHidden  = true
        
        btnAdress.isHidden       = false
        btnFlat.isHidden         = false
        
        StopIndicator()
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
