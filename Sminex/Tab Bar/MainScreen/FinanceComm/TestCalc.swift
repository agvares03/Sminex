//
//  TestCalc.swift
//  Sminex
//
//  Created by Sergey Ivanov on 26/08/2019.
//

import UIKit
import ExpyTableView

class TestCalc: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PayDelegate, UITableViewDelegate, UITableViewDataSource, ExpyTableViewDataSource, ExpyTableViewDelegate {
    
    @IBOutlet weak var collectionYear:  UICollectionView!
    @IBOutlet weak var table:           ExpyTableView!
    @IBOutlet private weak var loader:  UIActivityIndicatorView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
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
                        let pointX = (self.view.frame.size.width / 2) - (self.view.frame.size.width / 3) / 2
                        self.collectionYear.setContentOffset(CGPoint(x: ((rect?.origin.x)! - pointX), y: 0), animated: true)
                    }
                }
//                var s = 0
//                for k in 0...self.filteredCalcs.count - 1{
//                    let d = self.filteredCalcs[k].numYearSet! - self.date.1!
//                    if d == 1 && s == 0{
//                        s = 1
//                        self.date = (self.filteredCalcs[k].numMonthSet, self.filteredCalcs[k].numYearSet)
//                    }
//                }
                self.date = (self.yearArr[self.index].month, self.yearArr[self.index].year)
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
                    self.table.reloadData()
                    let indexPath = NSIndexPath(row: 0, section: 0)
                    self.table.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
                    
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
                        let pointX = (self.view.frame.size.width / 2) - (self.view.frame.size.width / 3) / 2
                        self.collectionYear.setContentOffset(CGPoint(x: ((rect?.origin.x)! - pointX), y: 0), animated: true)
                    }
                }
                
