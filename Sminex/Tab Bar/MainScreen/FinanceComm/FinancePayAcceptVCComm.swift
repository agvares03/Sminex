//
//  FinancePayAcceptVCComm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 18/07/2019.
//

import UIKit
import AKMaskField

class FinancePayAcceptVCComm: UIViewController, UITextFieldDelegate {
    
    @IBOutlet private weak var offerLabel:  UILabel!
    @IBOutlet private weak var fieldTop:    NSLayoutConstraint!
    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var sendButton:  UIButton!
    @IBOutlet private weak var choicePhoneBtn:  UIButton!
    @IBOutlet private weak var choiceEmailBtn:  UIButton!
    @IBOutlet private weak var iconPhone:  UIImageView!
    @IBOutlet private weak var iconEmail:  UIImageView!
    @IBOutlet private weak var phoneEmailText:    AKMaskField!
    @IBOutlet private weak var sumTextField:    UITextField!
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
    
    @IBAction private func infoButtonPressed(_ sender: UIButton) {
        url = URLRequest(url: URL(string: "http://client.sminex.com/_layouts/BusinessCenters.Branding/Payments/PaymentDescriptionMobile.aspx")!)
        performSegue(withIdentifier: Segues.fromFinancePayAcceptVC.toPay, sender: self)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        startAnimation()
        sumText = sumTextField.text ?? ""
        if Double(sumText) != nil{
            if Double(sumText)! > 0.00{
                DispatchQueue.global(qos: .userInitiated).async {
                    self.requestPay()
                }
            }else{
                DispatchQueue.main.async{
                    let alert = UIAlertController(title: "Ошибка", message: "Сумма к оплате равна нулю!", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    self.stopAnimation()
                }
            }
        }else{
            DispatchQueue.main.async{
                let alert = UIAlertController(title: "Ошибка", message: "Сумма к оплате равна нулю!", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                self.stopAnimation()
            }
        }
    }
    var phoneChoice = true
    var emailChoice = false
    @IBAction private func phonePressed(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.iconPhone.isHidden = false
            self.iconEmail.isHidden = true
            self.phoneEmailText.maskExpression = "+7 ({ddd}) {ddd}-{dddd}"
            self.phoneEmailText.maskTemplate = "*"
            self.phoneEmailText.keyboardType = .phonePad
            self.phoneEmailText.reloadInputViews()
            self.phoneEmailText.placeholder = "Контактный номер для отправки чека"
            self.phoneChoice = true
            self.emailChoice = false
        }
    }
    
    @IBAction private func emailPressed(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.iconPhone.isHidden = true
            self.iconEmail.isHidden = false
            self.phoneEmailText.maskExpression = "{...........................................}"
            self.phoneEmailText.maskTemplate = " "
            self.phoneEmailText.keyboardType = .emailAddress
            self.phoneEmailText.reloadInputViews()
            self.phoneEmailText.placeholder = "Email для отправки чека"
            self.phoneChoice = false
            self.emailChoice = true
        }
    }
    
    public var accountData_: AccountDebtJson?
    public var billsData_: AccountBillsJson?
    private var url: URLRequest!
    private var str_url: String!
    private var sumText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        stopAnimation()
        sumTextField.delegate = self
        title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"
        
        if accountData_ != nil && billsData_ != nil {
            sumTextField.text = String(format: "%.2f", (accountData_?.sumPay ?? 0.0))
            titleLabel.text = "Платеж для Лицевого счета №\(billsData_?.number ?? "")"
            var date = accountData_?.datePay
            if (date?.count ?? 0) > 9 {
                date?.removeLast(9)
            }
            descLabel.text = "\(billsData_?.number ?? "") от \(date ?? "")"
            
        }else if billsData_ != nil {
            sumTextField.text = String(format: "%.2f", (billsData_?.sum ?? 0.0) - (billsData_?.payment_sum ?? 0.0))
            titleLabel.text = "Платеж для Лицевого счета №\(billsData_?.number ?? "")"
            var date = billsData_?.datePay
            if (date?.count ?? 0) > 9 {
                date?.removeLast(9)
            }
            descLabel.text = "\(billsData_?.number ?? "") от \(date ?? "")"
            
        } else {
            sumTextField.text = String(format: "%.2f", (accountData_?.sumPay ?? 0.0))
            titleLabel.text = "Платеж для Лицевого счета"
            descLabel.isHidden = true
//            fieldTop.constant = 16
        }
        self.iconPhone.isHidden = false
        self.iconPhone.tintColor = mainGreenColor
        self.iconEmail.tintColor = mainGreenColor
        self.iconEmail.isHidden = true
        self.phoneEmailText.maskExpression = "+7 ({ddd}) {ddd}-{dddd}"
        self.phoneEmailText.maskTemplate = "*"
        self.phoneEmailText.keyboardType = .phonePad
        self.phoneEmailText.reloadInputViews()
        self.phoneEmailText.placeholder = "Контактный номер для отправки чека"
        self.phoneChoice = true
        self.emailChoice = false
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        let string              = "Нажимая кнопку «Оплатить», вы принимаете условия Публичной оферты"
        let range               = (string as NSString).range(of: "Публичной оферты")
        let attributedString    = NSMutableAttributedString(string: string)
        
