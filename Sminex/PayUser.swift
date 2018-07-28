//
//  PayUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
@available(*, deprecated, message: "Класс нигде не используется. Будет удалён в будущих сборках")
final class PayUser: UIViewController {

    @IBOutlet private weak var menuButton:  UIBarButtonItem!
    @IBOutlet private weak var txtNotPay:  UILabel!
    @IBOutlet private weak var webView:     UIWebView!
    @IBOutlet private weak var mainView:    UIView!

    @IBOutlet private weak var topTxt:      UILabel!
    
    @IBOutlet private weak var Sum:         UILabel!
    @IBOutlet private weak var SumStrah:    UILabel!
    @IBOutlet private weak var SumObj:      UILabel!
    @IBOutlet private weak var choice:      UISwitch!
    
    @IBAction private func pay_Go(_ sender: UIButton) {
        mainView.isHidden = true
        webView.isHidden  = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Получим логин и сумму долга для передачи в оплату
//        let defaults            = UserDefaults.standard
//        let login:String        = defaults.string(forKey: "login")  ?? ""
//        var sum:String          = defaults.string(forKey: "sum")    ?? ""
//        let strah: String       = defaults.string(forKey: "strah")  ?? ""
        
        // Надпись о задолженности пока только для ДомЖилСервиса
        let topTxt_text = ""
        
        topTxt.text = topTxt_text
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        // Оставим текущуий интерфейс
        txtNotPay.isHidden = false
        webView.isHidden = true
        view.isHidden = true
    }
    
    private func loadWeb(login: String, sum: String, strah: String) {
        let sum_web = String(Double(sum)! + Double(strah)!)
        
        webView.loadRequest(URLRequest(url: URL(string: "https://vp.ru/common-modal/?action=provider&guid=domjilservicebtn&acc=" + login + "&amount=" + sum_web + "&widget=1&utm_source=widget&utm_medium=domjilservice_full&utm_campaign=dgservic.ru")!))
    }
    
    @IBAction private func choice_Go(_ sender: UISwitch) {
        
        let defaults            = UserDefaults.standard
        let login               = defaults.string(forKey: "login")  ?? ""
        let sum                 = defaults.string(forKey: "sum")    ?? ""
        let strah               = defaults.string(forKey: "strah")  ?? ""
        
        if choice.isOn {
            loadWeb(login: login, sum: sum, strah: strah)
            SumObj.text        = String(Double(sum)! + Double(strah)!) + " руб."
        } else {
            loadWeb(login: login, sum: sum, strah: "0")
            SumObj.text        = sum + " руб."
        }
    }
}
