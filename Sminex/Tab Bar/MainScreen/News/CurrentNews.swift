//
//  CurrentNews.swift
//  Sminex
//
//  Created by IH0kN3m on 4/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class CurrentNews: UIViewController, UIWebViewDelegate {
    
    @IBOutlet private weak var titleTop:    NSLayoutConstraint!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var image:       UIImageView!
    @IBOutlet private weak var webView:     UIWebView!
    @IBOutlet private weak var titleLabel:  UILabel!
    @IBOutlet private weak var date:        UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: NewsJson?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        webView.delegate = self
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(data_?.text ?? "", baseURL: nil)
        
        titleLabel.text = data_?.header
        
        if data_?.dateStart != "" {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            date.text = dayDifference(from: df.date(from: data_?.dateStart ?? "") ?? Date(), style: "dd MMMM yyyy, hh:mm")
        }
        
        if data_?.headerImage == nil || data_?.headerImage == "" {
            titleTop.constant = 16
            image.isHidden = true
        
        } else {
            image.image = UIImage(data: Data(base64Encoded: (data_?.headerImage?.replacingOccurrences(of: "data:image/png;base64,", with: ""))!)!)
        }
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.frame.size.height = 1
        webView.frame.size = webView.sizeThatFits(.zero)
        scroll.contentSize.height += webView.frame.size.height
    }
}
