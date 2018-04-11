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
    @IBOutlet private weak var backView:       UIView!
    
    @IBAction private func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: DealsJson?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(backButtonPressed(_:)))
        backView.isUserInteractionEnabled = true
        backView.addGestureRecognizer(tap)
        
        image.image = data_?.img
        titleLabel.text = data_?.name
        dateLabel.text = data_?.dateStop
        bodyLabel.text = data_?.body
        linksLabel.text = "Соцсети: \(data_?.link ?? "")"
    }
    
    @objc private func backButtonPressed(_ sender: UITapGestureRecognizer) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden           = true
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden           = false
        navigationController?.isNavigationBarHidden = false
    }
}
