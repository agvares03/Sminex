//
//  RegistrationSminexEnterPassword.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class RegistrationSminexEnterPassword: UIViewController {
    
    @IBOutlet private weak var saveButton:      UIButton!
    @IBOutlet private weak var passTextField:   UITextField!
    @IBOutlet private weak var descTxt:         UILabel!
    
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
    
    open var login_ = ""
    
    private var responceString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    private func startAnimation() {
        
    }
    
    private func stopAnimation() {
        
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
