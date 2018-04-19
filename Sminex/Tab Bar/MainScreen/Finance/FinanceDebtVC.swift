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
    
    @IBAction private func barcodePressed(_ sender: UIButton) {
        if data_?.codPay != "" && data_?.codPay != nil {
            performSegue(withIdentifier: Segues.fromFinanceDebtVC.toBarcode, sender: self)
            
        } else {
            showToast(message: "Нет данных по QR-коду")
        }
    }
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        requestPay()
    }
    
    open var data_: AccountBillsJson?
    private var receipts: [ReceiptsJson]?
    private var url: URLRequest?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.dataSource   = self
        collection.delegate     = self
        
        startAnimation()
        if data_ != nil {
            DispatchQueue.global(qos: .userInitiated).async {
                self.getDebt()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard receipts != nil else {
            return 0
        }
        return receipts?.count != 0 ? (receipts?.count ?? 0) + 1 : 0
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceDebtHeader", for: indexPath) as! FinanceDebtHeader
        header.dispay(getNameAndMonth(data_?.numMonth ?? 0) + " \(data_?.numYear ?? 0)")
        return header
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == receipts?.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtPayCell", for: indexPath) as! FinanceDebtPayCell
            cell.display(data_!)
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceDebtCell", for: indexPath) as! FinanceDebtCell
        let isBold = receipts![indexPath.row].usluga?.replacingOccurrences(of: " ", with: "") == receipts![indexPath.row].type?.replacingOccurrences(of: " ", with: "")
        if !isBold {
        cell.display(title: receipts![indexPath.row].usluga ?? "",
                     desc: String(receipts![indexPath.row].sum ?? 0.0),
                     isBold: isBold)
        
        } else {
            let currType = receipts?.filter {
                return $0.type == receipts![indexPath.row].type
            }
            var sum = 0.0
            currType?.forEach {
                sum += ($0.sum ?? 0.0)
            }
            cell.display(title: receipts![indexPath.row].usluga ?? "",
                         desc: String(sum),
                         isBold: isBold)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == receipts?.count {
            return CGSize(width: view.frame.size.width, height: 100.0)
        } else {
            return CGSize(width: view.frame.size.width, height: 40.0)
        }
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
    
    private func requestPay() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let password = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + password + "&amount=" + String(data_?.sum ?? 0.0))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: String(data: data!, encoding: .utf8)?.replacingOccurrences(of: "error: ", with: "") ?? "", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.url = URLRequest(url: URL(string: String(data: data!, encoding: .utf8) ?? "")!)
            
            DispatchQueue.main.sync {
                self.performSegue(withIdentifier: Segues.fromFinanceDebtVC.toPay, sender: self)
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromFinanceDebtVC.toBarcode {
            let vc = segue.destination as! FinanceBarCodeVC
            vc.amount_ = data_?.sum
            vc.codePay_ = data_?.codPay
        
        } else if segue.identifier == Segues.fromFinanceDebtVC.toPay {
            let vc = segue.destination as! FinancePayVC
            vc.url_ = url
        }
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
    
    func display(title: String, desc: String, isBold: Bool) {
        self.title.text = title
        self.desc.text = desc
        
        if isBold {
            self.title.font = UIFont.boldSystemFont(ofSize: self.title.font.pointSize)
            self.desc.font  = UIFont.boldSystemFont(ofSize: self.desc.font.pointSize)
            self.title.textColor = .black
        
        } else {
            self.title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .light)
            self.desc.font  = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .light)
            self.title.textColor = .lightGray
        }
    }
}

final class FinanceDebtPayCell: UICollectionViewCell {
    
    @IBOutlet private weak var dateLabel: UILabel!
    
    func display(_ data: AccountBillsJson) {
        var date = data.datePay
        date?.removeLast(9)
        self.dateLabel.text = "До " + (date ?? "")
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

















