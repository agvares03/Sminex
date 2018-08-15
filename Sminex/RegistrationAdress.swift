//
//  RegistrationAdress.swift
//  DemoUC
//
//  Created by Роман Тузин on 15.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

final class RegistrationAdress: UIViewController {
    
    // Картинки на подмену
    @IBOutlet private weak var fon_top:   UIImageView!
    @IBOutlet private weak var home:      UIImageView!
    @IBOutlet private weak var flat:      UIImageView!
    @IBOutlet private weak var number_ls: UIImageView!
    @IBOutlet private weak var new_phone: UIImageView!
    @IBOutlet private weak var new_mail:  UIImageView!
    
    private var responseString = ""
    open var letter_           = ""
    
    // Массивы для хранения данных
    private var adressNames: [String] = []
    private var adressIds:   [String] = []
    private var teckAdress = -1
    
    private var flatsNames: [String] = []
    private var flatsIds:   [String] = []
    private var teckFlat = -1

    @IBOutlet private weak var edAdress: UITextField!
    @IBOutlet private weak var edFlat:   UITextField!
    @IBOutlet private weak var edLogin:  UITextField!
    @IBOutlet private weak var edPhone:  UITextField!
    @IBOutlet private weak var edMail:   UITextField!
    
    @IBOutlet private weak var btnAdress:       UIButton!
    @IBOutlet private weak var indicatorAdress: UIActivityIndicatorView!
    @IBOutlet private weak var btnFlat:         UIButton!
    @IBOutlet private weak var indicatorFlat:   UIActivityIndicatorView!
    
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var btnCancel: UIButton!
    @IBOutlet private weak var btnReg:    UIButton!
    
    @IBAction private func goCancel(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func goReg(_ sender: UIButton) {
        
        // Регистрация
        startIndicatorChoice(num_ind: "1")
        StartIndicator()
        
        var houseID: String = ""
        if teckAdress != -1 {
            houseID = adressIds[teckAdress].addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        }
        let premiseNumber   = edFlat.text!.replacingOccurrences(of: " кв.", with: "", options: .literal, range: nil)
        let login           = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let phone           = edPhone.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let mail            = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        let urlPath = Server.SERVER + Server.REGISTRATION + "houseID=" + houseID +
                                                            "&premiseNumber=" + premiseNumber +
                                                            "&login=" + login +
                                                            "&phone=" + phone +
                                                            "&email=" + mail
        var request = URLRequest(url: URL(string: urlPath)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                return
            }
            
            let answerString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                print("answer (reg) = \(String(describing: answerString))")
            #endif
            
            self.answerReg(answer: answerString)
            
        }.resume()
        
    }
    
    private func answerReg(answer: String) {
        
        // введем переменную, которая сигнализирует о необходимости отправить письмо - неверная регистрация
        var send_letter     = false
        let answer_for_send =
                "Регистрация в iOS! " +
                "Логин: "      + edLogin.text! + " " +
                "Адрес: "      + edAdress.text! + " " +
                "Номер кв: "  + edFlat.text! + " " +
                "Телефон: "    + edPhone.text! + " " +
                "Эл почта: "  + edMail.text!
        var reason_for_send = ""
        
        DispatchQueue.main.async {
            
            if answer == "1" {
                send_letter     = true
                reason_for_send = "Тестовый посыл."
                
                // Переданы некорректные данные
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Переданы некорректные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "2" {
                send_letter = true
                reason_for_send = "Лицевой счет на найден в базе данных"
                // Лицевой счет не найден в базе данных
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в базе данных", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "3" {
                send_letter = true
                reason_for_send = "Этот лицевой счет уже зарегистрирован"
                // Этот лицевой счет уже зарегистрирован
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Этот лицевой счет уже зарегистрирован", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "5" {
                send_letter = true
                reason_for_send = "Некорректный e-mail"
                // Некорректный e-mail
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Некорректный e-mail", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "7" {
                send_letter = true
                reason_for_send = "Лицевой счет не найден в указанной квартире"
                // Лицевой счет не найден в указанной квартире
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в указанной квартире", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "0" {
                // Регистрация прошла успешно
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
                
            } else {
                send_letter = true
                reason_for_send = "Непонятная ошибка сервера. !!!!"
                // Ошибка - попробуйте позже
                self.stopIndicatorChoice()
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        if (send_letter) {
            
            // Отравим письмо на почту, что регистрация не удалась
            let login = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let mail  = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var text_for_send = answer_for_send + " Причина ошибки: " + reason_for_send
            text_for_send     = text_for_send.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            let txt_login     = login == "" ? "_" : login
            let txt_mail      = mail == "" ? "_" : mail
            let urlPath = Server.SERVER + Server.SEND_MAIL +
                "login=" + txt_login +
                "&text=" + text_for_send +
                "&mail=" + txt_mail
            
            #if DEBUG
                print("text (send) = \(String(describing: urlPath))")
            #endif
            
            var request = URLRequest(url: URL(string: urlPath)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if error != nil {
                    
                    #if DEBUG
                        print("text (send) = \(String(describing: urlPath))")
                    #endif
                    return
                }
                
                let answerString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
                    print("text (send) = \(String(describing: urlPath))")
                    print("answer (send) = \(String(describing: answerString))")
                #endif
            }.resume()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        edLogin.text = letter_
        
        // Действия для подбора адреса
        indicatorAdress.startAnimating()
        indicatorFlat.startAnimating()
        startIndicatorChoice(num_ind: "1")
        StartIndicator()
        
        // Первый показ - загрузим адреса домов
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_HOUSES_ONLY)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
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
                                self.adressNames.append(obj.value as! String)
                            }
                            if obj.key == "ID" {
                                self.adressIds.append(String(describing: obj.value))
                            }
                        }
                    }
                }
                
