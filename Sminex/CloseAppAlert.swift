//
//  CloseAppAlert.swift
//  DemoUC
//
//  Created by Роман Тузин on 11.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

protocol CloseAppDelegate : class {
    func closeAppDone(closeApp: CloseAppAlert)
}

final class CloseAppAlert: UIViewController, FloatRatingViewDelegate {
    
    open weak var delegate: CloseAppDelegate?
    open var apps_:         Applications?
    
    // Номер заявки
    open var number_                 = ""
    private var responseString = ""
    
    // Данные для создания комментария
    open var idAuthor_      = ""
    open var nameAccount_   = ""
    open var idAccount_     = ""
    open var teckId_: Int64 = 1
    
    @IBOutlet private weak var floatRatingView:   FloatRatingView!
    @IBOutlet private weak var closeComm:         UITextField!
    
    @IBOutlet private weak var btnClose:  UIButton!
    @IBOutlet private weak var btnOk:     UIButton!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBAction private func close_action_close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func close_action_do(_ sender: UIButton) {
        self.startIndicator()
        let urlPath = Server.SERVER + Server.CLOSE_APP +
            "&reqID=" + self.number_.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! +
            "&text=" + self.closeComm.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)! +
            "&mark=" + self.mark.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        var request = URLRequest(url: URL(string: urlPath)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                DispatchQueue.main.async {
                    self.stopIndicator()
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
                print("responseString = \(self.responseString)")
            #endif
            
            self.choice()
            }.resume()
    }
    
    // Оценка
    private var mark = "7"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Rating
        // Required float rating view params
        self.floatRatingView.emptyImage = UIImage(named: "StarEmpty")
        self.floatRatingView.fullImage  = UIImage(named: "StarFull")
        // Optional params
        self.floatRatingView.delegate       = self
        self.floatRatingView.contentMode    = UIViewContentMode.scaleAspectFit
        self.floatRatingView.maxRating      = 5
        self.floatRatingView.minRating      = 1
        self.floatRatingView.rating         = 3.5
        self.floatRatingView.editable       = true
        self.floatRatingView.halfRatings    = true
        self.floatRatingView.floatRatings   = false
        
        self.stopIndicator()
    }
    
    private func choice() {
        DispatchQueue.main.async {
            
            if self.responseString == "0" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось закрыть заявку, попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "1" {
                // Успешно - обновим значение в БД
                self.apps_?.is_close = 0
                CoreDataManager.instance.saveContext()
                
                let db = DB()
                db.add_comm(ID: self.teckId_, id_request: Int64(self.number_)!, text: "Заявка закрыта с оценкой - " + self.mark, added: self.dateTeck()!, id_Author: self.idAuthor_, name: self.nameAccount_, id_account: self.idAccount_)
                
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Успешно", message: "Заявка закрыта с оценкой - " + self.mark, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    if self.delegate != nil {
                        self.delegate?.closeAppDone(closeApp: self)
                    }
                    self.dismiss(animated: true, completion: nil)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось закрыть заявку, попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func startIndicator() {
        self.btnClose.isHidden  = true
        self.btnOk.isHidden     = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator() {
        self.btnClose.isHidden  = false
        self.btnOk.isHidden     = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    private func dateTeck() -> (String)? {
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString           = dateFormatter.string(from: Date())
        return dateString
        
    }
    
    // MARK: FloatRatingViewDelegate
    
    func floatRatingView(ratingView: FloatRatingView, isUpdating rating:Float) {
        
        #if DEBUG
            print(String(format: "%.0f", self.floatRatingView.rating))
        #endif
        self.mark = String(format: "%.0f", self.floatRatingView.rating * 2)
    }
    
    func floatRatingView(ratingView: FloatRatingView, didUpdate rating: Float) {
        
        #if DEBUG
            print(String(format: "%.0f", self.floatRatingView.rating * 2))
        #endif
        self.mark = String(format: "%f.0", self.floatRatingView.rating * 2)
    }
    
}
