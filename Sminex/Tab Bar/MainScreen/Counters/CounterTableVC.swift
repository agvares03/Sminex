//
//  CounterTableVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/28/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import SwiftyXMLParser

private protocol CounterTableCellDelegate: class {
    func pressed(_ named: String)
    func setDelegate(_ delegate: CounterVCDelegate)
}
protocol CounterVCDelegate: class {
    func startAnimator()
    func stopAnimator()
}

final class CounterTableVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, UIGestureRecognizerDelegate, CounterTableCellDelegate, CounterStatementDelegate {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var canCount = true
    
    private var index = 0
    private var meterArr: [MeterValue] = [] {
        didSet {
            DispatchQueue.main.sync {
                self.collection.reloadData()
                self.delegate?.stopAnimator()
            }
        }
    }
    
    private var periods: [CounterPeriod] = [] {
        didSet {
            DispatchQueue.main.sync {
                self.collection.reloadData()
            }
        }
    }
    private var delegate: CounterVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        delegate?.startAnimator()
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.getCounters()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return meterArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterTableCell", for: indexPath) as! CounterTableCell
        cell.display(meterArr[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        
        if canCount {
            performSegue(withIdentifier: Segues.fromCounterTableVC.toStatement, sender: self)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.size.width, height: 70.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CounterTableHeaderCell", for: indexPath) as! CounterTableHeaderCell
        
        if periods.count > 0 {
            header.display(getNameAndMonth(periods.last?.numMonth ?? "1") + " " + (periods[0].year ?? ""), delegate: self)
        
        } else {
            header.display("", delegate: self)
        }
        return header
    }
    
    func pressed(_ named: String) {
        performSegue(withIdentifier: Segues.fromCounterTableVC.toHistory, sender: self)
    }
    
    func setDelegate(_ delegate: CounterVCDelegate) {
        self.delegate = delegate
    }
    
    private func getCounters() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass =  getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_METERS + "login=" + login.stringByAddingPercentEncodingForRFC3986()! + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            if (String(data: data!, encoding: .utf8)?.contains(find: "error"))! {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8)!)
            #endif
            
            let xml = XML.parse(data!)
            let metersValues = xml["MetersValues"]
            let period = metersValues["Period"]
            let meterValue = period.last["MeterValue"]
            
            self.meterArr = []
            meterValue.forEach {
                self.meterArr.append( MeterValue($0, period: period.last.attributes["NumMonth"] ?? "1") )
            }
            
            self.periods = []
            period.forEach {
                self.periods.append( CounterPeriod($0) )
            }
            
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
    
    private func getNameAndMonth(_ number_month: String) -> String {
        
        if number_month == "1" {
            return "Январь"
        } else if number_month == "2" {
            return "Февраль"
        } else if number_month == "3" {
            return "Март"
        } else if number_month == "4" {
            return "Апрель"
        } else if number_month == "5" {
            return "Май"
        } else if number_month == "6" {
            return "Июнь"
        } else if number_month == "7" {
            return "Июль"
        } else if number_month == "8" {
            return "Август"
        } else if number_month == "9" {
            return "Сентябрь"
        } else if number_month == "10" {
            return "Октябрь"
        } else if number_month == "11" {
            return "Ноябрь"
        } else {
            return "Декабрь"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCounterTableVC.toStatement {
            let date = (periods[0].periodDate ?? "").split(separator: ".")
            
            let vc = segue.destination as! CounterStatementVC
            vc.value_   = meterArr[index]
            vc.month_   = getNameAndMonth(periods[0].numMonth ?? "1")
            vc.date_    =  date[0] + " " + getNameAndMonth(periods[0].numMonth ?? "1") + " " + (periods[0].year ?? "")
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromCounterTableVC.toHistory {
            let vc     = segue.destination as! CounterHistoryTableVC
            vc.data_   = meterArr
            vc.period_ = periods
        }
    }
    
    func update() {
        getCounters()
    }
}

final class CounterTableHeaderCell: UICollectionReusableView, CounterVCDelegate {
    
    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var history: UIButton!
    
    @IBAction private func historyTapped(_ sender: UIButton) {
        delegate?.pressed("История")
    }
    
    private var delegate: CounterTableCellDelegate?
    
    fileprivate func display(_ item: String, delegate: CounterTableCellDelegate) {
        
        self.delegate    = delegate
        title.text       = item
        self.delegate?.setDelegate(self)
    }
    
    func stopAnimator() {
        self.history.isHidden = false
        self.loader.isHidden  = true
        self.loader.stopAnimating()
    }
    func startAnimator() {
        self.loader.isHidden  = false
        self.loader.startAnimating()
        self.history.isHidden = true
    }
}

final class CounterTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var count:   UILabel!
    
    fileprivate func display(_ item: MeterValue) {
        
        title.text = item.name
        count.text = item.value != "0,00" ? item.value : ""
        desc.text  = item.meterUniqueNum
    }
}

struct MeterValue {
    
    let fractionalNumber:   String?
    let units:              String?
    let previousValue:      String?
    let name:               String?
    let resource:           String?
    let previousValueInput: String?
    let difference: 	    String?
    let differenceInput: 	String?
    let meterUniqueNum:     String?
    let value:              String?
    let valueInput: 	    String?
    let previousPeriod:     String?
    let period:             String?
    
    init(_ row: XML.Accessor, period: String) {
        
        self.period         = period
        fractionalNumber    = row.attributes["FractionalNumber"]
        units               = row.attributes["Units"]
        previousValue       = row.attributes["PreviousValue"]
        name                = row.attributes["Name"]
        resource            = row.attributes["Resource"]
        previousValueInput  = row.attributes["PreviousValueInput"]
        difference          = row.attributes["Difference"]
        differenceInput     = row.attributes["DifferenceInput"]
        meterUniqueNum      = row.attributes["MeterUniqueNum"]
        value               = row.attributes["Value"]
        valueInput          = row.attributes["ValueInput"]
        previousPeriod      = row.attributes["PreviousPeriod"]
    }
}

struct CounterPeriod {
    
    let periodDate: String?
    let numMonth:   String?
    let lastModf:   String?
    let year:       String?
    
    let perXml:     XML.Accessor
    
    init(_ row: XML.Accessor) {
        
        perXml      = row
        periodDate  = row.attributes["PeriodDate"]
        numMonth    = row.attributes["NumMonth"]
        lastModf    = row.attributes["LastModified"]
        year        = row.attributes["Year"]
    }
}











