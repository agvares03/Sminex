//
//  PayUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class PayUser: UIViewController {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var txtNotPay: UILabel!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var mainView: UIView!    

    @IBOutlet weak var topTxt: UILabel!
    
    @IBOutlet weak var Sum: UILabel!
    @IBOutlet weak var SumStrah: UILabel!
    @IBOutlet weak var SumObj: UILabel!
    @IBOutlet weak var choice: UISwitch!
    
    @IBAction func pay_Go(_ sender: UIButton) {
        mainView.isHidden = true
        webView.isHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Получим логин и сумму долга для передачи в оплату
        let defaults     = UserDefaults.standard
        let login:String        = defaults.string(forKey: "login")!
        var sum:String          = defaults.string(forKey: "sum")!
        #if isDJ
            sum                 = String(defaults.double(forKey: "debt_sum_all"))
        #endif
        let strah: String       = defaults.string(forKey: "strah")!
        
        // Надпись о задолженности пока только для ДомЖилСервиса
        var topTxt_text: String = "";
        
        #if isDJ
            let debt_date = defaults.string(forKey: "debt_date")!
            let debt_sum_all = defaults.double(forKey: "debt_sum_all")
            let debt_sum = String(defaults.double(forKey: "debt_sum"))
            let debt_over_sum = String(defaults.double(forKey: "debt_over_sum"))
            
            if (debt_date == "0") {
                topTxt_text = "    Задолженность не обнаружена";
            } else {
                if (debt_sum_all <= 0) {
                    topTxt_text = "    Задолженность не обнаружена";
                } else if (debt_sum_all > 5000) {
                    topTxt_text = "    Уважаемый собственник!\n" +
                        "У Вас имеется задолженность на " + debt_date + ":\n" +
                        "- за жилищно-коммунальные услуги - " + debt_sum + " руб.\n" +
                        "- за капитальный ремонт - " + debt_over_sum + " руб.\n" +
                        "Вы внесены в список на ограничение предоставления ЖКУ.\n" +
                        "Срочно оплатите задолженность!"
                } else {
                    topTxt_text = "    Уважаемый собственник!\n" +
                        "Сумма к оплате по Вашему лицевому счету на " + debt_date + " составляет:\n" +
                        "- за жилищно-коммунальные услуги - " + debt_sum + " руб.\n" +
                        "- за капитальный ремонт - " + debt_over_sum + " руб.\n"
                }
            }
        #endif
        
        topTxt.text = topTxt_text
        
        // Установим общий стиль
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
            txtNotPay.isHidden = false
            webView.isHidden   = true
            view.isHidden      = true
        #elseif isDJ
            txtNotPay.isHidden = true
            webView.isHidden   = true
            view.isHidden      = false
            choice.isOn        = true
            
            Sum.text           = sum + " руб."
            SumStrah.text      = strah + " руб."
            SumObj.text        = String(Double(sum)! + Double(strah)!) + " руб."
            
            // Покажем оплату для ДомЖилСервиса
            load_web(login: login, sum: sum, strah: strah)
            
        #else
            // Оставим текущуий интерфейс
            txtNotPay.isHidden = false
            webView.isHidden = true
            view.isHidden = true
        #endif
    }
    
    func load_web(login: String, sum: String, strah: String) {
        let sum_web: String = String(Double(sum)! + Double(strah)!)
        let url = NSURL(string: "https://vp.ru/common-modal/?action=provider&guid=domjilservicebtn&acc=" + login + "&amount=" + sum_web + "&widget=1&utm_source=widget&utm_medium=domjilservice_full&utm_campaign=dgservic.ru")
        let requestObj = NSURLRequest(url: url! as URL);
        webView.loadRequest(requestObj as URLRequest);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func choice_Go(_ sender: UISwitch) {
        
        let defaults     = UserDefaults.standard
        let login:String        = defaults.string(forKey: "login")!
        var sum:String          = defaults.string(forKey: "sum")!
        #if isDJ
            sum                 = String(defaults.double(forKey: "debt_sum_all"))
        #endif
        let strah: String       = defaults.string(forKey: "strah")!
        
        if (choice.isOn) {
            load_web(login: login, sum: sum, strah: strah)
            SumObj.text        = String(Double(sum)! + Double(strah)!) + " руб."
        } else {
            load_web(login: login, sum: sum, strah: "0")
            SumObj.text        = sum + " руб."
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
