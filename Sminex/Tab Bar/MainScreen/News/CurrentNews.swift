//
//  CurrentNews.swift
//  Sminex
//
//  Created by IH0kN3m on 4/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import SafariServices
import WebKit

final class CurrentNews: UIViewController, WKNavigationDelegate, WKUIDelegate, UITextViewDelegate {
    
    @IBOutlet private weak var imageHeight:     NSLayoutConstraint!
    @IBOutlet private weak var imageWidth:      NSLayoutConstraint!
    @IBOutlet private weak var descHeight:      NSLayoutConstraint!
    @IBOutlet private weak var titleTop:        NSLayoutConstraint!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var image:           UIImageView!
    @IBOutlet private weak var wView:           UIView!
    @IBOutlet private weak var titleLabel:  	UILabel!
    @IBOutlet private weak var date:        	UILabel!
    @IBOutlet private weak var desc:            UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    var webView: WKWebView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        if isFromNotifi_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
            
        } else if !isFromMain_ {
            navigationController?.popViewController(animated: true)
        
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    public var isFromNotifi_ = false
    public var data_: NewsJson?
    public var isFromMain_ = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        StartIndicator()
        getImage()
        automaticallyAdjustsScrollViewInsets = false
//        let webConfiguration = WKWebViewConfiguration()
//        let customFrame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 0, height: self.wView.frame.size.height))
//        self.webView = WKWebView (frame: customFrame , configuration: webConfiguration)
//        self.webView.translatesAutoresizingMaskIntoConstraints = false
//        self.wView.addSubview(self.webView)
//        self.webView.scrollView.isScrollEnabled = false
//        self.webView.topAnchor.constraint(equalTo: self.wView.topAnchor).isActive = true
//        self.webView.rightAnchor.constraint(equalTo: self.wView.rightAnchor).isActive = true
//        self.webView.leftAnchor.constraint(equalTo: self.wView.leftAnchor).isActive = true
//        self.webView.bottomAnchor.constraint(equalTo: self.wView.bottomAnchor).isActive = true
//        self.webView.heightAnchor.constraint(equalTo: self.wView.heightAnchor).isActive = true
//        self.webView.navigationDelegate = self
//        self.webView.uiDelegate = self
        
        let txt = "<div font-size:16px;'>" + (data_?.text)!
        desc.delegate = self
        desc.isEditable = false
        desc.attributedText = txt.htmlToAttributedString
//        webView.loadHTMLString(txt, baseURL: nil)
        descHeight.constant = heightForView(text: desc?.text ?? "", font: UIFont(name: "Times New Roman", size: 16)!, width: view.frame.size.width - 68)
        titleLabel.text = data_?.header!.uppercased()
        
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
        
//        if data_?.headerImage == nil || data_?.headerImage == "" {
//            titleTop.constant = 16
//            image.isHidden = true
//
//        } else {
//            image.image = UIImage(data: Data(base64Encoded: (data_?.headerImage?.replacingOccurrences(of: "data:image/png;base64,", with: ""))!)!)
//        }
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UITextView = UITextView(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(URL)
        }
        return false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
    }
    
    private func getImage() {
        let newsId:Int = (data_?.newsId!)!
        var request = URLRequest(url: URL(string: Server.SERVER + "GetNewsHeaderImageByID.ashx?" + "id=" + String(newsId))!)
        print("REQUEST = \(request)")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            
//            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
//            #endif
            if String(data: data!, encoding: .utf8) != nil && (String(data: data!, encoding: .utf8)?.contains(find: "картинка для новости"))!{
                DispatchQueue.main.async {
                    self.titleTop.constant = 16
                    self.image.isHidden = true
                    self.imageHeight.constant = 0
                    self.StopIndicator()
                }
            }else{
                if let image = UIImage(data: data!) {
                    DispatchQueue.main.async {
                        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
                        print(points)
                        
                        if (300.0...320.0).contains(points) {
                            self.imageWidth.constant  = 288
                            self.imageHeight.constant = 144
                        } else if (320.0...350.0).contains(points) {
                            self.imageWidth.constant  = 343
                            self.imageHeight.constant = 170
                        } else if (350.0...400.0).contains(points) {
                            self.imageWidth.constant  = 343
                            self.imageHeight.constant = 170
                        } else {
                            self.imageWidth.constant  = 382
                            self.imageHeight.constant = 191
                        }
                        self.image.image = image
                        self.image.isHidden = false
                        self.StopIndicator()
                    }
                }
            }
        }.resume()
    }
    
    private func StartIndicator() {
        self.scroll.isHidden    = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func StopIndicator() {
        self.scroll.isHidden    = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
