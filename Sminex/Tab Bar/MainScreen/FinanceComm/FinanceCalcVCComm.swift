//
//  FinanceCalcVCComm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 18/07/2019.
//

import UIKit
protocol PayDelegate{
    func requestPay(debt: String, indexPath: IndexPath)
    func goCalc(indexPath: IndexPath)
}
class FinanceCalcVCComm: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PayDelegate {
    
    @IBOutlet weak var collection: UICollectionView!
    @IBOutlet weak var collectionYear: UICollectionView!
    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    private var yearArr: [CalcYearCellData] = []
    public var data_: [AccountCalculationsJson] = []
    var dataYear = [Int:[AccountCalculationsJson]]()
    public var dataDebt: [AccountBillsJson] = []
    public var filteredCalcs: [AccountCalculationsJson] = []
    public var calcs: [AccountCalculationsJson] = []
    public var index = Int()
    public var date: (Int?, Int?)
    var dateArr: [(Int?, Int?)] = []
    @IBAction func SwipeRight(_ sender: UISwipeGestureRecognizer) {
        if index > 0{
            self.startAnimation()
            DispatchQueue.global(qos: .background).async {
                self.index -= 1
                self.selType = self.index
                DispatchQueue.main.async {
                    self.collectionYear?.selectItem(at: [0, self.index], animated: true, scrollPosition: .centeredVertically)
                    self.collectionYear.reloadData()
                    if self.collectionYear?.dataSource?.collectionView(self.collectionYear!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
                        let rect = self.collectionYear.layoutAttributesForItem(at: IndexPath(item: self.index, section: 0))?.frame
                        self.collectionYear.setContentOffset(CGPoint(x: (rect?.origin.x)!, y: 0), animated: true)
                    }
                }
                var s = 0
                for k in 0...self.filteredCalcs.count - 1{
                    let d = self.filteredCalcs[k].numYearSet! - self.date.1!
                    if d == 1 && s == 0{
                        s = 1
                        self.date = (self.filteredCalcs[k].numMonthSet, self.filteredCalcs[k].numYearSet)
                    }
                }
                self.data_ = self.calcs.filter {
                    return self.date.1 == $0.numYearSet
                }
                var year = self.date.1
                var month = 0
                self.dateArr.removeAll()
                if self.data_.count != 0{
                    var cont = false
                    for k in 0...self.data_.count - 1{
                        if !cont{
                            if (self.data_[k].type?.containsIgnoringCase(find: "пени"))!{
                                if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                    self.data_.remove(at: k)
                                    cont = true
                                }
                            }
                        }
                        if self.data_[k].numMonthSet != month && self.data_[k].numYearSet == year{
                            month = self.data_[k].numMonthSet!
                            year = self.data_[k].numYearSet!
                            self.dateArr.append((self.data_[k].numMonthSet!, self.data_[k].numYearSet!))
                        }
                    }
                }
                self.dataYear.removeAll()
                for i in 0...self.dateArr.count - 1{
                    var dat: [AccountCalculationsJson] = []
                    for k in 0...self.data_.count - 1{
                        if self.dateArr[i].0 == self.data_[k].numMonthSet!{
                            dat.append(self.data_[k])
                        }
                    }
                    self.dataYear[i] = dat
                }
                DispatchQueue.main.async {
                    self.collection.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                    self.collection.reloadData()
                    self.stopAnimation()
                }
            }
        }
    }
    
    @IBAction func SwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if index < yearArr.count - 1{
            self.startAnimation()
            DispatchQueue.global(qos: .background).async {
                self.index += 1
                self.selType = self.index
                DispatchQueue.main.async {
                    self.collectionYear?.selectItem(at: [0, self.index], animated: true, scrollPosition: .centeredVertically)
                    self.collectionYear?.reloadData()
                    if self.collectionYear?.dataSource?.collectionView(self.collectionYear!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
                        let rect = self.collectionYear.layoutAttributesForItem(at: IndexPath(item: self.index, section: 0))?.frame
                        self.collectionYear.setContentOffset(CGPoint(x: (rect?.origin.x)!, y: 0), animated: true)
                    }
                }
                
                var s = 0
                for k in 0...self.filteredCalcs.count - 1{
                    let d = self.date.1! - self.filteredCalcs[k].numYearSet!
                    if d == 1 && s == 0{
                        s = 1
                        self.date = (self.filteredCalcs[k].numMonthSet, self.filteredCalcs[k].numYearSet)
                    }
                }
                self.data_ = self.calcs.filter {
                    return self.date.1 == $0.numYearSet
                }
                var year = self.date.1
                var month = 0
                self.dateArr.removeAll()
                if self.data_.count != 0{
                    var cont = false
                    for k in 0...self.data_.count - 1{
                        if !cont{
                            if (self.data_[k].type?.containsIgnoringCase(find: "пени"))!{
                                if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                    self.data_.remove(at: k)
                                    cont = true
                                }
                            }
                        }
                        if self.data_[k].numMonthSet != month && self.data_[k].numYearSet == year{
                            month = self.data_[k].numMonthSet!
                            year = self.data_[k].numYearSet!
                            self.dateArr.append((self.data_[k].numMonthSet!, self.data_[k].numYearSet!))
                        }
                    }
                }
                self.dataYear.removeAll()
                for i in 0...self.dateArr.count - 1{
                    var dat: [AccountCalculationsJson] = []
                    for k in 0...self.data_.count - 1{
                        if self.dateArr[i].0 == self.data_[k].numMonthSet!{
                            dat.append(self.data_[k])
                        }
                    }
                    self.dataYear[i] = dat
                }
                DispatchQueue.main.async {
                    self.collection.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                    self.collection.reloadData()
                    self.stopAnimation()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "receiptArchive" {
            let vc = segue.destination as! FinanceDebtVCComm
            var dat: AccountBillsJson?
            dataDebt.forEach{
                if date.0 == $0.numMonth && date.1 == $0.numYear{
                    dat = $0
                }
            }
            vc.data_ = dat
        }
        if segue.identifier == "goPay" {
            let vc = segue.destination as! FinancePayVC
            vc.url_ = url
        }
    }
    
    func goCalc(indexPath: IndexPath) {
        var dat: AccountBillsJson?
        date = (dataYear[indexPath.section]![0].numMonthSet, dataYear[indexPath.section]![0].numYearSet)
        dataDebt.forEach{
            if date.0 == $0.numMonth && date.1 == $0.numYear{
                dat = $0
            }
        }
        if dat != nil{
            self.performSegue(withIdentifier: "receiptArchive", sender: self)
        }else{
            let alert = UIAlertController(title: "", message: "Не найдена квитанция по выбранной дате!", preferredStyle: .alert)
            alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
            self.present(alert, animated: true, completion: nil)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        
        collectionYear.delegate     = self
        collectionYear.dataSource   = self
        collectionYear.isHidden     = true
        yearArr.removeAll()
        var s = 0
        for k in 0...self.filteredCalcs.count - 1{
            if yearArr.count == 0{
                self.yearArr.append(CalcYearCellData(title: String(self.filteredCalcs[k].numYearSet!), id: "", year: self.filteredCalcs[k].numYearSet!, month: self.filteredCalcs[k].numMonthSet!))
            }else{
                yearArr.forEach{
                    if $0.year == self.filteredCalcs[k].numYearSet!{
                        s = 1
                    }
                }
                if s == 0{
                    self.yearArr.append(CalcYearCellData(title: String(self.filteredCalcs[k].numYearSet!), id: "", year: self.filteredCalcs[k].numYearSet!, month: self.filteredCalcs[k].numMonthSet!))
                }
                s = 0
            }
        }
    }
    
    var load = true
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if load{
            for i in 0...self.yearArr.count - 1{
                if self.date.1 == self.yearArr[i].year{
                    self.index = i
                }
            }
            self.selType = self.index
            load = false
            self.startAnimation()
            DispatchQueue.global(qos: .background).async {
                var year = self.date.1
                var month = 0
                print(self.date)
                if self.data_.count != 0{
                    var cont = false
                    for k in 0...self.data_.count - 1{
                        if !cont{
                            if (self.data_[k].type?.containsIgnoringCase(find: "пени"))!{
                                if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                    self.data_.remove(at: k)
                                    cont = true
                                }
                            }
                        }
                        if self.data_[k].numMonthSet != month && self.data_[k].numYearSet == year{
                            month = self.data_[k].numMonthSet!
                            year = self.data_[k].numYearSet!
                            self.dateArr.append((self.data_[k].numMonthSet!, self.data_[k].numYearSet!))
                        }
                    }
                }
                for i in 0...self.dateArr.count - 1{
                    var dat: [AccountCalculationsJson] = []
                    for k in 0...self.data_.count - 1{
                        if self.dateArr[i].0 == self.data_[k].numMonthSet!{
                            dat.append(self.data_[k])
                        }
                    }
                    self.dataYear[i] = dat
                }
                DispatchQueue.main.async {
                    var selSection = 0
                    var selYear = 0
                    for k in 0...self.yearArr.count - 1{
                        if self.yearArr[k].year == self.date.1{
                            selYear = k
                        }
                    }
                    for i in 0...self.dateArr.count - 1{
                        if self.dateArr[i].0 == self.date.0{
                            selSection = i
                        }
                    }
                    self.collectionYear.reloadData()
                    if self.collectionYear?.dataSource?.collectionView(self.collectionYear!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
                        let rect = self.collectionYear.layoutAttributesForItem(at: IndexPath(item: selYear, section: 0))?.frame
                        self.collectionYear.setContentOffset(CGPoint(x: (rect?.origin.x)!, y: 0), animated: true)
                    }
                    self.collection.reloadData()
                    //                    if self.collection.dataSource?.collectionView(self.collection, cellForItemAt: IndexPath(row: 0, section: 0)) != nil{
                    //                        if selSection != 0{
                    //                            self.collection.scrollToItem(at: IndexPath(item: self.dataYear[selSection - 1]!.count, section: selSection - 1), at: .top, animated: true)
                    //                        }
                    //                    }
                    if self.collection?.dataSource?.collectionView(self.collection!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
                        let rect = self.collection.layoutAttributesForItem(at: IndexPath(item: 0, section: selSection))?.frame
                        self.collection.setContentOffset(CGPoint(x: 0, y: (rect?.origin.y)! - 50), animated: true)
                    }
                    self.collectionYear.isHidden = false
                    self.stopAnimation()
                }
            }
        }
    }
    
    func loadData(){
        self.startAnimation()
        DispatchQueue.global(qos: .background).async {
            self.index = self.selType
//            var s = 0
//            for k in 0...self.filteredCalcs.count - 1{
//                let d = self.filteredCalcs[k].numYearSet! - self.date.1!
//                if d == 1 && s == 0{
//                    s = 1
//                    self.date = (self.filteredCalcs[k].numMonthSet, self.filteredCalcs[k].numYearSet)
//                }
//            }
            self.data_ = self.calcs.filter {
                return self.date.1 == $0.numYearSet
            }
            var year = self.date.1
            var month = 0
            self.dateArr.removeAll()
            if self.data_.count != 0{
                var cont = false
                for k in 0...self.data_.count - 1{
                    if !cont{
                        if (self.data_[k].type?.containsIgnoringCase(find: "пени"))!{
                            if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                self.data_.remove(at: k)
                                cont = true
                            }
                        }
                    }
                    if self.data_[k].numMonthSet != month && self.data_[k].numYearSet == year{
                        month = self.data_[k].numMonthSet!
                        year = self.data_[k].numYearSet!
                        self.dateArr.append((self.data_[k].numMonthSet!, self.data_[k].numYearSet!))
                    }
                }
            }
            self.dataYear.removeAll()
            for i in 0...self.dateArr.count - 1{
                var dat: [AccountCalculationsJson] = []
                for k in 0...self.data_.count - 1{
                    if self.dateArr[i].0 == self.data_[k].numMonthSet!{
                        dat.append(self.data_[k])
                    }
                }
                self.dataYear[i] = dat
            }
            DispatchQueue.main.async {
                self.collection.reloadData()
                self.stopAnimation()
            }
        }
    }
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.collection{
            if dataYear.count != 0{
                return dataYear.count
            }else{
                return 0
            }
        }else{
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.collection{
            return dataYear[section]!.count == 0 ? 0 : dataYear[section]!.count + 1
        }else{
            return yearArr.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0.0
        if collectionView == self.collection{
            let cell = FinanceCalcCommCell.fromNib()
            if indexPath.row != dataYear[indexPath.section]!.count {
                cell?.display(dataYear[indexPath.section]![indexPath.row], pay: self, indexPath: indexPath)
            } else {
                cell?.display( AccountCalculationsJson(type: "Итого", sumAccrued: 0, sumDebt: 0, sumPay: 0), pay: self, indexPath: indexPath)
                var sumDebt     = 0.0
                
                dataYear[indexPath.section]!.forEach {
                    sumDebt     += $0.sumDebt       ?? 0.0
                }
                if sumDebt > 0.00{
                    height = 50
                }else{
                    height = 0
                }
            }
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width, height: size.height + height)
        }else{
            let cell = CalcYearCell.fromNib()
            if firstLoad && indexPath.row == 0{
                firstLoad = false
                cell?.display(yearArr[indexPath.row], selectIndex: true)
            }else if selType == indexPath.row{
                cell?.display(yearArr[indexPath.row], selectIndex: true)
            }else{
                cell?.display(yearArr[indexPath.row], selectIndex: false)
            }
            return CGSize(width: view.frame.size.width / 3, height: 40)
        }
    }
    var firstLoad = true
    var selType = 0
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == collection{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceCalcCommCell", for: indexPath) as! FinanceCalcCommCell
            if indexPath.row != dataYear[indexPath.section]!.count {
                cell.display(dataYear[indexPath.section]![indexPath.row], pay: self, indexPath: indexPath)
            } else {
                var sumAccured  = 0.0
                var sumDebt     = 0.0
                var sumPay      = 0.0
                
                dataYear[indexPath.section]!.forEach {
                    sumAccured  += $0.sumAccrued    ?? 0.0
                    sumDebt     += $0.sumDebt       ?? 0.0
                    sumPay      += $0.sumPay        ?? 0.0
                }
                
                cell.display( AccountCalculationsJson(type: "Итого", sumAccrued: sumAccured, sumDebt: sumDebt, sumPay: sumPay), pay: self, indexPath: indexPath)
            }
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalcYearCell", for: indexPath) as! CalcYearCell
            if firstLoad && indexPath.row == 0{
                firstLoad = false
                cell.display(yearArr[indexPath.row], selectIndex: true)
            }else if selType == indexPath.row{
                cell.display(yearArr[indexPath.row], selectIndex: true)
            }else{
                cell.display(yearArr[indexPath.row], selectIndex: false)
            }
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceCalcCommHeader", for: indexPath) as! FinanceCalcCommHeader
        header.display(getNameAndMonth(dateArr[indexPath.section].0!) + " \(dateArr[indexPath.section].1!)")
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionYear{
            self.startAnimation()
            selType = indexPath.row
            collectionYear?.reloadData()
            self.date = (self.yearArr[selType].month, self.yearArr[selType].year)
            loadData()
        }
    }
    
    private var url: URLRequest!
    func requestPay(debt: String, indexPath: IndexPath) {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        var billsData_: AccountBillsJson?
        for i in 0...dataDebt.count - 1 {
            date = (dataYear[indexPath.section]![0].numMonthSet, dataYear[indexPath.section]![0].numYearSet)
            if date.0 == dataDebt[i].numMonth && date.1 == dataDebt[i].numYear{
                billsData_ = dataDebt[i]
            }
        }
        let number_bills = billsData_?.number_eng
        let date_bills   = billsData_?.datePay
        var url_str = Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + pwd
        url_str = url_str + "&amount=" + debt.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        if (number_bills != nil) {
            url_str = url_str + "&invoiceNumber=" + number_bills!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            url_str = url_str + "&date=" + date_bills!.replacingOccurrences(of: " 00:00:00", with: "").addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        }
        
        var request = URLRequest(url: URL(string: url_str)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: String(data: data!, encoding: .utf8)?.replacingOccurrences(of: "error: ", with: "") ?? "", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            //            self.str_url = String(data: data!, encoding: .utf8)!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            //            self.str_url = self.str_url.replacingOccurrences(of: "https%3A", with: "https:")
            
            // Костыль
            let str_url = String(data: data!, encoding: .utf8)!//.replacingOccurrences(of: " ", with: "")
            
            //            let index = self.str_url.index(self.str_url.startIndex, offsetBy: 39)
            //            var str1 = self.str_url.substring(to: index)
            //            var str2 = self.str_url.suffix(self.str_url.length - 39)
            //
            //            self.str_url = str1 + str2.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlPathAllowed)!
            self.url = URLRequest(url: URL(string: str_url)!)
            
            DispatchQueue.main.sync {
                self.performSegue(withIdentifier: "goPay", sender: self)
            }
            
            #if DEBUG
            //            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
    }
    
    func startAnimation() {
        self.collection.isHidden  = true
        self.loader.isHidden = false
        self.loader.startAnimating()
    }
    
    func stopAnimation() {
        self.loader.stopAnimating()
        self.loader.isHidden = true
        self.collection.isHidden  = false
    }
}

