//
//  Registration_Sminex_SMS.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class Registration_Sminex_SMS: UIViewController {
    
    @IBOutlet private weak var txtNameLS:   UILabel!
    @IBOutlet private weak var NameLS:      UILabel!
    @IBOutlet private weak var descTxt:     UILabel!
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    @IBOutlet private weak var btn_go:      UIButton!
    @IBOutlet private weak var smsField:    UITextField!
    @IBOutlet private weak var showpswrd:   UIButton!
    
    @IBAction private func btn_go_touch(_ sender: UIButton) {
        
        guard (smsField.text?.count ?? 0) >= 0 else {
            descTxt.text = "Введите код доступа"
            return
        }
        
        startLoading()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.COMPLETE_REG + "smsCode=" + (smsField.text ?? ""))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                
                DispatchQueue.main.async {
                    self.endLoading()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                print(self.responseString)
            #endif
            
            self.choise()
            
            }.resume()
    }
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if smsField.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            smsField.isSecureTextEntry = false
        } else {
            
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            smsField.isSecureTextEntry = true
        }
    }
    
    @IBAction private func btn_cancel(_ sender: UIButton) {
        
        navigationController?.popViewController(animated: true)
    }
    
    open var isReg_ = false
    
    open var numberPhone_ = ""
    open var numberLs_    = ""
    
    private var responseString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        endLoading()
        
        smsField.isSecureTextEntry = false
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        if numberPhone_ != "" {
            txtNameLS.text  = "Номер телефона"
            NameLS.text     = numberPhone_
        } else {
            txtNameLS.text  = "Номер лицевого счета"
            NameLS.text     = numberLs_
        }
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification) {
        
        // Только если 4" экран
        if Device().isOneOf([Device.iPhone5,
                             Device.iPhone5s,
                             Device.iPhone5c,
                             Device.iPhoneSE,
                             Device.simulator(Device.iPhone5),
                             Device.simulator(Device.iPhone5s),
                             Device.simulator(Device.iPhone5c),
                             Device.simulator(Device.iPhoneSE)]) {
            
            self.view.frame.origin.y = -30
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification) {
        
        // Только если 4" экран
        if Device().isOneOf([Device.iPhone5,
                             Device.iPhone5s,
                             Device.iPhone5c,
                             Device.iPhoneSE,
                             Device.simulator(Device.iPhone5),
                             Device.simulator(Device.iPhone5s),
                             Device.simulator(Device.iPhone5c),
                             Device.simulator(Device.iPhoneSE)]) {
            
            self.view.frame.origin.y = 0
        }
    }
    
    private func choise() {
        
        DispatchQueue.main.async {
            
            if self.responseString.contains(find: "error") {
                self.descTxt.text       = self.responseString.replacingOccurrences(of: "error:", with: "")
                self.descTxt.textColor  = .red
            
            } else {
                self.descTxt.text       = self.responseString
                self.descTxt.textColor  = .lightGray
                self.performSegue(withIdentifier: Segues.fromRegistrationSminexSMS.toEnterPassword, sender: self)
            }
        
            self.endLoading()
        }
    }
    
    private func startLoading() {
        
        indicator.isHidden = false
        indicator.startAnimating()
        
        btn_go.isHidden = true
    }
    
    private func endLoading() {
        
        indicator.isHidden = true
        indicator.stopAnimating()
        
        btn_go.isHidden = false
    }
}
