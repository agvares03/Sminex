//
//  Registration_Sminex.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

extension String {
    
    var length: Int {
        return self.characters.count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
    
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
}

class Registration_Sminex: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var edLS: UITextField!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var btn_go: UIButton!
    @IBOutlet weak var txtDesc: UILabel!
    
    var responseString:NSString = ""
    
    var ls:String = ""
    // признак того, вводим мы телефон или нет
    var itsPhone: Bool = false
    
    @IBAction func btn_go_action(_ sender: UIButton) {
        
        if (edLS.text != "") {
            self.startAnimation()
            // здесь мы проверяем есть ли лиц. счет или номер телефона
            // Если нет лиц. счета -                 txtDesc = "Лицевой счет " + edLS + " не зарегистрирован".
            // Если нет телефона у лиц. счета -      txtDesc = "По лицевому счету " + edLS + " не обнаружен привязанный телефон".
            // Если указанный телефон не обнаружен - txtDesc = "Телефон " + edLS + " не привязан ни к одному лицевому счету".
            // Если все ок - переходим на страницу ввода кода смс
            registration()
        } else {
            let alert = UIAlertController(title: "Ошибка", message: "Укажите лиц. счет или номер телефона, привязанного к лиц. счету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func btn_cancel(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    func registration() {
        var ls_for_zapros = ls.replacingOccurrences(of: "+", with: "")
        ls_for_zapros = ls.replacingOccurrences(of: " ", with: "")
        if (itsPhone) {
            ls_for_zapros = "7" + ls_for_zapros.substring(fromIndex: 1)
        }
        let urlPath = Server.SERVER + Server.REGISTRATION_SMINEX + "identOrPhone=" + ls_for_zapros
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
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
                                                
                                                self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                                                print("responseString = \(self.responseString)")
                                                
                                                self.choice_reg()
        })
        task.resume()
        
    }
    
