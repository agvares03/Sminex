//
//  AccountChangePasswordVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/6/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class AccountChangePasswordVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet private weak var oldPasswordField:    UITextField!
    @IBOutlet private weak var newPasswordField:    UITextField!
    @IBOutlet private weak var saveButton:          UIButton!
    @IBOutlet private weak var oldPasswordSecure:   UIButton!
    @IBOutlet private weak var newPasswordSecure:   UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func oldPasswordSecureButtonPressed(_ sender: UIButton) {
        
        if oldPasswordField.isSecureTextEntry {
            oldPasswordSecure.setImage(UIImage(named: "ic_show_password"), for: .normal)
            oldPasswordField.isSecureTextEntry = false
            
        } else {
            oldPasswordSecure.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            oldPasswordField.isSecureTextEntry = true
        }
    }
    
    @IBAction private func newPasswordSecureButtonPressed(_ sender: UIButton) {
        
        if newPasswordField.isSecureTextEntry {
            newPasswordSecure.setImage(UIImage(named: "ic_show_password"), for: .normal)
            newPasswordField.isSecureTextEntry = false
            
        } else {
            newPasswordSecure.setImage(UIImage(named: "ic_not_show_password"), for: .normal)
            newPasswordField.isSecureTextEntry = true
        }
    }
    
    @IBAction private func saveButtonPressed(_ sender: UIButton) {
        
        let alert = UIAlertController(title: nil, message: "Ваш пароль был успешно изменён!", preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in self.navigationController?.popViewController(animated: true) }) )
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func forgotPassButtonPressed(_ sender: UIButton) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        oldPasswordField.delegate = self
        newPasswordField.delegate = self
        
        oldPasswordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        newPasswordField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        activateSaveButton()
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        activateSaveButton()
    }
    
    private func activateSaveButton() {
        
        if oldPasswordField.text == "" || newPasswordField.text == "" {
            saveButton.isEnabled    = false
            saveButton.alpha        = 0.5
        
        } else {
            saveButton.isEnabled    = true
            saveButton.alpha        = 1
        }
    }
}







