//
//  FinanceDebtVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/13/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class FinanceDebtVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var data_: AccountBillsJson?
    private var receipts: [ReceiptsJson]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource   = self
        collection.delegate     = self
        
        startAnimation()
        if data_ != nil {
            getDebt()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard receipts != nil else {
            return 0
        }
        return receipts?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceDebtHeader", for: indexPath) as! FinanceDebtHeader
        header.dispay(getNameAndMonth(data_?.numMonth ?? 0) + " \(data_?.numYear ?? 0)")
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCell", for: indexPath) as! FinanceDebtCell
        cell.display(title: receipts![indexPath.row].usluga ?? "", desc: String(receipts![indexPath.row].sum ?? 0.0))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 30.0)
    }
    
    private func getDebt() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        let id = data_?.idReceipts?.stringByAddingPercentEncodingForRFC3986() ?? ""
        
        let url = Server.SERVER + Server.GET_BILLS_SERVICES + "login=" + login + "&pwd=" + pass + "&id_receipts=" + id
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.stopAnimation()
                    self.collection.reloadData()
                }
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.receipts = ReceiptsDataJson(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)?.data
            
            #if DEBUG
                print(String.init(data: data!, encoding: .utf8) ?? "")
            #endif
        
        }.resume()
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        request.httpMethod = "GET"
        
        queue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            defer {
                queue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            
            #if DEBUG
            print("salt is = \(String(describing: String(data: data!, encoding: .utf8)))")
            #endif
            
            }.resume()
        
        queue.wait()
        return salt!
    }
    
    private func startAnimation() {
        loader.isHidden     = false
        collection.isHidden = true
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        collection.isHidden = false
        loader.isHidden     = true
        loader.stopAnimating()
    }
}

final class FinanceDebtHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    func dispay(_ title: String) {
        self.title.text = title
    }
}

final class FinanceDebtCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    func display(title: String, desc: String) {
        self.title.text = title
        self.desc.text = desc
    }
}

struct ReceiptsDataJson: JSONDecodable {
    
    let data: [ReceiptsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct ReceiptsJson: JSONDecodable {
    
    let idReceipts:     String?
    let usluga:         String?
    let type:           String?
    let sum:            Double?
    
    init?(json: JSON) {
        idReceipts  = "id_receipts" <~~ json
        usluga      = "usluga"      <~~ json
        type        = "type"        <~~ json
        sum         = "sum"         <~~ json
    }
    
    init(idReceipts: String, usluga: String, type: String, sum: Double) {
        self.idReceipts = idReceipts
        self.usluga     = usluga
        self.type       = type
        self.sum        = sum
    }
}

















