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

final class CounterStatementVC: UIViewController, CounterDelegate {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var goBottomConst:   NSLayoutConstraint!
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
    @IBOutlet private weak var dateLabel:       UILabel!
    @IBOutlet private weak var typeLabel:       UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        startAnimator()
        sendCount()
    }
    
    open var period_: [CounterPeriod]?
    
    open var month_:        String?
    open var year_:         String?
    open var date_:         String?
    open var value_:        MeterValue?
    open weak var delegate: CounterStatementDelegate?
    
    private var responseString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        automaticallyAdjustsScrollViewInsets = false
        
        count.bottomBorderColor = .clear
        count.nextDigitBottomBorderColor = .clear
        count.backColor = UIColor(red: 241/255, green: 241/255, blue: 241/255, alpha: 1.0)
        count.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        
//        if value_?.resource?.contains(find: "лектроэнергия") ?? false {
//            count.isEnergy = true
//            count.numberOfDigits = 6
//            count.acceptableCharacters = "1234567890"
        
//        } else {
        
            if value_?.fractionalNumber?.contains(find: "alse") ?? true {
                count.isEnergy = true
                count.numberOfDigits = 6
                count.acceptableCharacters = "1234567890"
                
            } else {
                count.acceptableCharacters = "1234567890,"
                count.numberOfDigits = 9
                descLabel1.text = "Реальное показание 00012345.678 --> необходимо ввести как 12345.678"
//                goButtonConst.constant = 20
            }
//        }
        goButton.isEnabled = false
        goButton.alpha     = 0.5
        count.delegate     = self
        
        // Выведем текущую дату в формате
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: date as Date)
        
        dateLabel.text = dateString //date_?.lowercased()
        typeLabel.text = value_?.resource
        counterLabel.text = "Счетчик " + (value_?.meterUniqueNum)!
        // Округлим прошлое показание счетчика
        let round_value = value_?.previousValue?.replacingOccurrences(of: ",00", with: "")
        monthValLabel.text = round_value
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        monthLabel.text = getMonth(date: previousMonth!)   // month_
//        navigationController?.title = "Показания за " + month_! + " " + year_!
        self.title = "Показания за " + month_! + " " + year_!
        
        outcomeLabel.text = "\(value_?.difference?.replacingOccurrences(of: ",00", with: "") ?? "0") \(value_?.units ?? "")"
        //outcomeLabel.text = "\(value_?.difference?.replacingOccurrences(of: ",00", with: "") ?? "0") \(value_?.units ?? "")/мес."
        
        stopAnimator()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        let _ = count.becomeFirstResponder()
        
//        count.textField?.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        var metValues: [MeterValue] = []
        
        period_?.forEach { period in
            
            guard period.year == period_?.first?.year else { return }
            period.perXml["MeterValue"].forEach {
                let val = MeterValue($0, period: period.numMonth ?? "1")
                if val.meterUniqueNum == value_?.meterUniqueNum {
                    metValues.append(val)
                    
                }
            }
        }
        
        metValues.forEach {
            if Float($0.value?.replacingOccurrences(of: ",", with: ".") ?? "0")! > Float(0) {
                monthValLabel.text = $0.value
                return
            }
        }
        
        
        
    }
    
    func getMonth(date: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        let str_date = formatter.string(from: date as Date)
        return get_strMonth(str_date: str_date)
    }
    
    func get_strMonth(str_date: String) -> String {
        if (str_date == "01") {
            return "Январь"
        } else if (str_date == "02") {
            return "Февраль"
        } else if (str_date == "03") {
            return "Март"
        } else if (str_date == "04") {
            return "Апрель"
        } else if (str_date == "05") {
            return "Май"
        } else if (str_date == "06") {
            return "Июнь"
        } else if (str_date == "07") {
            return "Июль"
        } else if (str_date == "08") {
            return "Август"
        } else if (str_date == "09") {
            return "Сентябрь"
        } else if (str_date == "10") {
            return "Октябрь"
        } else if (str_date == "11") {
            return "Ноябрь"
        } else if (str_date == "12") {
            return "Декабрь"
        }
        return ""
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        
        if count.text == "" {
            goButton.isEnabled = false
            goButton.alpha     = 0.5
        
        } else {
            goButton.isEnabled = true
            goButton.alpha     = 1
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        tabBarController?.tabBar.selectedItem?.title = "Главная"
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        
        if isNeedToScrollMore() {
            scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height + 240.0)
            scroll.contentOffset = CGPoint(x: 0, y: 50)
        
        } else {
//            if isNeedToScroll() {
//                goBottomConst.constant = 215
//            }
            scroll.contentInset.bottom = 265
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if isNeedToScrollMore() {
            scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height - 240.0)
            scroll.contentOffset = CGPoint(x: 0, y: 0)
        
        } else {
//            if isNeedToScroll() {
//                goBottomConst.constant = 8
//            }
            scroll.contentInset.bottom = 0
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    // Передача показаний
    private func sendCount() {
        if count.text != "" && count.text.last != "," {
            
            let edLogin = UserDefaults.standard.string(forKey: "login") ?? ""
            let edPass = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt())
            
            var strNumber = value_?.guid ?? ""
            
            
            print("###: ")
            print(count.text.stringByAddingPercentEncodingForRFC3986()!)
            let newCount = count.text.replacingOccurrences(of: ",", with: ".")
            
            let urlPath = Server.SERVER + Server.ADD_METER
                + "login=" + edLogin.stringByAddingPercentEncodingForRFC3986()!
                + "&pwd=" + edPass
                + "&meterID=" + strNumber.stringByAddingPercentEncodingForRFC3986()!
                + "&val=" + newCount
            
            var request = URLRequest(url: URL(string: urlPath)!)
            request.httpMethod = "GET"
            
            print(request.url)
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                defer {
                    DispatchQueue.main.async {
                        self.stopAnimator()
                        self.navigationController?.popViewController(animated: true)
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
                let newCount1 = self.count.text.replacingOccurrences(of: ",", with: ".")
                print(self.count.text)
                self.monthValLabel.text    = (self.self.value_?.fractionalNumber?.contains(find: "alse") ?? true)
                                                ? String(describing: Int(newCount1)!)
                                                : String(describing: Float(newCount1)!)
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
