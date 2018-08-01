//
//  SettingsUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
@available(*, deprecated, message: "Класс нигде не используется. Будет удалён в будущих сборках")
final class SettingsUser: UIViewController {

    @IBOutlet private weak var menuButton: UIBarButtonItem!
    
    @IBAction private func changeUser(_ sender: UIButton) {
        saveUsersDefaults()
    }
    
    private func saveUsersDefaults() {
        let defaults = UserDefaults.standard
        defaults.setValue("", forKey: "login")
        defaults.setValue("", forKey: "pass")
        defaults.synchronize()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
}