final class FinanceCalcCommHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    fileprivate func display(_ title: String) {
        self.title.text = title
    }
}

final class FinanceCalcCommCell: UICollectionViewCell {
    
    @IBOutlet private weak var headerStack: UIStackView!
    @IBOutlet private weak var headerHeight: NSLayoutConstraint!
    @IBOutlet private weak var sumAccured:  UILabel!
    @IBOutlet private weak var sumDebt:     UILabel!
    @IBOutlet private weak var sumPay:      UILabel!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var payBtn:      UIButton!
    @IBOutlet private weak var goDebt:      UIButton!
    @IBOutlet private weak var payHeight:   NSLayoutConstraint!
    @IBOutlet private weak var payTop:      NSLayoutConstraint!
    @IBOutlet private weak var debtHeight:   NSLayoutConstraint!
    @IBOutlet private weak var debtTop:      NSLayoutConstraint!
    var indexPath = IndexPath()
    @IBAction private func goPay(_ sender: UIButton) {
        self.delegate?.requestPay(debt: sumDebt.text!, indexPath: self.indexPath)
    }
    
    @IBAction private func goCalc(_ sender: UIButton) {
        self.delegate?.goCalc(indexPath: self.indexPath)
    }
    var delegate: PayDelegate?
    fileprivate func display(_ item: AccountCalculationsJson, pay: PayDelegate, indexPath: IndexPath) {
        self.indexPath = indexPath
        self.delegate = pay
        if indexPath.row != 0{
            headerStack.isHidden = true
            headerHeight.constant = 0
        }else{
            headerStack.isHidden = false
            headerHeight.constant = 20
        }
        if item.type != "Итого"{
            payBtn.isHidden = true
            payHeight.constant = 0
            payTop.constant = 0
            goDebt.isHidden = true
            debtHeight.constant = 0
            debtTop.constant = 0
        }else{
            if item.sumDebt! > 0.00{
                payBtn.isHidden = false
                payHeight.constant = 40
                payTop.constant = 15
            }else{
                payBtn.isHidden = true
                payHeight.constant = 0
                payTop.constant = 0
            }
            goDebt.isHidden = false
            debtHeight.constant = 40
            debtTop.constant = 15
        }
        var sumA = String(format:"%.2f", item.sumAccrued!)
        if item.sumAccrued! > 999.00 || item.sumAccrued! < -999.00{
            let i = Int(sumA.distance(from: sumA.startIndex, to: sumA.index(of: ".")!)) - 3
            sumA.insert(" ", at: sumA.index(sumA.startIndex, offsetBy: i))
        }
        if sumA.first == "-" {
            sumA.insert(" ", at: sumA.index(sumA.startIndex, offsetBy: 1))
        }
        sumAccured.text = sumA.replacingOccurrences(of: ".", with: ",")
        
        var sumD = String(format:"%.2f", item.sumDebt!)
        if item.sumDebt! > 999.00 || item.sumDebt! < -999.00{
            let i = Int(sumD.distance(from: sumD.startIndex, to: sumD.index(of: ".")!)) - 3
            sumD.insert(" ", at: sumD.index(sumD.startIndex, offsetBy: i))
        }
        if sumD.first == "-" {
            sumD.insert(" ", at: sumD.index(sumD.startIndex, offsetBy: 1))
        }
        sumDebt.text = sumD.replacingOccurrences(of: ".", with: ",")
        
        var sumP = String(format:"%.2f", item.sumPay!)
        if item.sumPay! > 999.00 || item.sumPay! < -999.00{
            let i = Int(sumP.distance(from: sumP.startIndex, to: sumP.index(of: ".")!)) - 3
            sumP.insert(" ", at: sumP.index(sumP.startIndex, offsetBy: i))
        }
        if sumP.first == "-" {
            sumP.insert(" ", at: sumP.index(sumP.startIndex, offsetBy: 1))
        }
        sumPay.text = sumP.replacingOccurrences(of: ".", with: ",")
        title.text = item.type
        
//        if item.type == "Итого" {
//            sumAccured.font = UIFont.boldSystemFont(ofSize: sumAccured.font.pointSize)
//            sumDebt.font    = UIFont.boldSystemFont(ofSize: sumDebt.font.pointSize)
//            sumPay.font     = UIFont.boldSystemFont(ofSize: sumPay.font.pointSize)
//            title.font      = UIFont.boldSystemFont(ofSize: title.font.pointSize)
//
//        } else {
            sumAccured.font = UIFont.systemFont(ofSize: sumAccured.font.pointSize, weight: .light)
            sumDebt.font    = UIFont.systemFont(ofSize: sumDebt.font.pointSize, weight: .light)
            sumPay.font     = UIFont.systemFont(ofSize: sumPay.font.pointSize, weight: .light)
            title.font      = UIFont.systemFont(ofSize: title.font.pointSize, weight: .light)
//        }
    }
    
    class func fromNib() -> FinanceCalcCommCell? {
        var cell: FinanceCalcCommCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? FinanceCalcCommCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 75
        return cell
    }
}

final class CalcYearCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var selLine:         UILabel!
    
    private var type: String?
    
    fileprivate func display(_ item: CalcYearCellData, selectIndex: Bool) {
        title.text = item.title
        if selectIndex{
            selLine.backgroundColor = .darkGray
        }else{
            selLine.backgroundColor = .lightGray
        }
    }
    
    class func fromNib() -> CalcYearCell? {
        var cell: CalcYearCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? CalcYearCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        return cell
    }
}

private final class CalcYearCellData {
    
    let title:      String
    let id:         String
    let year:       Int
    let month:      Int
    
    init(title: String, id: String, year: Int, month: Int) {
        
        self.title      = title
        self.id         = id
        self.year       = year
        self.month      = month
    }
}
