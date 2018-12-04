//
//  ServicesUKDescVC.swift
//  Sminex
//
//  Created by IH0kN3m on 5/11/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class ServicesUKDescVC: UIViewController {
    
    @IBOutlet private weak var imgHeight:   NSLayoutConstraint!
    @IBOutlet private weak var titleTop:    NSLayoutConstraint!
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var imgView:     UIImageView!
    @IBOutlet private weak var sendBtn:  UIButton!
    @IBOutlet private weak var titleLabel:  UILabel!
    @IBOutlet private weak var costLabel:   UILabel!
    @IBOutlet private weak var descLabel:   UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        startAnimator()
        uploadRequest()
    }
    
    open var data_: ServicesUKJson?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = UIImage(data: Data(base64Encoded: ((data_?.picture ?? "").replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
            imgView.image = image
        
        } else {
            imgHeight.constant = 0
            titleTop.constant  = -16
        }
        loader.isHidden = true
        navigationItem.title = data_?.name
        titleLabel.text = data_?.name
        costLabel.text  = data_?.cost
        descLabel.text  = data_?.desc
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: date)
    }
    
    private func uploadRequest() {
        
        let login = UserDefaults.standard.string(forKey: "login")!
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let comm = titleLabel.text ?? ""
        
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=bceeab0b-891a-4af8-9953-1bf1ffd7fe29&name=\(comm.stringByAddingPercentEncodingForRFC3986()!)&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)&phonenum=\(UserDefaults.standard.string(forKey: "contactNumber") ?? "")&email=\(UserDefaults.standard.string(forKey: "mail") ?? "")&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(Date().toString(format: .custom("dd.MM.yyyy hh:mm:ss")).stringByAddingPercentEncodingForRFC3986()!)&dateTo=\(Date().toString(format: .custom("dd.MM.yyyy hh:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=\(Date().toString(format: .custom("dd.MM.yyyy hh:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy hh:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&paidServiceType=\(data_?.id!.stringByAddingPercentEncodingForRFC3986() ?? "")"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        print(request)
        URLSession.shared.dataTask(with: request) {
            responce, error, _ in
            
            guard responce != nil else {
                DispatchQueue.main.async {
                    self.endAnimator()
                }
                return
            }
            #if DEBUG
            print(String(data: responce!, encoding: .utf8)!)
            #endif
            
            if (String(data: responce!, encoding: .utf8)?.contains(find: "error"))! {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Услуга не заказана", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    self.endAnimator()
                }
                return
            } else {
                
                
                    DispatchQueue.main.sync {
                        UserDefaults.standard.set(true, forKey: "backBtn")
                        let alert = UIAlertController(title: "Услуга заказана", message: "", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                            self.endAnimator()
                            self.navigationController?.popViewController(animated: true)
                        }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
            }
            }
    .resume()
    }
    
    private func startAnimator() {
        sendBtn.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimator() {
        sendBtn.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
    }
}
