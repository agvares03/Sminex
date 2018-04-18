//
//  QuestionFinalVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/2/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class QuestionFinalVC: UIViewController {
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        let viewControllers = navigationController?.viewControllers
        navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
    }
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        let viewControllers = navigationController?.viewControllers
        navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
}
