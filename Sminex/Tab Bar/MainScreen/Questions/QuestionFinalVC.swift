//
//  QuestionFinalVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/2/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class QuestionFinalVC: UIViewController {
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        if !isFromMain_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
        
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        if !isFromMain_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
        
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    public var isFromMain_ = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
}
