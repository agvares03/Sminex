//
//  Registration_Sminex.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit
import Gloss

final class AddLS: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var didntEnter: UILabel!
    @IBOutlet private weak var sprtTop:     NSLayoutConstraint!
    @IBOutlet private weak var edLsTop:     NSLayoutConstraint!
    @IBOutlet private weak var btnGoTop:    NSLayoutConstraint!
    @IBOutlet private weak var edLS:        UITextField!
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    @IBOutlet private weak var backButton:  UIButton!
    @IBOutlet private weak var btn_go:      UIButton!
    @IBOutlet private weak var txtDesc:     UILabel!
    @IBOutlet private weak var sprtLabel:   UILabel!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var backView:    UIView!
    
    public var isFromApp_ = false
    
    private var responseString = ""
    private var ls = ""
    
    // Признак того, вводим мы телефон или нет
    private var itsPhone = false
    
    @IBAction private func btn_go_action(_ sender: UIButton) {
        var didntAdd = false
        TemporaryHolder.instance.allLS.forEach {
            let item: AllLsData = $0
            let ident = item.ident
            if ident == edLS.text{
                didntAdd = true
            }
        }
        if didntAdd == true{
            self.txtDesc.textColor = .red
            let ident: String = edLS.text!
            self.txtDesc.text = "Лицевой счет \(ident) уже добавлен в приложение"
            self.changeGoButton(isEnabled: false)
        }else if edLS.text != "" {
            view.endEditing(true)
            self.startAnimation()
            
            checkLS()
        } else {
            let alert = UIAlertController(title: "Ошибка", message: "Укажите лиц. счет или номер телефона, привязанного к лиц. счету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction private func callSupportButtonPressed(_ sender: UIButton) {
        view.endEditing(true)
        if let url = URL(string: "tel://+74957266791") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func btn_cancel(_ sender: UITapGestureRecognizer?) {
        navigationController?.popViewController(animated: true)
    }
    
    private func checkLS() {
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let code = edLS.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.CHECK_ACCOUNT + "login=\(login.stringByAddingPercentEncodingForRFC3986() ?? "")&pwd=\(pwd)&code=\(code)")!)
        print(request)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    self.stopAnimation()
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
            self.choice()
            }.resume()
    }
    
    private func choice() {
        
        DispatchQueue.main.sync {
            
            self.stopAnimation()
            
            if self.responseString.contains(find: "не зарегистрирован") {
                self.changeDescTextTo(isError: true, text: responseString)
                
            } else if self.responseString.contains(find: "не обнаружен привязанный") {
                self.changeDescTextTo(isError: true, text: responseString)
                
            } else if self.responseString.length > 150 {
                self.changeDescTextTo(isError: true, text: "Ошибка сервера. Попробуйте позже")
                
            } else if self.responseString == "xxx" {
                self.changeDescTextTo(isError: true, text: "Ошибка сервера. Попробуйте позже")
                
            } else if self.responseString.contains("error") {
                self.changeDescTextTo(isError: true, text: self.responseString.replacingOccurrences(of: "error:", with: ""))
            } else {
                sendSMS()
            }
        }
    }
    
    private func sendSMS() {
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let code = edLS.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.NEW_ACCOUNT_SMS + "login=\(login.stringByAddingPercentEncodingForRFC3986() ?? "")&pwd=\(pwd)&code=\(code)")!)
//        print(request)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    self.stopAnimation()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            #if DEBUG
//            print("responseString = \(self.responseString)")
            #endif
            self.choiceSMS()
            }.resume()
    }
    
    private func choiceSMS() {
        
        DispatchQueue.main.sync {
            
            self.stopAnimation()
            
            if self.responseString.contains(find: "уже выслан") {
                self.changeDescTextTo(isError: true, text: responseString)
                
            } else {
                self.changeDescTextTo(isError: false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edLS.delegate = self;
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        edLS.text = ls
        indicator.isHidden = true
        
        if isFromApp_ {
            tabBarController?.tabBar.isHidden = true
            //            navigationController?.isNavigationBarHidden = true
            backView.isHidden   = true
            backButton.isHidden = true
            let login   = UserDefaults.standard.string(forKey: "login") ?? ""
            ls          = login
            edLS.text   = login
            
        } else {
            btn_go.isEnabled = false
            btn_go.alpha = 0.5
        }
        
        if isNeedToScrollMore() {
            btnGoTop.constant = 15
            edLsTop.constant  = 45
        }
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(btn_cancel(_:)))
        recognizer.delegate = self
        backView.addGestureRecognizer(recognizer)
        backView.isUserInteractionEnabled = true
        if Device() == .iPhoneX && Device() == .simulator(.iPhoneX) {
            sprtTop.constant = (view.frame.size.height - sprtLabel.frame.origin.y) - 220
        } else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            sprtTop.constant = (view.frame.size.height - sprtLabel.frame.origin.y) - 140
        } else{
            sprtTop.constant = (view.frame.size.height - sprtLabel.frame.origin.y) - 125
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        edLS.becomeFirstResponder()
        navigationController?.isNavigationBarHidden = false
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        
        //        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        //        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    //    @objc func keyboardWillShow(sender: NSNotification?) {
    //        if !isNeedToScrollMore() {
    //            sprtTop.constant -= 200
    //
    //        } else {
    //            sprtTop.constant -= 120
    //        }
    //    }
    
    // И вниз при исчезновении
    //    @objc func keyboardWillHide(sender: NSNotification?) {
    //
    //        if !isNeedToScrollMore() {
    //            sprtTop.constant += 200
    //        } else {
    //            sprtTop.constant += 120
    //        }
    //    }
    
    private func startAnimation() {
        indicator.isHidden = false
        indicator.startAnimating()
        
        btn_go.isHidden = true
    }
    
    private func stopAnimation() {
        indicator.isHidden = true
        indicator.stopAnimating()
        
        btn_go.isHidden = false
    }
    
    private func changeDescTextTo(isError: Bool, text: String? = nil) {
        
        if isError {
            
            self.txtDesc.textColor = .red
            self.txtDesc.text = self.responseString.replacingOccurrences(of: "error: ", with: "")
            self.changeGoButton(isEnabled: false)
            
            if self.txtDesc.text?.contains(find: "уже выслан") ?? false {
                self.startTimer()
            }
            
        } else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "addNew_step1", sender: self)
            }
        }
    }
    
    private func startTimer() {
        DispatchQueue.global(qos: .background).async {
            sleep(60)
            DispatchQueue.main.async {
                self.txtDesc.textColor = .gray
                self.txtDesc.text = "Укажите ваш лицевой счет"
                self.changeGoButton(isEnabled: true)
            }
        }
    }
    
    private func changeGoButton(isEnabled: Bool) {
        
        // Если доступно, изменяем с анимацией
        // если нет, то без анимации
        if !isEnabled {
            
            if #available(iOS 10.0, *) {
                UIViewPropertyAnimator(duration: 0, curve: .easeInOut) {
                    self.btn_go.isEnabled = false
                    self.btn_go.alpha = 0.5
                    }.startAnimation()
            } else {
                btn_go.isEnabled = false
                self.btn_go.alpha = 0.5
            }
        } else {
            
            if #available(iOS 10.0, *) {
                UIViewPropertyAnimator(duration: 0, curve: .easeInOut) {
                    self.btn_go.isEnabled = true
                    self.btn_go.alpha = 1
                    }.startAnimation()
            } else {
                btn_go.isEnabled = true
                self.btn_go.alpha = 1
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        view.endEditing(true)
        
        if segue.identifier == "addNew_step1" {
            
            let vc  = segue.destination as!  AddLS_SMS
            vc.code = edLS.text!
            vc.phone_ = responseString
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !isNeedToScrollMore() {
            sprtTop.constant -= 200
            
        } else {
            sprtTop.constant -= 120
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if !isNeedToScrollMore() {
            sprtTop.constant += 200
        } else {
            sprtTop.constant += 120
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        if ls.count >= 2 || string.count > 1 {
            changeGoButton(isEnabled: true)
        } else {
            changeGoButton(isEnabled: false)
        }
        
        if string == "" {
            
            let ls_ind = ls.index(ls.endIndex, offsetBy: -1)
            let ls_end = String(ls[..<ls_ind])
            ls = ls_end
            if (ls_end == "") {
                itsPhone = false
            }
        } else {
            
            ls = ls + string
        }
        
        // определим телефон это или нет
        var ls_1_end = ""
        if (ls.count < 1) {
            ls_1_end = ""
        } else {
            let ls_1 = ls.index(ls.startIndex, offsetBy: 1)
            ls_1_end = String(ls[..<ls_1])
        }
        
        var ls_12_end = ""
        if (ls.count < 2) {
            ls_12_end = ""
        } else {
            let ls_12 = ls.index(ls.startIndex, offsetBy: 2)
            ls_12_end = String(ls[..<ls_12])
        }
        if (ls_1_end == "+") {
            itsPhone = true
        }
        if (!itsPhone) {
            if (ls_12_end == "89") || (ls_12_end == "79") {
                itsPhone = true
            }
        }
        return true
    }
}
