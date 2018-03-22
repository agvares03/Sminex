//
//  Registration_Sminex_SMS.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class Registration_Sminex_SMS: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var txtNameLS:   UILabel!
    @IBOutlet private weak var NameLS:      UILabel!
    @IBOutlet private weak var descTxt:     UILabel!
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    @IBOutlet private weak var btn_go:      UIButton!
    @IBOutlet private weak var smsField:    UITextField!
    @IBOutlet private weak var showpswrd:   UIButton!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var againLabel:  UIButton!
    @IBOutlet private weak var againLine:   UILabel!
    @IBOutlet private weak var backView:    UIView!
    
    @IBAction private func btn_go_touch(_ sender: UIButton) {
        
        guard (smsField.text?.count ?? 0) >= 0 else {
            descTxt.text = "Введите код доступа"
            return
        }
        
        startLoading()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.COMPLETE_REG + "smsCode=" + (smsField.text ?? ""))!)
        request.httpMethod = "GET"
        
        if !isReg_ {
            request = URLRequest(url: URL(string: Server.SERVER + Server.COMPLETE_REM + "smsCode=" + (smsField.text ?? ""))!)
            request.httpMethod = "GET"
        }
        
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
    
    @objc private func btn_cancel(_ sender: UITapGestureRecognizer?) {
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func retryLabelPressed(_ sender: UIButton) {
        
        self.startLoading()
        
        if isReg_ {
            registration()
        
        } else {
            forgotPass()
        }
    }
    
    open var isPhone_     = false
    open var isReg_       = false
    open var numberPhone_ = ""
    open var numberLs_    = ""
    
    private var responseString  = ""
    private var descText        = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        endLoading()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        if numberPhone_ != "" {
            txtNameLS.text  = "Номер телефона"
            NameLS.text     = numberPhone_
            
        } else {
            txtNameLS.text  = "Номер лицевого счета"
            NameLS.text     = numberLs_
        }
        
        showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
        smsField.isSecureTextEntry = true
        
        descText = descTxt.text ?? ""
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(btn_cancel(_:)))
        recognizer.delegate = self
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(recognizer)
        
        startTimer()
    }
    
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        if isNeedToScroll() {
            
            if isNeedToScrollMore() {
                scroll.contentSize.height += 30
                scroll.contentOffset = CGPoint(x: 0, y: 80)
            
            } else {
                view.frame.origin.y = -30
            }
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if isNeedToScroll() {
            
            if isNeedToScrollMore() {
                scroll.contentSize.height -= 30
                scroll.contentOffset = CGPoint(x: 0, y: 0)
            
            } else {
                view.frame.origin.y = 0
            }
        }
    }
    
    private func startTimer() {
        DispatchQueue.global(qos: .userInteractive).async {
            sleep(60)
            
            DispatchQueue.main.async {
                self.againLabel.isHidden    = false
                self.againLine.isHidden     = false
                self.descTxt.text = self.descTxt.text?.replacingOccurrences(of: "Запросить новый код можно через минуту", with: "")
            }
        }
    }
    
    private func choise() {
        
        DispatchQueue.main.async {
            
            if self.responseString.contains(find: "error") {
                self.descTxt.text       = self.responseString.replacingOccurrences(of: "error:", with: "")
                self.descTxt.textColor  = .red

            } else {
                self.descTxt.text       = self.responseString
                self.descTxt.textColor  = .gray
                self.performSegue(withIdentifier: Segues.fromRegistrationSminexSMS.toEnterPassword, sender: self)
            }
        
            self.endLoading()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Поправим текущий UI перед переходом
        keyboardWillHide(sender: nil)
        
        if segue.identifier == Segues.fromRegistrationSminexSMS.toEnterPassword {
            let vc = segue.destination as! RegistrationSminexEnterPassword
            
            let response = responseString.components(separatedBy: ";")
            
            vc.login_ = response[0].replacingOccurrences(of: "ok: ", with: "")
            vc.phone_ = response[1]
            
            print(responseString)
            print(response)
            print(response[0].replacingOccurrences(of: "ok: ", with: ""))
            print(response[1])
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
    
    private func registration() {
        var ls_for_zapros = numberLs_.replacingOccurrences(of: "+", with: "")
        ls_for_zapros = numberLs_.replacingOccurrences(of: " ", with: "")
        if (isPhone_) {
            ls_for_zapros = "7" + ls_for_zapros.substring(fromIndex: 1)
        }
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REGISTRATION_SMINEX + "identOrPhone=" + ls_for_zapros)!)
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
                print("responseString = \(self.responseString)")
            #endif
            self.choiceReg()
            }.resume()
    }
    
    private func forgotPass() {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.FORGOT + "identOrPhone=" + numberLs_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                let alert = UIAlertController(title: "Результат", message: "Не удалось. Попробуйте позже", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
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
            self.endLoading()
            
            if self.responseString.contains("error") {
                let alert = UIAlertController(title: "Ошибка", message: self.responseString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { (_) -> Void in self.navigationController?.popViewController(animated: true) }))
                self.present(alert, animated: true, completion: nil)
                
            } else {
                self.descTxt.text           = self.descText
                self.againLabel.isHidden    = true
                self.againLine.isHidden     = false
                self.startTimer()
            }
        }
    }
    
    private func choiceReg() {
        
        DispatchQueue.main.async {
            self.endLoading()
            
            if self.responseString.contains("error") {
                let alert = UIAlertController(title: "Ошибка", message: self.responseString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ок", style: .default, handler: { (_) -> Void in self.navigationController?.popViewController(animated: true) }))
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString.contains("ok") {
                self.descTxt.text           = self.descText
                self.againLabel.isHidden    = true
                self.againLine.isHidden     = false
                self.startTimer()
            }
        }
    }
}
