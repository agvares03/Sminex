//
//  Registration_Sminex_SMS.swift
//  Sminex
//
//  Created by Роман Тузин on 13.02.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

class Registration_Sminex_SMS: UIViewController {
    
    @IBOutlet weak var txtNameLS: UILabel!
    @IBOutlet weak var NameLS: UILabel!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var btn_go: UIButton!
    
    @IBAction func btn_go_touch(_ sender: UIButton) {
    }
    
    @IBAction func btn_cancel(_ sender: UIButton) {
    }
    
    var number_phone: String = ""
    var number_ls: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        if (number_phone != "") {
            txtNameLS.text = "Номер телефона"
            NameLS.text = number_phone
        } else {
            txtNameLS.text = "Номер лицевого счета"
            NameLS.text = number_ls
        }
        
    }
    
}
