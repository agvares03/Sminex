//
//  Registration.swift
//  DemoUC
//
//  Created by Роман Тузин on 16.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

final class Registration: UIViewController {
    
    // Картинки на подмену
    @IBOutlet private weak var fon_top:   UIImageView!
    @IBOutlet private weak var new_face:  UIImageView!
    @IBOutlet private weak var number_ls: UIImageView!
    @IBOutlet private weak var new_phone: UIImageView!
    @IBOutlet private weak var new_mail:  UIImageView!
    
    private var responseString  = ""
    open var letter_            = ""
    
    @IBOutlet private weak var edFIO:     UITextField!
    @IBOutlet private weak var edLogin:   UITextField!
    @IBOutlet private weak var edTelefon: UITextField!
    @IBOutlet private weak var edMail:    UITextField!
    
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    @IBOutlet private weak var btnReg:    UIButton!
    @IBOutlet private weak var btnCancel: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        stopIndicator()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        edLogin.text = letter_
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction private func regBtn(_ sender: UIButton) {
        startIndicator()
        
        let txtLogin   = edLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtFIO     = edFIO.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtTelefon = edTelefon.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtMail    = edMail.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REGISTRATION + "login=" + txtLogin + "&fio=" + txtFIO + "&phone=" + txtTelefon + "&email=" + txtMail)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request){
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "Результат", message: "Не удалось. Попробуйте позже", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                self.responseString = "xxx";
                self.choice()
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
                let alert = UIAlertController(title: "Ошибка", message: "Переданы некорректные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "2" {
                let alert = UIAlertController(title: "Ошибка", message: "Лиц. счет на найден в базе данных", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "3" {
                let alert = UIAlertController(title: "Ошибка", message: "Этот лиц. счет уже зарегистрирован", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "4" {
                let alert = UIAlertController(title: "Ошибка", message: "По данному лиц. счету не проживает - " + self.edFIO.text!, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "5" {
                let alert = UIAlertController(title: "Ошибка", message: "Некорректный e-mail", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString.length > 150 {
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "xxx" {
                self.stopIndicator()

        } else {
                let alert = UIAlertController(title: "Успешно", message: "Регистрация прошла успешно. Пароль выслан на указанный e-mail.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction private func regCancel(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    private func startIndicator() {
        self.btnReg.isHidden    = true
        self.btnCancel.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator() {
        self.btnReg.isHidden    = false
        self.btnCancel.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    
}
