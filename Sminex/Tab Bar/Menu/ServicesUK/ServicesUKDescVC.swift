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
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var imgView:     UIImageView!
    @IBOutlet private weak var titleLabel:  UILabel!
    @IBOutlet private weak var costLabel:   UILabel!
    @IBOutlet private weak var descLabel:   UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        
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
        
        navigationItem.title = data_?.name
        titleLabel.text = data_?.name
        costLabel.text  = data_?.cost
        descLabel.text  = data_?.desc
    }
}
