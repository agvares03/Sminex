//
//  DealsListDescVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/10/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class DealsListDescVC: UIViewController {
    
    @IBOutlet private weak var image:          UIImageView!
    @IBOutlet private weak var titleLabel:     UILabel!
    @IBOutlet private weak var dateLabel:      UILabel!
    @IBOutlet private weak var bodyLabel:      UILabel!
    @IBOutlet private weak var linksLabel:     UILabel!
    
    @IBAction private func backButtonTapped(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: DealsJson?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        image.image = data_?.img
        titleLabel.text = data_?.name
        dateLabel.text = data_?.dateStop
        bodyLabel.text = data_?.body
        linksLabel.text = "Соцсети: \(data_?.link ?? "")"
        automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden           = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden           = false
    }
}
