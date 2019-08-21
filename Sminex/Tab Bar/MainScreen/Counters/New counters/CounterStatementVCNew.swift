//
//  CounterStatementVCNew.swift
//  Sminex
//
//  Created by Sergey Ivanov on 02/08/2019.
//

import UIKit

class CounterStatementVCNew: UIViewController, CounterDelegate {
    
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
    @IBOutlet private weak var pager:           UIPageControl!
    @IBOutlet private weak var tarifText:       UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        if index == (Int(kolTarif!)! - 1){
            if count.text != "" && count.text.last != ","{
                print(index)
                allValue![index] = count.text
            }
            goButton.setTitle("Передать показания", for: .normal)
            goButton.isEnabled = true
            goButton.alpha     = 1
            startAnimator()
            sendCount()
        }else{
            if index < Int(kolTarif!)! - 1{
                index += 1
                loader.isHidden = true
                counterLabel.text = "Счетчик " + (value_?.meterUniqueNum)!
                typeLabel.text = value_?.resource
                var round_value = value_?.previousValue1?.replacingOccurrences(of: ",00", with: "")
                if index == 1{
                    round_value = value_?.previousValue2?.replacingOccurrences(of: ",00", with: "")
                }else if index == 2{
                    round_value = value_?.previousValue3?.replacingOccurrences(of: ",00", with: "")
                }
                if count.text != "" && count.text.last != ","{
                    allValue![index - 1] = count.text
                }
                monthValLabel.text = round_value
                pager.currentPage = index
                count.textField?.text = allValue![index]
                count.setup()
                if index == Int(kolTarif!)! - 1{
                    goButton.setTitle("Передать показания", for: .normal)
                    goButton.isEnabled = true
                    goButton.alpha     = 1
                }
            }
        }
    }
    
    @IBAction func SwipeRight(_ sender: UISwipeGestureRecognizer) {
        if index > 0{
            index -= 1
            counterLabel.text = "Счетчик " + (value_?.meterUniqueNum)!
            typeLabel.text = value_?.resource
            var round_value = value_?.previousValue1?.replacingOccurrences(of: ",00", with: "")
            tarifText.text = value_?.tarifName1
            if index == 1{
                round_value = value_?.previousValue2?.replacingOccurrences(of: ",00", with: "")
                tarifText.text = value_?.tarifName2
            }else if index == 2{
                round_value = value_?.previousValue3?.replacingOccurrences(of: ",00", with: "")
                tarifText.text = value_?.tarifName3
            }
            if count.text != "" && count.text.last != ","{
                allValue![index + 1] = count.text
            }
            monthValLabel.text = round_value
            pager.currentPage = index
            count.textField?.text = allValue![index]
            count.setup()
        }
    }
    
    @IBAction func SwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if index < Int(kolTarif!)! - 1{
            index += 1
            loader.isHidden = true
            counterLabel.text = "Счетчик " + (value_?.meterUniqueNum)!
            typeLabel.text = value_?.resource
            var round_value = value_?.previousValue1?.replacingOccurrences(of: ",00", with: "")
            tarifText.text = value_?.tarifName1
            if index == 1{
                round_value = value_?.previousValue2?.replacingOccurrences(of: ",00", with: "")
                tarifText.text = value_?.tarifName2
            }else if index == 2{
                round_value = value_?.previousValue3?.replacingOccurrences(of: ",00", with: "")
                tarifText.text = value_?.tarifName3
            }
            if count.text != "" && count.text.last != ","{
                allValue![index - 1] = count.text
            }
            monthValLabel.text = round_value
            pager.currentPage = index
            count.textField?.text = allValue![index]
            count.setup()
            if index == Int(kolTarif!)! - 1{
                goButton.setTitle("Передать показания", for: .normal)
                goButton.isEnabled = true
                goButton.alpha     = 1
            }
        }
    }
    
    public var period_: [CounterPeriod]?
    
    public var month_:        String?
    public var year_:         String?
    public var date_:         String?
    public var value_:        MeterValue?
    var allValue: [String]? = []
    var index:Int = 0
    public var kolTarif: String?
    public weak var delegate: CounterStatementDelegate?
    
    private var responseString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        
        automaticallyAdjustsScrollViewInsets = false
        if kolTarif == ""{
            kolTarif = "1"
        }
        if allValue?.count == 0{
            for _ in 0...Int(kolTarif!)! - 1{
                allValue?.append("")
            }
        }
        if Int(kolTarif!)! > 1{
            goButton.setTitle("Далее", for: .normal)
            tarifText.text = value_?.tarifName1
        }else{
            tarifText.isHidden = true
        }
        pager.numberOfPages = Int(kolTarif!)!
        if pager.numberOfPages == 1 || pager.numberOfPages == 0{
            pager.isHidden = true
        }
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
        if !UserDefaults.standard.bool(forKey: "didntSchet"){
            goButton.isHidden = true
        }
        if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
            goButton.isHidden = UserDefaults.standard.bool(forKey: "onlyViewMeterReadings")
        }
        count.delegate     = self as CounterDelegate
        
        // Выведем текущую дату в формате
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: date as Date)
        
        dateLabel.text = dateString //date_?.lowercased()
        typeLabel.text = value_?.resource
        counterLabel.text = "Счетчик " + (value_?.meterUniqueNum)!
        // Округлим прошлое показание счетчика
        let round_value = value_?.previousValue1?.replacingOccurrences(of: ",00", with: "")
        monthValLabel.text = round_value
        let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())
        monthLabel.text = getMonth(date: previousMonth!)   // month_
        //        navigationController?.title = "Показания за " + month_! + " " + year_!
        self.title = "Показания за " + month_! + " " + year_!
        
        outcomeLabel.text = "\(value_?.difference1?.replacingOccurrences(of: ",00", with: "") ?? "0") \(value_?.units ?? "")"
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
        print(metValues)
        var a = [String]()
        metValues.forEach {
            if Float($0.value1?.replacingOccurrences(of: ",", with: ".") ?? "0")! > Float(0) {
                a.append($0.value1!)
                return
            }
        }
        if a.count > 1{
            monthValLabel.text = a[1]
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
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.updateUserInterface()
                //                self.viewDidLoad()
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
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
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
        print(allValue)
        if allValue?[index] != "" {
            
            let edLogin = UserDefaults.standard.string(forKey: "login") ?? ""
            let edPass = UserDefaults.standard.string(forKey: "pwd") ?? ""
            
            var strNumber = value_?.guid ?? ""
            
            //            print("###: ",count.text.stringByAddingPercentEncodingForRFC3986()!)
            let newCount = count.text.replacingOccurrences(of: ",", with: ".")
            var val1 = allValue?[0]
            var val2 = ""
            var val3 = ""
            var urlPath = Server.SERVER + Server.ADD_METER
                + "login=" + edLogin.stringByAddingPercentEncodingForRFC3986()!
                + "&pwd=" + edPass
                + "&meterID=" + strNumber.stringByAddingPercentEncodingForRFC3986()!
                + "&val=" + val1!.replacingOccurrences(of: ",", with: ".").stringByAddingPercentEncodingForRFC3986()!
            if kolTarif == "2"{
                var val2 = allValue?[1]
                urlPath = urlPath + "&val2=" + val2!.replacingOccurrences(of: ",", with: ".").stringByAddingPercentEncodingForRFC3986()!
            }else if kolTarif == "3"{
                var val2 = allValue?[1]
                var val3 = allValue?[2]
                urlPath = urlPath + "&val2=" + val2!.replacingOccurrences(of: ",", with: ".").stringByAddingPercentEncodingForRFC3986()! + "&val3=" + val3!.replacingOccurrences(of: ",", with: ".").stringByAddingPercentEncodingForRFC3986()!
            }
            var request = URLRequest(url: URL(string: urlPath)!)
            request.httpMethod = "GET"
            print(request)
            
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
                
                self.choice()//89955029865
                
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
                //                print(self.count.text)
                self.monthValLabel.text    = (self.self.value_?.fractionalNumber?.contains(find: "alse") ?? true)
                    ? String(describing: Int(newCount1)!)
                    : String(describing: Float(newCount1)!)
                self.count.textField?.text = ""
                self.count.setup()
                let alert = UIAlertController(title: "Показания успешно приняты", message: "", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    self.navigationController?.popViewController(animated: true)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
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
        if !UserDefaults.standard.bool(forKey: "didntSchet"){
            goButton.isHidden = true
        }
        if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
            goButton.isHidden   = true
        }
        loader.stopAnimating()
        loader.isHidden = true
    }
}
