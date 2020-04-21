//
//  AccountChangePasswordVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/6/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class AccountChangePasswordVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet private weak var loader:              UIActivityIndicatorView!
    @IBOutlet private weak var errorHeight:         NSLayoutConstraint!
    @IBOutlet private weak var viewHeight:          NSLayoutConstraint!
    @IBOutlet private weak var oldPasswordField:    UITextField!
    @IBOutlet private weak var newPasswordField:    UITextField!
    @IBOutlet private weak var oldPasswordIndicator: UILabel!
    @IBOutlet private weak var newPasswordIndicator: UILabel!
    @IBOutlet private weak var saveButton:          UIButton!
    @IBOutlet private weak var oldPasswordSecure:   UIButton!
    @IBOutlet private weak var newPasswordSecure:   UIButton!
    @IBOutlet private weak var wrongPassLabel:      UILabel!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func oldPasswordSecureButtonPressed(_ sender: UIButton?) {
        
        if oldPasswordField.isSecureTextEntry {
            oldPasswordSecure.setImage(UIImage(named: "ic_show_password"), for: .normal)
            oldPasswordField.isSecureTextEntry = false
            oldPasswordSecure.tintColor = mainGreenColor
        } else {
            oldPasswordSecure.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            oldPasswordField.isSecureTextEntry = true
            oldPasswordSecure.tintColor = mainGrayColor
        }
    }
    
    @IBAction private func newPasswordSecureButtonPressed(_ sender: UIButton?) {
        
        if newPasswordField.isSecureTextEntry {
            newPasswordSecure.setImage(UIImage(named: "ic_show_password"), for: .normal)
            newPasswordField.isSecureTextEntry = false
            newPasswordSecure.tintColor = mainGreenColor
        } else {
            newPasswordSecure.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            newPasswordField.isSecureTextEntry = true
            newPasswordSecure.tintColor = mainGrayColor
        }
    }
    
    @IBAction private func saveButtonPressed(_ sender: UIButton) {
        
        guard oldPasswordField.text != "" || newPasswordField.text != "" else {
            return
        }
        
        guard (UserDefaults.standard.string(forKey: "pass") ?? "") == (oldPasswordField.text ?? "") else {
            wrongPassLabel.isHidden = false
            errorHeight.constant = 20
            return
        }
        startAnimator()
        changePass()
    }
    
    @IBAction private func forgotPassButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Segues.fromAccountChangePasswordVC.toForgot, sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewHeight.constant = 180
        saveButton.isHidden = true
        errorHeight.constant = 0
        wrongPassLabel.isHidden = true
        oldPasswordSecureButtonPressed(nil)
        newPasswordSecureButtonPressed(nil)
        self.oldPasswordIndicator.backgroundColor = .lightGray
        self.newPasswordIndicator.backgroundColor = .lightGray
        stopAnimator()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        oldPasswordField.delegate = self
        newPasswordField.delegate = self
        
//        if #available(iOS 10, *) {
//            // Disables the password autoFill accessory view.
//            oldPasswordField.textContentType = UITextContentType("")
//            newPasswordField.textContentType = UITextContentType("")
//        }
        
        oldPasswordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        newPasswordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        newPasswordField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: newPasswordField.frame.height))
        newPasswordField.rightViewMode = .always
        
        oldPasswordField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 18, height: oldPasswordField.frame.height))
        oldPasswordField.rightViewMode = .always
        
        activateSaveButton()
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        DispatchQueue.main.async{
            self.errorHeight.constant = 0
            self.wrongPassLabel.isHidden = true
            if textField == self.oldPasswordField{
                self.oldPasswordIndicator.backgroundColor = mainGreenColor
                self.newPasswordIndicator.backgroundColor = .lightGray
            }else{
                self.newPasswordIndicator.backgroundColor = mainGreenColor
                self.oldPasswordIndicator.backgroundColor = .lightGray
            }
        }
        activateSaveButton()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        DispatchQueue.main.async{
            if textField == self.oldPasswordField{
                self.oldPasswordIndicator.backgroundColor = mainGreenColor
                self.newPasswordIndicator.backgroundColor = .lightGray
            }else{
                self.newPasswordIndicator.backgroundColor = mainGreenColor
                self.oldPasswordIndicator.backgroundColor = .lightGray
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        DispatchQueue.main.async{
            self.oldPasswordIndicator.backgroundColor = .lightGray
            self.newPasswordIndicator.backgroundColor = .lightGray
        }
    }
    
    private func activateSaveButton() {
        DispatchQueue.main.async {
            if self.oldPasswordField.text == "" || self.newPasswordField.text == "" {
                self.saveButton.isHidden = true
                self.viewHeight.constant = 180
            } else {
                self.saveButton.isHidden = false
                self.viewHeight.constant = 256
            }
        }
    }
    
    private func changePass() {
        
        let login   = UserDefaults.standard.string(forKey: "login")?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let oldPass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.CHANGE_PASSWRD + "isChg=1&login=\(login)&pwd=\(newPasswordField.text ?? "")&oldPwd=\(oldPass)")!)
        request.httpMethod = "GET"
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
//            defer {
//                DispatchQueue.main.sync {
//                    UserDefaults.standard.setValue(self.newPasswordField.text ?? "", forKey: "pass")
//                    self.stopAnimator()
//                }
//            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                
                DispatchQueue.main.sync {
                    self.stopAnimator()
                    self.present(alert, animated: true, completion: nil)
                }
            
            } else {
                let alert = UIAlertController(title: nil, message: "Ваш пароль был успешно изменён!", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in self.navigationController?.popViewController(animated: true) }) )
                DispatchQueue.main.async {
                    let _ = self.getSalt(login: login)
                    UserDefaults.standard.setValue(self.newPasswordField.text ?? "", forKey: "pass")
                    UserDefaults.standard.synchronize()
                }
                
                DispatchQueue.main.sync {
                    
                    self.stopAnimator()
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            #if DEBUG
//                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        }.resume()
    }
    
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        //var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login.suffix(4))!)
        request.httpMethod = "GET"
        print(request)
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    //                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    //                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    //                    alert.addAction(cancelAction)
                    //                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            TemporaryHolder.instance.salt = data
            DispatchQueue.main.async {
                let pwd = getHash(pass: self.newPasswordField.text!, salt: salt!)
                UserDefaults.standard.setValue(pwd, forKey: "pwd")
                UserDefaults.standard.synchronize()
            }
            
            }.resume()
        return salt ?? Data()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromAccountChangePasswordVC.toForgot {
            let vc = segue.destination as! NewRegistration_Sminex
            vc.isReg_       = false
            vc.isFromApp_   = true
        }
    }
    
    private func startAnimator() {
        loader.isHidden = false
        loader.startAnimating()
        saveButton.isHidden = true
    }
    
    private func stopAnimator() {
        loader.stopAnimating()
        loader.isHidden = true
        saveButton.isHidden = false
    }
}







