//
//  RegistrationAdress4.swift
//  DemoUC
//
//  Created by Роман Тузин on 20.08.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

final class RegistrationAdress4: UIViewController {
    
    // Картинки на подмену
    @IBOutlet private weak var fon_top:   UIImageView!
    @IBOutlet private weak var home:      UIImageView!
    @IBOutlet private weak var flat:      UIImageView!
    @IBOutlet private weak var number_ls: UIImageView!
    @IBOutlet private weak var new_phone: UIImageView!
    @IBOutlet private weak var new_mail:  UIImageView!
    
    private var responseString = ""
    open var letter_           = ""
    
    @IBOutlet private weak var edAdress: UITextField!
    @IBOutlet private weak var edFlat:   UITextField!
    @IBOutlet private weak var edLogin:  UITextField!
    @IBOutlet private weak var edPhone:  UITextField!
    @IBOutlet private weak var edMail:   UITextField!
    
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet private weak var btnCancel: UIButton!
    @IBOutlet private weak var btnReg:    UIButton!
    
    @IBAction private func goCancel(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func goReg(_ sender: UIButton) {
        
        // Регистрация
        startIndicator()
        
        let address       = edAdress.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let premiseNumber = edFlat.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let login         = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let phone         = edPhone.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let mail          = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        var itsOk: Bool = true
        if address == "" {
            itsOk = false
        }
        if premiseNumber == "" {
            itsOk = false
        }
        if login == "" {
            itsOk = false
        }
        if phone == "" {
            itsOk = false
        }
        if mail == "" {
            itsOk = false
        }
        if !itsOk {
            self.stopIndicator()
            var textError = "Не заполнены параметры: "
            var firstPar  = true
            if address == "" {
                textError = textError + "адрес дома"
                firstPar = false
            }
            if premiseNumber == "" {
                if firstPar {
                    textError = textError + "номер квартиры"
                    firstPar = false
                } else {
                    textError = textError + ", номер квартиры"
                }
            }
            if login == "" {
                if firstPar {
                    textError = textError + "логин"
                    firstPar = false
                } else {
                    textError = textError + ", логин"
                }
            }
            if phone == "" {
                if firstPar {
                    textError = textError + "номер телефона"
                    firstPar = false
                } else {
                    textError = textError + ", номер телефона"
                }
            }
            if mail == "" {
                if firstPar {
                    textError = textError + "e-mail"
                    firstPar = false
                } else {
                    textError = textError + ", e-mail"
                }
            }
            let alert = UIAlertController(title: "Ошибка", message: textError, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else {
            let urlPath = Server.SERVER + Server.REGISTRATION +
                "address=" + address +
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
    }
    
    private func answerReg(answer: String) {
        DispatchQueue.main.async {
            
            if answer == "1" {
                // Переданы некорректные данные
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Переданы некорректные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "2" {
                // Лицевой счет не найден в базе данных
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в базе данных", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "3" {
                // Этот лицевой счет уже зарегистрирован
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Этот лицевой счет уже зарегистрирован", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "5" {
                // Некорректный e-mail
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Некорректный e-mail", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "7" {
                // Лицевой счет не найден в указанной квартире
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в указанной квартире", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if answer == "0" {
                // Регистрация прошла успешно
                self.stopIndicator()
                
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
                // Ошибка - попробуйте позже
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
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
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Процедуры индикации
    private func startIndicator(){
        self.btnReg.isHidden    = true
        self.btnCancel.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator(){
        self.btnReg.isHidden    = false
        self.btnCancel.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
}
