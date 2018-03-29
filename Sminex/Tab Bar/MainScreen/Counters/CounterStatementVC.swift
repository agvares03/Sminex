//
//  CounterStatementVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/28/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

protocol CounterStatementDelegate: class {
    func update()
}

final class CounterStatementVC: UIViewController {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var goButtonConst:   NSLayoutConstraint!
    @IBOutlet private weak var count:           DigitInputView!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var numStack:        UIStackView!
    @IBOutlet private weak var goButton:        UIButton!
    @IBOutlet private weak var monthValLabel:   UILabel!
    @IBOutlet private weak var counterLabel:    UILabel!
    @IBOutlet private weak var outcomeLabel:    UILabel!
    @IBOutlet private weak var monthLabel:      UILabel!
    @IBOutlet private weak var descLabel1:      UILabel!
    @IBOutlet private weak var descLabel2:      UILabel!
    @IBOutlet private weak var dateLabel:       UILabel!
    @IBOutlet private weak var typeLabel:       UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        startAnimator()
        sendCount()
    }
    
    open var month_: String?
    open var date_: String?
    open var value_: MeterValue?
    open weak var delegate: CounterStatementDelegate?
    
    private var responseString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        
        count.numberOfDigits = 4
        count.bottomBorderColor = .clear
        count.nextDigitBottomBorderColor = .clear
        count.backColor = UIColor(white: 96/100, alpha: 1.0)
        count.font = UIFont.systemFont(ofSize: 17, weight: .thin)
        
        if value_?.fractionalNumber?.contains(find: "alse") ?? true {
            
            print("1234567890")
            
            count.acceptableCharacters = "1234567890"
        
        } else {
            print("1234567890.")
            
            count.acceptableCharacters = "1234567890."
            
            descLabel1.isHidden = true
            descLabel2.isHidden = true
            goButtonConst.constant = 20
        }
        
        dateLabel.text = date_
        typeLabel.text = value_?.resource
        counterLabel.text = value_?.meterUniqueNum
        monthValLabel.text = value_?.value
        monthLabel.text = month_
        navigationController?.title = "Показания за " + month_!
        
        let intVal = Int(value_?.value ?? "0") ?? 0
        let prevIntVal = Int(value_?.previousValue ?? "0") ?? 0
        
        outcomeLabel.text = String(intVal - prevIntVal) + " " + (value_?.units)! + "/мес."
        
        stopAnimator()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        if isNeedToScroll() {
            scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height + 240.0)
            scroll.contentOffset = CGPoint(x: 0, y: 140)
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if isNeedToScroll() {
            scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height - 240.0)
            scroll.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    // Передача показаний
    private func sendCount() {
        if count.text != "" && count.text.last != "." {
            
            let edLogin = UserDefaults.standard.string(forKey: "login") ?? ""
            let edPass = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: edLogin))
            
            var strNumber = value_?.meterUniqueNum ?? ""
            
            let urlPath = Server.SERVER + Server.ADD_METER
                + "login=" + edLogin.stringByAddingPercentEncodingForRFC3986()!
                + "&pwd=" + edPass
                + "&meterID=" + strNumber.stringByAddingPercentEncodingForRFC3986()!
                + "&val=" + count.text.stringByAddingPercentEncodingForRFC3986()!
            
            var request = URLRequest(url: URL(string: urlPath)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                defer {
                    DispatchQueue.main.async {
                        self.stopAnimator()
                    }
                }
                
                if error != nil {
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    })
                    return
                }
                
                self.responseString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choice()
                
                }.resume()
        
        } else {
            self.stopAnimator()
        }
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        request.httpMethod = "GET"
        
        queue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            defer {
                queue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            salt = data
            
            #if DEBUG
                print("salt is = \(String(describing: String(data: data!, encoding: .utf8)))")
            #endif
            
            }.resume()
        
        queue.wait()
        return salt!
    }
    
    private func choice() {
        DispatchQueue.main.async {
            
            if self.responseString == "0" {
                let alert = UIAlertController(title: "Ошибка", message: "Переданы не все параметры. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "1" {
                let alert = UIAlertController(title: "Ошибка", message: "Не пройдена авторизация. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "2" {
                let alert = UIAlertController(title: "Ошибка", message: "Не найден прибор у пользователя. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "3" {
                let alert = UIAlertController(title: "Ошибка", message: "Передача показаний невозможна.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "5" {
                self.delegate?.update()
                self.monthValLabel.text = String(describing: Int(self.count.text)!)
                self.count.textField?.text = ""
                self.count.setup()
            }
        }
    }
    
    private func startAnimator() {
        goButton.isHidden   = true
        loader.isHidden     = false
        loader.startAnimating()
    }
    
    private func stopAnimator() {
        goButton.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
    }
}
