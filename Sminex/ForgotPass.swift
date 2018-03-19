//
//  ForgotPass.swift
//  DemoUC
//
//  Created by Роман Тузин on 16.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class ForgotPass: UIViewController, UITextFieldDelegate {
    // Картинки на подмену
    @IBOutlet weak var fon_top: UIImageView!
    @IBOutlet weak var new_face: UIImageView!
    
    var letter: String = ""
    var responseString:NSString = ""
    
    @IBOutlet weak var FogLogin: UITextField!
    @IBOutlet weak var btnFogrot: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var ls:String = ""
    // признак того, вводим мы телефон или нет
    var itsPhone: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FogLogin.delegate = self
        
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        StopIndicator()
        
        let theTap = UITapGestureRecognizer(target: self, action: #selector(self.ViewTapped(recognizer:)))
        view.addGestureRecognizer(theTap)
        
        FogLogin.text = letter
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            fon_top.image               = UIImage(named: "fon_top_gkrzs")
            new_face.image              = UIImage(named: "new_face_gkrzs")
            btnFogrot.backgroundColor    = server.hexStringToUIColor(hex: "#1f287f")
            btnCancel.tintColor            = server.hexStringToUIColor(hex: "#c0c0c0")
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func ViewTapped(recognizer: UIGestureRecognizer) {
        view.endEditing(true)
    }    
    
    @IBAction func ForgetPass(_ sender: UIButton) {
        
        StartIndicator()
        
        let urlPath = Server.SERVER + Server.FORGOT + "login=" + FogLogin.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let url: NSURL = NSURL(string: urlPath)!
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    let alert = UIAlertController(title: "Результат", message: "Не удалось. Попробуйте позже", preferredStyle: UIAlertControllerStyle.alert)
                                                    alert.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.default, handler: nil))
                                                    self.present(alert, animated: true, completion: nil)
                                                    self.responseString = "xxx";
                                                    self.choice()
                                                    return
                                                }
                                                
                                                self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                                                print("responseString = \(self.responseString)")
                                                
                                                self.choice()
                                                
        })
        
        task.resume()
        
    }
    
    func choice(){
        if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не указан лицевой счет", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "2") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Некорректные данные", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString.length > 150) {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Ошибка сервера. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "xxx") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
            })
        } else {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Успешно", message: "Пароль отправлен на почту - " + (self.responseString as String), preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    func StartIndicator(){
        self.btnFogrot.isHidden = true
        self.btnCancel.isHidden = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator(){
        self.btnFogrot.isHidden = false
        self.btnCancel.isHidden = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
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
