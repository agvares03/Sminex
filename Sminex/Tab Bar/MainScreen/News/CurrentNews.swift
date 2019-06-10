//
//  CurrentNews.swift
//  Sminex
//
//  Created by IH0kN3m on 4/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class CurrentNews: UIViewController, UIWebViewDelegate {
    
    @IBOutlet private weak var imageHeight:     NSLayoutConstraint!
    @IBOutlet private weak var imageWidth:      NSLayoutConstraint!
    @IBOutlet private weak var webViewHeight:   NSLayoutConstraint!
    @IBOutlet private weak var titleTop:        NSLayoutConstraint!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var image:           UIImageView!
    @IBOutlet private weak var webView:         UIWebView!
    @IBOutlet private weak var titleLabel:  	UILabel!
    @IBOutlet private weak var date:        	UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        if !isFromMain_ {
            navigationController?.popViewController(animated: true)
        
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    public var data_: NewsJson?
    public var isFromMain_ = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        webView.delegate = self
        webView.scrollView.isScrollEnabled = false
        let txt = "<div font-size:16px;'>" + (data_?.text)!
        webView.loadHTMLString(txt, baseURL: nil)
        
        titleLabel.text = data_?.header
        if data_?.dateStart != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            //date.text = dayDifference(from: df.date(from: data_?.dateStart ?? "") ?? Date(), style: "dd MMMM yyyy, hh:mm")
            if dayDifference(from: df.date(from: data_?.dateStart ?? "") ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: data_?.created ?? "") ?? Date(), style: "HH:mm")
                
            } else {
                let dateI = df.date(from: data_?.created ?? "")
                let calendar = Calendar.current
                let year = calendar.component(.year, from: dateI!)
                let curYear = calendar.component(.year, from: Date())
                if year < curYear{
                    date.text = dayDifference(from: df.date(from: data_?.created ?? "") ?? Date(), style: "dd MMMM YYYY")
                }else{
                    date.text = dayDifference(from: df.date(from: data_?.created ?? "") ?? Date(), style: "dd MMMM")
                }
            }
        }
        
        if data_?.headerImage == nil || data_?.headerImage == "" {
            titleTop.constant = 16
            image.isHidden = true
        
        } else {
            image.image = UIImage(data: Data(base64Encoded: (data_?.headerImage?.replacingOccurrences(of: "data:image/png;base64,", with: ""))!)!)
        }
        
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        print(points)
        
        if (300.0...320.0).contains(points) {
            imageWidth.constant  = 288
            imageHeight.constant = 144
        } else if (320.0...350.0).contains(points) {
            imageWidth.constant  = 343
            imageHeight.constant = 170
        } else if (350.0...400.0).contains(points) {
            imageWidth.constant  = 343
            imageHeight.constant = 170
            
        } else {
            imageWidth.constant  = 382
            imageHeight.constant = 191
        }
        getImage()
    }
    
    private func getImage() {
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let newsId:Int = (data_?.newsId!)!
        var request = URLRequest(url: URL(string: Server.SERVER + "GetNewsByID.ashx?" + "id=" + String(newsId))!)
        print("REQUEST = \(request)")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            //            print(String(data: data!, encoding: .utf8) ?? "")
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
//            DispatchQueue.main.async {
//                if String(data: data!, encoding: .utf8) == nil || String(data: data!, encoding: .utf8) == "" {
//                    self.titleTop.constant = 16
//                    self.image.isHidden = true
//
//                } else {
//                    self.image.image = UIImage(data: Data(base64Encoded: (String(data: data!, encoding: .utf8)!.replacingOccurrences(of: "data:image/png;base64,", with: "")))!)
//                }
//            }
            }.resume()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        webViewHeight.constant     = webView.scrollView.contentSize.height
        scroll.contentSize.height += webView.scrollView.contentSize.height
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.open(request.url!, options: [:], completionHandler: nil)
            return false
        }
        return true
    }
}
