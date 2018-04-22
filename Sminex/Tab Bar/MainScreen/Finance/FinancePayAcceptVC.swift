//
//  FinancePayAcceptVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/22/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class FinancePayAcceptVC: UIViewController {
    
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
        
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        startAnimation()
        DispatchQueue.global(qos: .userInitiated).async {
            self.requestPay()
        }
    }
    
    open var accountData_: AccountDebtJson?
    open var billsData_: AccountBillsJson?
    private var url: URLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"
        
        if accountData_ == nil {
            titleLabel.text = "Платеж для Лицевого счета №\(Int(billsData_?.sum ?? 0.0))"
            var date = billsData_?.datePay
            date?.removeLast(9)
            descLabel.text = "Оплата счета: \(billsData_?.number ?? "") от \(date ?? "")"
        
        } else {
            titleLabel.text = "Платеж для Лицевого счета"
            descLabel.isHidden = true
            fieldTop.constant = 16
        }
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    private func requestPay() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let password = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + password + "&amount=" + (sumTextField.text ?? ""))!)
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
        return salt ?? Data()
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


















