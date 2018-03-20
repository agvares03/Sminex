//
//  RegistrationAdress4.swift
//  DemoUC
//
//  Created by Роман Тузин on 20.08.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class RegistrationAdress4: UIViewController {
    // Картинки на подмену
    @IBOutlet weak var fon_top: UIImageView!
    @IBOutlet weak var home: UIImageView!
    @IBOutlet weak var flat: UIImageView!
    @IBOutlet weak var number_ls: UIImageView!
    @IBOutlet weak var new_phone: UIImageView!
    @IBOutlet weak var new_mail: UIImageView!
    
    var responseString:NSString = ""
    var letter:String = ""
    
    @IBOutlet weak var edAdress: UITextField!
    @IBOutlet weak var edFlat: UITextField!
    @IBOutlet weak var edLogin: UITextField!
    @IBOutlet weak var edPhone: UITextField!
    @IBOutlet weak var edMail: UITextField!
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var btnReg: UIButton!
    
    @IBAction func goCancel(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func goReg(_ sender: UIButton) {
        // Регистрация
        StartIndicator()
        
        let address = edAdress.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let premiseNumber = edFlat.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let login = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let phone = edPhone.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let mail = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        var itsOk: Bool = true
        if (address == "") {
            itsOk = false
        }
        if (premiseNumber == "") {
            itsOk = false
        }
        if (login == "") {
            itsOk = false
        }
        if (phone == "") {
            itsOk = false
        }
        if (mail == "") {
            itsOk = false
        }
        if (!itsOk) {
            self.StopIndicator()
            var textError: String = "Не заполнены параметры: "
            var firstPar: Bool = true
            if (address == "") {
                textError = textError + "адрес дома"
                firstPar = false
            }
            if (premiseNumber == "") {
                if (firstPar) {
                    textError = textError + "номер квартиры"
                    firstPar = false
                } else {
                    textError = textError + ", номер квартиры"
                }
            }
            if (login == "") {
                if (firstPar) {
                    textError = textError + "логин"
                    firstPar = false
                } else {
                    textError = textError + ", логин"
                }
            }
            if (phone == "") {
                if (firstPar) {
                    textError = textError + "номер телефона"
                    firstPar = false
                } else {
                    textError = textError + ", номер телефона"
                }
            }
            if (mail == "") {
                if (firstPar) {
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
        
    }
    
    func answer_reg(answer: String) {
        if (answer == "1") {
            // Переданы некорректные данные
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Переданы некорректные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "2") {
            // Лицевой счет не найден в базе данных
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в базе данных", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "3") {
            // Этот лицевой счет уже зарегистрирован
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Этот лицевой счет уже зарегистрирован", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "5") {
            // Некорректный e-mail
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Некорректный e-mail", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "7") {
            // Лицевой счет не найден в указанной квартире
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Лицевой счет не найден в указанной квартире", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        } else if (answer == "0") {
            // Регистрация прошла успешно
            DispatchQueue.main.async(execute: {
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
            // Ошибка - попробуйте позже
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
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
    }
    
    @objc func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Процедуры индикации
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
    
}
