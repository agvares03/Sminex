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
    
    open var url_: URLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        webView.loadRequest(url_!)
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}