        attributedString.addAttribute(.underlineStyle, value: NSNumber(value: 1), range: range)
        attributedString.addAttribute(.underlineColor, value: UIColor.black, range: range)
        offerLabel.attributedText = attributedString
        
        let offerTap = UITapGestureRecognizer(target: self, action: #selector(offerTapped(_:)))
        offerLabel.isUserInteractionEnabled = true
        offerLabel.addGestureRecognizer(offerTap)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        sumTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            view.frame.origin.y = 0 - keyboardHeight
            scroll.contentInset.top = keyboardHeight
        }
    }
    
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.frame.origin.y = 0
        scroll.contentInset.top = 0
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField){
        var str: String = textField.text!
        print(str)
        str = str.replacingOccurrences(of: ",", with: ".")
        self.sumTextField.text = str
        if str.contains(find: "."){
            var i = 0
            str.forEach{
                if $0 == "."{
                    i += 1
                }
            }
            if i > 1 && str.last == "."{
                str.removeLast()
                self.sumTextField.text = str
            }
            let index = (str.index(of: "."))!
            let s = str.distance(from: index, to: str.endIndex)
            if s > 3{
                str.removeLast()
                self.sumTextField.text = str
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let str: String = sumTextField.text ?? ""
        if str != "" && !str.contains(find: "."){
            sumTextField.text = sumTextField.text! + ".00"
        }else if str == ""{
            sumTextField.text = "0.00"
        }
    }
    
    //    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    //        var str: String = textField.text!
    //        str = str.replacingOccurrences(of: ",", with: ".")
    //        self.sumTextField.text = str
    //        if str.contains(find: ".") && (string == "." || string == ","){
    //            str.removeLast()
    //            self.sumTextField.text = str
    //        }
    //        return true
    //    }
    
    @objc private func offerTapped(_ sender: UITapGestureRecognizer) {
        url = URLRequest(url: URL(string: "http://client.sminex.com/_layouts/BusinessCenters.Branding/Payments/PaymentOffer.aspx")!)
        performSegue(withIdentifier: Segues.fromFinancePayAcceptVC.toPay, sender: self)
    }
    
    private func requestPay() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        var email = ""
        if emailChoice{
            email = phoneEmailText.text?.replacingOccurrences(of: " ", with: "") ?? ""
        }
        if email == ""{
            var mes = ""
            if phoneChoice{
                mes = "Укажите номер телефона"
            }else{
                mes = "Укажите Email"
            }
            let alert = UIAlertController(title: "Ошибка", message: mes, preferredStyle: .alert)
            alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
            DispatchQueue.main.sync {
                self.stopAnimation()
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        let number_bills = billsData_?.number_eng
        let date_bills   = billsData_?.datePay
        var url_str = Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + pwd
        url_str = url_str + "&amount=" + sumText.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        if (number_bills != nil) {
            url_str = url_str + "&invoiceNumber=" + number_bills!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            url_str = url_str + "&date=" + date_bills!.replacingOccurrences(of: " 00:00:00", with: "").addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        }
        
        var request = URLRequest(url: URL(string: url_str)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.stopAnimation()
                }
            }
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: String(data: data!, encoding: .utf8)?.replacingOccurrences(of: "error: ", with: "") ?? "", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            //            self.str_url = String(data: data!, encoding: .utf8)!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            //            self.str_url = self.str_url.replacingOccurrences(of: "https%3A", with: "https:")
            
            // Костыль
            self.str_url = String(data: data!, encoding: .utf8)!//.replacingOccurrences(of: " ", with: "")
            
            //            let index = self.str_url.index(self.str_url.startIndex, offsetBy: 39)
            //            var str1 = self.str_url.substring(to: index)
            //            var str2 = self.str_url.suffix(self.str_url.length - 39)
            //
            //            self.str_url = str1 + str2.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            self.url = URLRequest(url: URL(string: self.str_url)!)
            
            DispatchQueue.main.sync {
                self.performSegue(withIdentifier: Segues.fromFinancePayAcceptVC.toPay, sender: self)
            }
            
            #if DEBUG
            //            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
    }
    
    private func startAnimation() {
        sendButton.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        loader.stopAnimating()
        loader.isHidden = true
        sendButton.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinancePayAcceptVC.toPay {
            let vc = segue.destination as! FinancePayVC
            vc.url_ = url
        }
    }
    
}
