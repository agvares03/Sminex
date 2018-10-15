//
//  Registration_Sminex_SMS.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class AddLS_SMS: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var didntEnter: UILabel!
    @IBOutlet private weak var sprtBottom:  NSLayoutConstraint!
    @IBOutlet private weak var sprtTop:     NSLayoutConstraint!
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
    @IBOutlet private weak var sprtLabel:   UILabel!
    @IBOutlet private weak var backView:    UIView!
    
    @IBAction private func btn_go_touch(_ sender: UIButton) {
        
        guard (smsField.text?.count ?? 0) >= 0 else {
            descTxt.text = "Введите код доступа"
            return
        }
        
        view.endEditing(true)
        //        self.performSegue(withIdentifier: Segues.fromRegistrationSminexSMS.toEnterPassword, sender: self)
        startLoading()
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let code = self.code.stringByAddingPercentEncodingForRFC3986() ?? ""
        let address = UserDefaults.standard.string(forKey: "adress") ?? ""
        let smsCode = smsField.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ADD_NEW_LS + "login=\(login.stringByAddingPercentEncodingForRFC3986() ?? "")&pwd=\(pwd)&code=\(code)&address=\(address)&smsCode=\(smsCode)")!)
        print(request)
        
        request.httpMethod = "GET"        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil || data == nil /*|| (String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false)*/ {
                
                DispatchQueue.main.async {
                    self.endLoading()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Обратитесь в тех. поддержку", preferredStyle: .alert)
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
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if smsField.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            smsField.isSecureTextEntry = false
            
        } else {
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            smsField.isSecureTextEntry = true
        }
    }
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func btn_cancel(_ sender: UITapGestureRecognizer?) {
        navigationController?.popViewController(animated: true)
    }
    
//    @IBAction private func retryLabelPressed(_ sender: UIButton) {
//        self.startLoading()
//        addNewLS()
//    }
    
    open var phone_       = ""
    open var code         = ""
    
    private var responseString  = ""
    private var descText        = ""
    private var topConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endLoading()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        txtNameLS.text  = "Номер лицевого счета"
        NameLS.text     = code
        descTxt.text    = "Отправлен на телефон \(phone_) (действует в течение 10 минут). Запросить новый код можно через минуту"
        
        descText = descTxt.text ?? ""
        
        btn_go.isEnabled = false
        btn_go.alpha = 0.5
        
        smsField.delegate = self
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(btn_cancel(_:)))
        recognizer.delegate = self
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(recognizer)
        
        topConstant = sprtLabel.frame.origin.y
        sprtTop.constant = getPoint()
        startTimer()
    }
    
    @objc private func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        navigationController?.isNavigationBarHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = true
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        if !isNeedToScrollMore() {
            if !isNeedToScroll() {
                sprtTop.constant = getPoint() - 210
                
            } else {
                sprtTop.constant = getPoint() - 200
            }
            
        } else {
            sprtTop.constant    -= getPoint() - 120
            sprtBottom.constant += 200
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if !isNeedToScrollMore() {
            sprtTop.constant = getPoint()
            
        } else {
            sprtTop.constant    = getPoint()
            sprtBottom.constant -= 200
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
        
        DispatchQueue.main.sync {
            
            if self.responseString.contains(find: "error") {
                self.descTxt.text       = self.responseString.replacingOccurrences(of: "error:", with: "")
                self.descTxt.textColor  = .red
                
            } else {
                var lsList      : [String] = []
                var addressList : [String] = []

                lsList = UserDefaults.standard.stringArray(forKey: "allLS")!
                addressList = UserDefaults.standard.stringArray(forKey: "allAddress")!
                
                lsList.append(self.code)
                addressList.append(UserDefaults.standard.string(forKey: "adress")!)
                
                let defaults = UserDefaults.standard
                defaults.setValue(lsList, forKey: "allLS")
                defaults.setValue(addressList, forKey: "allAddress")
                defaults.synchronize()
                
                let ident: String = self.code
                let alert = UIAlertController(title: "Лицевой счёт \(ident) добавлен", message: "", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    self.performSegue(withIdentifier: "completeAdd", sender: self) }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
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
                self.againLine.isHidden     = true
                self.startTimer()
            }
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if smsField.text != "" {
            btn_go.isEnabled = true
            btn_go.alpha = 1
            
        } else {
            btn_go.isEnabled = false
            btn_go.alpha = 0.5
        }
        return true
    }
    
    private func getPoint() -> CGFloat {
        if Device() == .iPhoneX && Device() == .simulator(.iPhoneX) {
            return (view.frame.size.height - topConstant) - 220
            
        } else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) || Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) || Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) || Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            return (view.frame.size.height - topConstant) - 135
        } else {
            return (view.frame.size.height - topConstant) - 120
        }
    }
}
