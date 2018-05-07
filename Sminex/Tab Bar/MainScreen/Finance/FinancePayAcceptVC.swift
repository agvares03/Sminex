//
//  FinancePayAcceptVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/22/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class FinancePayAcceptVC: UIViewController {
    
    @IBOutlet private weak var offerLabel:  UILabel!
    @IBOutlet private weak var fieldTop:    NSLayoutConstraint!
    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBOutlet private weak var scroll: UIScrollView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descLabel: UILabel!
    @IBOutlet private weak var sendButton:  UIButton!
    @IBOutlet private weak var sumTextField:    UITextField!
    
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
        DispatchQueue.global(qos: .userInitiated).async {
            self.requestPay()
        }
    }
    
    open var accountData_: AccountDebtJson?
    open var billsData_: AccountBillsJson?
    private var url: URLRequest?
    private var sumText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopAnimation()
        
        title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"
        
        if accountData_ == nil {
            sumTextField.text = String(format: "%.1f", billsData_?.sum ?? 0.0)
            titleLabel.text = "Платеж для Лицевого счета №\(billsData_?.number ?? "")"
            var date = billsData_?.datePay
            if (date?.count ?? 0) > 9 {
                date?.removeLast(9)
            }
            descLabel.text = "Оплата счета: \(billsData_?.number ?? "") от \(date ?? "")"
        
        } else {
            sumTextField.text = String(format: "%.1f", accountData_?.sumPay ?? 0.0)
            titleLabel.text = "Платеж для Лицевого счета"
            descLabel.isHidden = true
            fieldTop.constant = 16
        }
        
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
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc private func offerTapped(_ sender: UITapGestureRecognizer) {
        url = URLRequest(url: URL(string: "http://client.sminex.com/_layouts/BusinessCenters.Branding/Payments/PaymentOffer.aspx")!)
        performSegue(withIdentifier: Segues.fromFinancePayAcceptVC.toPay, sender: self)
    }
    
    private func requestPay() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let password = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt())
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + password + "&amount=" + (sumText))!)
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
            
            self.url = URLRequest(url: URL(string: String(data: data!, encoding: .utf8) ?? "")!)
            
            DispatchQueue.main.sync {
                self.performSegue(withIdentifier: Segues.fromFinancePayAcceptVC.toPay, sender: self)
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
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


