                self.endChoiceAdress()
                
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
        }.resume()
    }
    
    private func endChoiceAdress() {
        DispatchQueue.main.async {
            self.stopIndicatorChoice()
            self.StopIndicator()
            self.updateView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromRegistrationAddres.toGetAddres {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = adressNames
            selectItemController.selectedIndex_ = teckAdress
            selectItemController.selectHandler_ = { selectedIndex in
                
                self.clearFlats()
                
                self.teckAdress      = selectedIndex
                let choice_id_adress = self.adressIds[selectedIndex]
                
                self.edAdress.text   = self.appAdressString()
                
                self.addFlats(id_house: choice_id_adress)
                
            }
        } else if segue.identifier == Segues.fromRegistrationAddres.toGetFlat {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = flatsNames
            selectItemController.selectedIndex_ = teckFlat
            selectItemController.selectHandler_ = { selectedIndex in
                
                self.teckFlat    = selectedIndex
                self.edFlat.text = self.appFlatString()
            }
        }
    }
    
    private func clearFlats() {
        flatsNames = []
        flatsIds   = []
        teckFlat   = -1
    }
    
    // Процедуры отображения названий
    private func appAdressString() -> String {
        if teckAdress == -1 {
            return ""
        }
        if teckAdress >= 0 && teckAdress < adressNames.count {
            return adressNames[teckAdress]
        }
        return ""
    }
    
    private func appFlatString() -> String {
        if teckFlat == -1 {
            return ""
        }
        if teckFlat >= 0 && teckFlat < flatsNames.count {
            return flatsNames[teckFlat]
        }
        return ""
    }
    
    // Получение квартир по указанному дому
    private func addFlats(id_house: String) {
        self.startIndicatorChoice(num_ind: "2")
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_HOUSES_FLATS + "id=" + id_house)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
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
                                    self.flatsNames.append(flat + " кв.")
                                    if flat.count == 1 {
                                        flat = "000" + flat
                                    } else if flat.count == 2 {
                                        flat = "00" + flat
                                    } else if flat.count == 3 {
                                        flat = "0" + flat
                                    }
                                    self.flatsIds.append(flat)
                                }
                            }
                        }
                    }
                }
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
            self.endChoiceAdress()
            
        }.resume()
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Общая процедура обновления всех данных на форме
    private func updateView() {
        
        if adressNames.count == 0 {
            btnAdress.isEnabled = false
        } else {
            btnAdress.isEnabled = true
        }
        
        if flatsNames.count == 0 {
            btnFlat.isEnabled = false
        } else {
            btnFlat.isEnabled = true
        }

    }
    
    private func StartIndicator() {
        self.btnReg.isHidden    = true
        self.btnCancel.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func StopIndicator() {
        self.btnReg.isHidden    = false
        self.btnCancel.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    // Процедуры индикации
    private func startIndicatorChoice(num_ind: String) {
        if num_ind == "1" {
            indicatorAdress.isHidden = false
            indicatorFlat.isHidden   = false
            
            btnAdress.isHidden       = true
            btnFlat.isHidden         = true
            
            StartIndicator()
        } else if num_ind == "2" {
            indicatorFlat.isHidden  = false
            
            btnFlat.isHidden        = true
            
            StartIndicator()
        }
    }
    
    private func stopIndicatorChoice() {
        
        indicatorAdress.isHidden = true
        indicatorFlat.isHidden   = true
        
        btnAdress.isHidden       = false
        btnFlat.isHidden         = false
        
        StopIndicator()
    }
}
