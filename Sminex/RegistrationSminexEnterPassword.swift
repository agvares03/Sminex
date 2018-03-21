//
//  RegistrationSminexEnterPassword.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import DeviceKit

final class RegistrationSminexEnterPassword: UIViewController {
    
    @IBOutlet private weak var saveButton:      UIButton!
    @IBOutlet private weak var passTextField:   UITextField!
    @IBOutlet private weak var descTxt:         UILabel!
    @IBOutlet private weak var showpswrd:       UIButton!
    @IBOutlet private weak var waitView:        UIActivityIndicatorView!
    
    @IBAction private func saveButtonPressed(_ sender: UIButton!) {
        
        guard (passTextField.text?.count ?? 0) > 0 else {
            
            descTxt.textColor = .red
            descTxt.text = "Заполните поле"
            
            return
        }
        
        startAnimation()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.CHANGE_PASSWRD + "login=" + login_ + "&pwd=" + passTextField.text!)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                
                DispatchQueue.main.async(execute: {
                    self.stopAnimation()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                })
                return
            }
            
            self.responceString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                print(self.responceString)
            #endif
            
            DispatchQueue.main.async {
                
                self.choise()
            }
        }.resume()
    }
    
    @IBAction private func backButtonPressed(_ sender: UIButton) {
        let viewControllers = navigationController?.viewControllers
        navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
    }
    
    @IBAction private func showPasswordPressed(_ sender: UIButton) {
        
        if passTextField.isSecureTextEntry {
            
            showpswrd.setImage(UIImage(named: "ic_show_password"), for: .normal)
            passTextField.isSecureTextEntry = false
        } else {
            
            showpswrd.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            passTextField.isSecureTextEntry = true
        }
    }
    
    open var login_ = ""
    
    private var responceString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopAnimation()
        passTextField.isSecureTextEntry = false
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
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
            
            self.view.frame.origin.y = -50
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
    
    private func startAnimation() {
        
        saveButton.isHidden = true
        waitView.isHidden = false
        
        waitView.startAnimating()
    }
    
    private func stopAnimation() {
        
        saveButton.isHidden = false
        waitView.isHidden = true
        
        waitView.stopAnimating()
    }
    
    private func choise() {
        
        self.stopAnimation()
        
        if responceString.contains(find: "error") {
            descTxt.text = responceString.replacingOccurrences(of: "error:", with: "")
            descTxt.textColor = .red
        
        } else {
            
            performSegue(withIdentifier: "backToLogin", sender: self)
        }
    }
}