    func choice_reg() {
        if (responseString.contains("error")) {
            DispatchQueue.main.async(execute: {
                self.stopAnimation()
                let alert = UIAlertController(title: "Ошибка", message: self.responseString.replacingOccurrences(of: "error: ", with: ""), preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString.contains("ok")) {
            DispatchQueue.main.async(execute: {
                self.stopAnimation()
                
                let vc  = self.storyboard?.instantiateViewController(withIdentifier: "registration_sminex_sms") as!  Registration_Sminex_SMS
                if (self.itsPhone) {
                    vc.number_phone = self.edLS.text!
                    vc.number_ls = ""
                } else {
                    vc.number_phone = ""
                    vc.number_ls = self.edLS.text!
                }
                self.present(vc, animated: true, completion: nil)
                
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edLS.delegate = self;
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        edLS.text = ls
        indicator.isHidden = true
                
    }
    
    func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }
    
    func startAnimation() {
        indicator.isHidden = false
        indicator.startAnimating()
        
        btn_go.isHidden = true
    }
    
    func stopAnimation() {
        indicator.isHidden = true
        indicator.stopAnimating()
        
        btn_go.isHidden = false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        
        if (string == "") {
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
        var first: Bool = true
        var ls_1_end = ""
        if (ls.characters.count < 1) {
            ls_1_end = ""
        } else {
            let ls_1 = ls.index(ls.startIndex, offsetBy: 1)
            ls_1_end = ls.substring(to: ls_1)
        }
        
        var ls_12_end = ""
        if (ls.characters.count < 2) {
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
        
        var new_ls: String = ""
        first = true
        var j: Int = 1
        for character in ls {
            if (first) {
                new_ls = String(character)
                first = false
            } else {
                if (itsPhone) {
                    if (ls_1_end == "+") {
                        if (j == 2) {
                            new_ls = new_ls + String(character)
                        } else if (j == 3) {
                            new_ls = new_ls + "(" + String(character)
                        } else if (j == 4) {
                            new_ls = new_ls + String(character)
                        } else if (j == 5) {
                            new_ls = new_ls + String(character) + ")"
                        } else if (j == 6) {
                            new_ls = new_ls + String(character)
                        } else if (j == 7) {
                            new_ls = new_ls + String(character)
                        } else if (j == 8) {
                            new_ls = new_ls + String(character)
                        } else if (j == 9) {
                            new_ls = new_ls + "-" + String(character)
                        } else if (j == 10) {
                            new_ls = new_ls + String(character)
                        } else if (j == 11) {
                            new_ls = new_ls + "_" + String(character)
                        } else if (j == 12) {
                            new_ls = new_ls + String(character)
                        } else {
                            new_ls = new_ls + String(character)
                        }
                    } else {
                        if (j == 2) {
                            new_ls = new_ls + "(" + String(character)
                        } else if (j == 3) {
                            new_ls = new_ls + String(character)
                        } else if (j == 4) {
                            new_ls = new_ls + String(character) + ")"
                        } else if (j == 5) {
                            new_ls = new_ls + String(character)
                        } else if (j == 6) {
                            new_ls = new_ls + String(character)
                        } else if (j == 7) {
                            new_ls = new_ls + String(character)
                        } else if (j == 8) {
                            new_ls = new_ls + "-" + String(character)
                        } else if (j == 9) {
                            new_ls = new_ls + String(character)
                        } else if (j == 10) {
                            new_ls = new_ls + "-" + String(character)
                        } else if (j == 11) {
                            new_ls = new_ls + String(character)
                        } else {
                            new_ls = new_ls + String(character)
                        }
                    }
                } else {
                    new_ls = new_ls + String(character)
                }
            }
            j = j + 1
        }
        
        if (itsPhone) {
            if (ls_1_end == "+") {
                if (j == 2) {
                    new_ls = new_ls + "*(***)***-**-**"
                } else if (j == 3) {
                    new_ls = new_ls + "(***)***-**-**"
                } else if (j == 4) {
                    new_ls = new_ls + "**)***-**-**"
                } else if (j == 5) {
                    new_ls = new_ls + "*)***-**-**"
                } else if (j == 6) {
                    new_ls = new_ls + "***-**-**"
                } else if (j == 7) {
                    new_ls = new_ls + "**-**-**"
                } else if (j == 8) {
                    new_ls = new_ls + "*-**-**"
                } else if (j == 9) {
                    new_ls = new_ls + "-**-**"
                } else if (j == 10) {
                    new_ls = new_ls + "*-**"
                } else if (j == 11) {
                    new_ls = new_ls + "-**"
                } else if (j == 12) {
                    new_ls = new_ls + "*"
                }
            } else {
                if (j == 3) {
                    new_ls = new_ls + "**)***-**-**"
                } else if (j == 4) {
                    new_ls = new_ls + "*)***-**-**"
                } else if (j == 5) {
                    new_ls = new_ls + "***-**-**"
                } else if (j == 6) {
                    new_ls = new_ls + "**-**-**"
                } else if (j == 7) {
                    new_ls = new_ls + "*-**-**"
                } else if (j == 8) {
                    new_ls = new_ls + "-**-**"
                } else if (j == 9) {
                    new_ls = new_ls + "*-**"
                } else if (j == 10) {
                    new_ls = new_ls + "-**"
                } else if (j == 11) {
                    new_ls = new_ls + "*"
                }
            }
        }
        
        textField.text = new_ls
        
        // Установим курсор, если это телефон
        if (itsPhone) {
            var jj = j
            if (ls_1_end == "+") {
                if (j == 2) {
                    jj = 1
                }
                if (j > 5) {
                    jj = j + 1
                }
                if (j > 8) {
                    jj = j + 2
                }
                if (j > 10) {
                    jj = j + 3
                }
            } else {
                if (j > 4) {
                    jj = j + 1
                }
                if (j > 7) {
                    jj = j + 2
                }
                if (j > 9) {
                    jj = j + 3
                }
            }
            if let newPosition = textField.position(from: textField.beginningOfDocument, offset: jj) {
                textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
            }
        }
        
        // Установим тип - для номера телефона - только цифры
        if (itsPhone) {
            textField.keyboardType = UIKeyboardType.phonePad
        } else {
            textField.keyboardType = UIKeyboardType.default
        }
        textField.reloadInputViews()
        
        return false
        
    }
    
}
