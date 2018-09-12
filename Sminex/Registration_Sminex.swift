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
var ls1:[String] = []
final class Registration_Sminex: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate {
    
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
    
    open var isNew      = false
    open var isReg_     = true
    open var isFromApp_ = false
    
    private var responseString = ""
    
    private var ls = ""
    
    // Признак того, вводим мы телефон или нет
    private var itsPhone = false
    
    @IBAction private func btn_go_action(_ sender: UIButton) {
        
//        performSegue(withIdentifier: Segues.fromRegistrationSminex.toRegStep1, sender: self)
        
        if edLS.text != "" {
            view.endEditing(true)
            self.startAnimation()
            // Здесь мы проверяем есть ли лиц. счет или номер телефона
            // Если нет лиц. счета -                 txtDesc = "Лицевой счет " + edLS + " не зарегистрирован".
            // Если нет телефона у лиц. счета -      txtDesc = "По лицевому счету " + edLS + " не обнаружен привязанный телефон".
            // Если указанный телефон не обнаружен - txtDesc = "Телефон " + edLS + " не привязан ни к одному лицевому счету".
            // Если все ок - переходим на страницу ввода кода смс

            if isReg_ {
                registration()

            } else {
//                performSegue(withIdentifier: Segues.fromRegistrationSminex.toRegStep1, sender: self)
                forgotPass()
            }
        } else {
            let alert = UIAlertController(title: "Ошибка", message: "Укажите лиц. счет или номер телефона, привязанного к лиц. счету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }

    }
    
    @IBAction private func callSupportButtonPressed(_ sender: UIButton) {
        view.endEditing(true)
        if let url = URL(string: "tel://74951911774") {
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
    
    private func registration() {
        var ls_for_zapros = ls.replacingOccurrences(of: "+", with: "")
        ls_for_zapros = ls.replacingOccurrences(of: " ", with: "")
//        if (itsPhone) {
//            ls_for_zapros = "7" + ls_for_zapros.substring(fromIndex: 1)
//        }
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REGISTRATION_SMINEX + "identOrPhone=" + ls_for_zapros)!)
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
    
    private func forgotPass() {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.FORGOT + "identOrPhone=" + edLS.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!)!)
        request.httpMethod = "GET"
        print(request)
        
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
        
        DispatchQueue.main.sync {
            
            self.stopAnimation()
            
            if self.responseString == "1" {
                self.changeDescTextTo(isError: true, text: "Не указан лицевой счет")
                
            } else if self.responseString == "2" {
                self.changeDescTextTo(isError: true, text: "Некорректные данные")
                
            } else if self.responseString.length > 150 {
                self.changeDescTextTo(isError: true, text: "Ошибка сервера. Попробуйте позже")
                
            } else if self.responseString == "xxx" {
                self.changeDescTextTo(isError: true, text: "Ошибка сервера. Попробуйте позже")
            
            } else if self.responseString == "error:  Найдено более одного лицевого счёта. Для уточнения введите номер лицевого счёта."{
                self.getLSforNumber()
            } else if self.responseString.contains("error") {
                self.changeDescTextTo(isError: true, text: self.responseString.replacingOccurrences(of: "error:", with: ""))
            } else {
                self.changeDescTextTo(isError: false)
            }
        }
    }
    private func getLSforNumber(){
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_PHONE + "phone=" + self.edLS.text!)!)
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
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                // Получим список ЛС
                ls1 = json["data"] as! [String]
            } catch let error {
                
                #if DEBUG
                print(error)
                #endif
            }
            if ls1.count > 1{
                self.showLS()
            }else{
                ls1.forEach {
                    let text = $0
                    self.ls = text
                    self.edLS.text = text
                    if self.isReg_ {
                        self.registration()
                    } else {
                        self.forgotPass()
                    }
                }
            }
            
            }.resume()
    }
    
    private func showLS(){
        let action = UIAlertController(title: nil, message: "Выберите привязанный лицевой счёт", preferredStyle: .actionSheet)
        ls1.forEach {
            let text = $0
            action.addAction(UIAlertAction(title: $0, style: .default, handler: { (_) in
                self.ls = text
                self.edLS.text = text
                if self.isReg_ {
                    self.registration()
                    
                } else {
                    self.forgotPass()
                }
            }))
        }
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    private func choiceReg() {
        if (responseString.contains("error")) {
            DispatchQueue.main.sync {
                self.stopAnimation()
                self.changeDescTextTo(isError: true)
            }
        } else {
            DispatchQueue.main.sync {
                self.stopAnimation()
                self.changeDescTextTo(isError: false)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edLS.delegate = self;
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        if isNew{
            edLS.placeholder = "Лицевой счёт"
            didntEnter.text = "Не можете добавить ЛС?"
        }
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
        
        if !isReg_ && !isNew {
            navigationItem.title = "Восстановление пароля"
        }
        if isNew && isReg_{
            navigationItem.title = "Новый лицевой счёт"
        }
        if self.isNew{
            self.txtDesc.textColor = .gray
            self.txtDesc.text = "Укажите ваш лицевой счет"
        }else{
            self.txtDesc.textColor = .gray
            self.txtDesc.text = "Укажите лицевой счет или телефон, привязанный к лицевому счету"
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
            if isNew{
                self.txtDesc.textColor = .gray
                self.txtDesc.text = text == nil ? "Укажите ваш лицевой счёт" : text
            }else{
                self.txtDesc.textColor = .gray
                self.txtDesc.text = text == nil ? "Укажите лицевой счет или телефон, привязанный к лицевому счету" : text
            }
            performSegue(withIdentifier: Segues.fromRegistrationSminex.toRegStep1, sender: self)
        }
    }
    
    private func startTimer() {
        DispatchQueue.global(qos: .background).async {
            sleep(60)
            DispatchQueue.main.async {
                if self.isNew{
                    self.txtDesc.textColor = .gray
                    self.txtDesc.text = "Укажите ваш лицевой счет"
                }else{
                    self.txtDesc.textColor = .gray
                    self.txtDesc.text = "Укажите лицевой счет или телефон, привязанный к лицевому счету"
                }
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
        
        if segue.identifier == Segues.fromRegistrationSminex.toRegStep1 {
            
            let vc  = segue.destination as!  Registration_Sminex_SMS
            if itsPhone {
                vc.numberPhone_ = edLS.text!
                vc.numberLs_ = ""
            } else {
                vc.numberPhone_ = ""
                vc.numberLs_ = edLS.text!
            }
            vc.isReg_ = isReg_
            vc.isNew  = isNew
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
        if ls.count >= 2 || string.characters.count > 1 {
            changeGoButton(isEnabled: true)
        } else {
            changeGoButton(isEnabled: false)
        }
        
        if string == "" {

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
        var ls_1_end = ""
        if (ls.count < 1) {
            ls_1_end = ""
        } else {
            let ls_1 = ls.index(ls.startIndex, offsetBy: 1)
            ls_1_end = ls.substring(to: ls_1)
        }

        var ls_12_end = ""
        if (ls.count < 2) {
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
//
//        var new_ls: String = ""
//        first = true
//        var j: Int = 1
//        for character in ls {
//            if (first) {
//                new_ls = String(character)
//                first = false
//            } else {
//                if (itsPhone) {
//                    if (ls_1_end == "+") {
//                        if (j == 2) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 3) {
//                            new_ls = new_ls + "(" + String(character)
//                        } else if (j == 4) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 5) {
//                            new_ls = new_ls + String(character) + ")"
//                        } else if (j == 6) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 7) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 8) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 9) {
//                            new_ls = new_ls + "-" + String(character)
//                        } else if (j == 10) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 11) {
//                            new_ls = new_ls + "_" + String(character)
//                        } else if (j == 12) {
//                            new_ls = new_ls + String(character)
//                        } else {
//                            new_ls = new_ls + String(character)
//                        }
//                    } else {
//                        if (j == 2) {
//                            new_ls = new_ls + "(" + String(character)
//                        } else if (j == 3) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 4) {
//                            new_ls = new_ls + String(character) + ")"
//                        } else if (j == 5) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 6) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 7) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 8) {
//                            new_ls = new_ls + "-" + String(character)
//                        } else if (j == 9) {
//                            new_ls = new_ls + String(character)
//                        } else if (j == 10) {
//                            new_ls = new_ls + "-" + String(character)
//                        } else if (j == 11) {
//                            new_ls = new_ls + String(character)
//                        } else {
//                            new_ls = new_ls + String(character)
//                        }
//                    }
//                } else {
//                    new_ls = new_ls + String(character)
//                }
//            }
//            j = j + 1
//        }
//
//        if (itsPhone) {
//            if (ls_1_end == "+") {
//                if (j == 2) {
//                    new_ls = new_ls + "*(***)***-**-**"
//                } else if (j == 3) {
//                    new_ls = new_ls + "(***)***-**-**"
//                } else if (j == 4) {
//                    new_ls = new_ls + "**)***-**-**"
//                } else if (j == 5) {
//                    new_ls = new_ls + "*)***-**-**"
//                } else if (j == 6) {
//                    new_ls = new_ls + "***-**-**"
//                } else if (j == 7) {
//                    new_ls = new_ls + "**-**-**"
//                } else if (j == 8) {
//                    new_ls = new_ls + "*-**-**"
//                } else if (j == 9) {
//                    new_ls = new_ls + "-**-**"
//                } else if (j == 10) {
//                    new_ls = new_ls + "*-**"
//                } else if (j == 11) {
//                    new_ls = new_ls + "-**"
//                } else if (j == 12) {
//                    new_ls = new_ls + "*"
//                }
//            } else {
//                if (j == 3) {
//                    new_ls = new_ls + "**)***-**-**"
//                } else if (j == 4) {
//                    new_ls = new_ls + "*)***-**-**"
//                } else if (j == 5) {
//                    new_ls = new_ls + "***-**-**"
//                } else if (j == 6) {
//                    new_ls = new_ls + "**-**-**"
//                } else if (j == 7) {
//                    new_ls = new_ls + "*-**-**"
//                } else if (j == 8) {
//                    new_ls = new_ls + "-**-**"
//                } else if (j == 9) {
//                    new_ls = new_ls + "*-**"
//                } else if (j == 10) {
//                    new_ls = new_ls + "-**"
//                } else if (j == 11) {
//                    new_ls = new_ls + "*"
//                }
//            }
//        }
//
//        textField.text = new_ls
//
//        // Установим курсор, если это телефон
//        if (itsPhone) {
//            var jj = j
//            if (ls_1_end == "+") {
//                if (j == 2) {
//                    jj = 1
//                }
//                if (j > 5) {
//                    jj = j + 1
//                }
//                if (j > 8) {
//                    jj = j + 2
//                }
//                if (j > 10) {
//                    jj = j + 3
//                }
//            } else {
//                if (j > 4) {
//                    jj = j + 1
//                }
//                if (j > 7) {
//                    jj = j + 2
//                }
//                if (j > 9) {
//                    jj = j + 3
//                }
//            }
//            if let newPosition = textField.position(from: textField.beginningOfDocument, offset: jj) {
//                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
//            }
//        }
//
//        // Установим тип - для номера телефона - только цифры
//        if (itsPhone) {
//            textField.keyboardType = UIKeyboardType.phonePad
//        } else {
//            textField.keyboardType = UIKeyboardType.default
//        }
//        textField.reloadInputViews()
//
//        return false
//
        return true
    }
}
