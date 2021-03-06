//
//  AccountNotifications.swift
//  Sminex
//
//  Created by IH0kN3m on 4/9/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class AccountNotificationsVC: UIViewController {
    
    @IBOutlet private weak var newComment:  UISwitch!
    @IBOutlet private weak var newStatus:   UISwitch!
    @IBOutlet private weak var counters:    UISwitch!
    @IBOutlet private weak var news:        UISwitch!
    @IBOutlet private weak var dolg:        UISwitch!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        sendStats()
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        newComment.setOn(!defaults.bool(forKey: "newCommentNotify"), animated: false)
        newStatus.setOn(!defaults.bool(forKey: "newStatusNotify"), animated: false)
        counters.setOn(!defaults.bool(forKey: "countersNotify"), animated: false)
        news.setOn(!defaults.bool(forKey: "newsNotify"), animated: false)
        dolg.setOn(!defaults.bool(forKey: "dolgNotify"), animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
    }
    
    private func sendStats() {
        
        let defaults    = UserDefaults.standard
        
        let newComment  = !self.newComment.isOn
        let newStatus   = !self.newStatus.isOn
        let counters    = !self.counters.isOn
        let news        = !self.news.isOn
        let dolg        = !self.dolg.isOn
        
        if newComment    == defaults.bool(forKey: "newCommentNotify")
            && newStatus == defaults.bool(forKey: "newStatusNotify")
            && counters  == defaults.bool(forKey: "countersNotify")
            && news      == defaults.bool(forKey: "newsNotify")
            && dolg      == defaults.bool(forKey: "dolgNotify") {
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            
            defaults.setValue(newComment, forKey: "newCommentNotify")
            defaults.setValue(newStatus, forKey: "newStatusNotify")
            defaults.setValue(counters, forKey: "countersNotify")
            defaults.setValue(news, forKey: "newsNotify")
            defaults.setValue(dolg, forKey: "dolgNotify")
            defaults.synchronize()
            let newStatusTxt    = !newStatus    ? "1;" : "0;"
            let newCommentTxt   = !newComment   ? "1;" : "0;"
            let newsTxt         = !news         ? "1;" : "0;"
            let dolgTxt         = !dolg         ? "1;" : "0;"
            let countersTxt     = !counters     ? "1"  : "0"
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.CONFIGURE_NOTIFY + "login=\(defaults.string(forKey: "login") ?? "")&deviceid=\(UserDefaults.standard.string(forKey: "googleToken") ?? "")&settings=" + newStatusTxt + newCommentTxt + newsTxt + dolgTxt + countersTxt)!)
            request.httpMethod = "GET"
            print(request)
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                #if DEBUG
                    print(String(data: data!, encoding: .utf8) ?? "")
                #endif
                
            }.resume()
        }
    }
}