//                var s = 0
//                for k in 0...self.filteredCalcs.count - 1{
//                    let d = self.date.1! - self.filteredCalcs[k].numYearSet!
//                    if d == 1 && s == 0{
//                        s = 1
//                        self.date = (self.filteredCalcs[k].numMonthSet, self.filteredCalcs[k].numYearSet)
//                    }
//                }
                self.date = (self.yearArr[self.index].month, self.yearArr[self.index].year)
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
                    self.table.reloadData()
                    let indexPath = NSIndexPath(row: 0, section: 0)
                    self.table.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
                    
                    self.stopAnimation()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "receiptArchive" {
            let vc = segue.destination as! FinanceDebtVCComm
            var dat: [AccountBillsJson] = []
            dataDebt.forEach{
                if date.0 == $0.numMonth && date.1 == $0.numYear{
                    dat.append($0)
                }
            }
            vc.data_ = dat
        }
        if segue.identifier == "goPay" {
        let vc = segue.destination as! FinancePayVC
            vc.url_ = url
        }
        if segue.identifier == Segues.fromFinanceDebtVC.toPay {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.billsData_ = self.billsData_
            vc.debt = self.debt
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
        table.dataSource    = self
        table.delegate      = self
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
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
                        let pointX = (self.view.frame.size.width / 2) - (self.view.frame.size.width / 3) / 2
                        self.collectionYear.setContentOffset(CGPoint(x: ((rect?.origin.x)! - pointX), y: 0), animated: true)
                    }
                    self.table.reloadData()
                    //                    if self.collection.dataSource?.collectionView(self.collection, cellForItemAt: IndexPath(row: 0, section: 0)) != nil{
                    //                        if selSection != 0{
                    //                            self.collection.scrollToItem(at: IndexPath(item: self.dataYear[selSection - 1]!.count, section: selSection - 1), at: .top, animated: true)
                    //                        }
                    //                    }
                    if self.table?.dataSource?.tableView(self.table!, cellForRowAt: IndexPath(row: 0, section: 0)) != nil {
                        let indexPath = NSIndexPath(row: 0, section: selSection)
                        self.table.scrollToRow(at: indexPath as IndexPath, at: .top, animated: false)
                        self.table.expand(selSection)
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
                self.table.reloadData()
                self.stopAnimation()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if dataYear.count != 0{
            return dataYear.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: ExpyTableView, expandableCellForSection section: Int) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCalcHeader") as! TestCalcHeader
        cell.display(getNameAndMonth(dateArr[section].0!) + " \(dateArr[section].1!)")
        
        //do other header related calls or settups
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataYear[section]!.count + 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestCalcCell") as! TestCalcCell
        if indexPath.row < dataYear[indexPath.section]!.count + 1 {
//            print(indexPath.row, dataYear[indexPath.section]!.count)
//            if dataYear[indexPath.section]![indexPath.row - 1] != nil{
                cell.display(dataYear[indexPath.section]![indexPath.row - 1], pay: self, indexPath: indexPath)
//            }
            
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
    }
    
    func tableView(_ tableView: ExpyTableView, expyState state: ExpyState, changeForSection section: Int) {
        
        if state == .willExpand {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! TestCalcHeader
            cell.expand(true)
            
        } else if state == .willCollapse {
            let index = IndexPath(row: 0, section: section)
            let cell = tableView.cellForRow(at: index) as! TestCalcHeader
            cell.expand(false)
        }
    }
    
    func tableView(_ tableView: ExpyTableView, canExpandSection section: Int) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return yearArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        var height: CGFloat = 0.0
        let cell = CalcYearCell1.fromNib()
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
    var firstLoad = true
    var selType = 0
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalcYearCell1", for: indexPath) as! CalcYearCell1
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.collectionYear{
            self.startAnimation()
            selType = indexPath.row
            collectionYear?.reloadData()
            if self.collectionYear?.dataSource?.collectionView(self.collectionYear!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
                let rect = self.collectionYear.layoutAttributesForItem(at: IndexPath(item: selType, section: 0))?.frame
                let pointX = (self.view.frame.size.width / 2) - (self.view.frame.size.width / 3) / 2
                self.collectionYear.setContentOffset(CGPoint(x: ((rect?.origin.x)! - pointX), y: 0), animated: true)
            }
            self.date = (self.yearArr[selType].month, self.yearArr[selType].year)
            loadData()
        }
    }
    
    private var url: URLRequest!
    var billsData_: AccountBillsJson?
    var debt = ""
    func requestPay(debt: String, indexPath: IndexPath) {
        self.debt = debt
        date = (dataYear[indexPath.section]![0].numMonthSet, dataYear[indexPath.section]![0].numYearSet)
        for i in 0...dataDebt.count - 1 {
            if date.0 == dataDebt[i].numMonth && date.1 == dataDebt[i].numYear{
                self.billsData_ = dataDebt[i]
            }
        }
        if billsData_ != nil{
            performSegue(withIdentifier: Segues.fromFinanceDebtVC.toPay, sender: self)
        }else{
            DispatchQueue.main.async{
                let alert = UIAlertController(title: "", message: "Не найдена квитанция по выбранной дате!", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func startAnimation() {
        self.table.isHidden  = true
        self.loader.isHidden = false
        self.loader.startAnimating()
    }
    
    func stopAnimation() {
        self.loader.stopAnimating()
        self.loader.isHidden = true
        self.table.isHidden  = false
    }
}

final class TestCalcHeader: UITableViewCell, ExpyTableViewHeaderCell {
    
    @IBOutlet private weak var title: UILabel!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var squareView: UIView!
    
    fileprivate func display(_ title: String) {
        self.title.text = title
        self.circleView.isHidden = false
        self.squareView.isHidden = true
        self.img.image = UIImage(named: "expand")
    }
    
    func changeState(_ state: ExpyState, cellReuseStatus cellReuse: Bool) {
        switch state {
        case .willExpand:
            self.circleView.isHidden = true
            self.squareView.isHidden = false
            self.img.image = UIImage(named: "expanded")
        case .willCollapse:
            self.circleView.isHidden = false
            self.squareView.isHidden = true
            self.img.image = UIImage(named: "expand")
        case .didExpand:
            self.circleView.isHidden = true
            self.squareView.isHidden = false
            self.img.image = UIImage(named: "expanded")
        case .didCollapse:
            self.circleView.isHidden = false
            self.squareView.isHidden = true
            self.img.image = UIImage(named: "expand")
        }
    }
    
    func expand(_ isExpanded: Bool) {
        if !isExpanded {
            self.circleView.isHidden = false
            self.squareView.isHidden = true
            self.img.image = UIImage(named: "expand")
            
        } else {
            self.circleView.isHidden = true
            self.squareView.isHidden = false
            self.img.image = UIImage(named: "expanded")
        }
    }
}

final class TestCalcCell: UITableViewCell {
    
    @IBOutlet private weak var headerStack: UIStackView!
    @IBOutlet private weak var headerHeight: NSLayoutConstraint!
    @IBOutlet private weak var botConst:    NSLayoutConstraint!
    @IBOutlet private weak var sumAccured:  UILabel!
    @IBOutlet private weak var sumDebt:     UILabel!
    @IBOutlet private weak var sumPay:      UILabel!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var payBtn:      UIButton!
    @IBOutlet private weak var goDebt:      UIButton!
    @IBOutlet private weak var botView:     UIView!
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
        if indexPath.row != 0 && indexPath.row != 1{
            headerStack.isHidden = true
            headerHeight.constant = 0
        }else{
            headerStack.isHidden = false
            headerHeight.constant = 20
        }
        if item.type != "Итого"{
            botConst.constant = 0
            payBtn.isHidden = true
            payHeight.constant = 0
            payTop.constant = 0
            goDebt.isHidden = true
            debtHeight.constant = 0
            debtTop.constant = 0
            botView.isHidden = true
            botView.cornerRadius = 0
        }else{
            if item.sumDebt! > 0.00{
                payBtn.isHidden = false
                payHeight.constant = 48
                payTop.constant = 15
            }else{
                payBtn.isHidden = true
                payHeight.constant = 0
                payTop.constant = 0
            }
            botView.isHidden = false
            botConst.constant = 20
            botView.cornerRadius = 24
            goDebt.isHidden = false
            debtHeight.constant = 20
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
            sumDebt.textColor = mainOrangeColor
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
    
    class func fromNib() -> TestCalcCell? {
        var cell: TestCalcCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? TestCalcCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 75
        return cell
    }
}

final class CalcYearCell1: UICollectionViewCell {
    
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var selLine:         UILabel!
    
    private var type: String?
    
    fileprivate func display(_ item: CalcYearCellData, selectIndex: Bool) {
        title.text = item.title
        if selectIndex{
            selLine.backgroundColor = mainGreenColor
            title.textColor = mainGreenColor
        }else{
            selLine.backgroundColor = .lightGray
            title.textColor = .lightGray
        }
    }
    
    class func fromNib() -> CalcYearCell1? {
        var cell: CalcYearCell1?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? CalcYearCell1 {
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

extension UITableView {
    func reloadData(completion:@escaping ()->()) {
        UIView.animate(withDuration: 0, animations: { self.reloadData() })
            { _ in completion() }
    }
}
