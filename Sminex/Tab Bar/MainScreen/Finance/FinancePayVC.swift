//
//  FinancePayVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/16/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class FinancePayVC: UIViewController {
    
    @IBOutlet private weak var webView: UIWebView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var url_: URLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        webView.loadRequest(url_!)

    }
}
