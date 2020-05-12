//
//  FinanceCalcVC3Comm.swift
//  Sminex
//
//  Created by Sergey Ivanov on 22/08/2019.
//

import UIKit

protocol PayDelegate{
    func requestPay(debt: String, indexPath: IndexPath)
    func goCalc(indexPath: IndexPath)
}

class FinanceCalcVC3Comm: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PayDelegate {
    
    @IBOutlet weak var collection: UICollectionView!
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    public var debt: AccountDebtJson?
    public var data_: [AccountCalculationsJson] = []
    public var dataDebt: [AccountBillsJson] = []
    public var filteredCalcs: [AccountCalculationsJson] = []
    public var calcs: [AccountCalculationsJson] = []
    public var index = Int()
    public var date: (Int?, Int?)
    var dateArr: [(Int?, Int?)] = []
    @IBAction func SwipeRight(_ sender: UISwipeGestureRecognizer) {
        if index > 0{
            self.index -= 1
            date = (filteredCalcs[index].numMonthSet, filteredCalcs[index].numYearSet)
            data_ = calcs.filter {
                return date.0 == $0.numMonthSet && date.1 == $0.numYearSet
            }
            if data_.count != 0{
                var cont = false
                for k in 0...data_.count - 1{
                    if !cont{
                        if (data_[k].type?.containsIgnoringCase(find: "пени"))!{
                            if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                data_.remove(at: k)
                                cont = true
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.collection.reloadData()
            }
        }
    }
    
    @IBAction func SwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if index < 2{
            self.index += 1
            date = (filteredCalcs[index].numMonthSet, filteredCalcs[index].numYearSet)
            data_ = calcs.filter {
                return date.0 == $0.numMonthSet && date.1 == $0.numYearSet
            }
            if data_.count != 0{
                var cont = false
                for k in 0...data_.count - 1{
                    if !cont{
                        if (data_[k].type?.containsIgnoringCase(find: "пени"))!{
                            if UserDefaults.standard.bool(forKey: "denyShowFine"){
                                data_.remove(at: k)
                                cont = true
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.collection.reloadData()
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
        if segue.identifier == Segues.fromFinanceDebtVC.toPay {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.billsData_ = self.billsData_
            vc.debt = self.debtA
        }
        if segue.identifier == Segues.fromFinanceVC.toCalcsArchive {
            let vc = segue.destination as! FinanceCalcsArchiveVCComm
            vc.debt = debt
            vc.dataDebt = dataDebt
            vc.data_ = calcs
            
        }
    }
    
    func goCalc(indexPath: IndexPath) {
        var dat: AccountBillsJson?
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
        if data_.count != 0{
            var cont = false
            for k in 0...data_.count - 1{
                if !cont{
                    if (data_[k].type?.containsIgnoringCase(find: "пени"))!{
                        if UserDefaults.standard.bool(forKey: "denyShowFine"){
                            data_.remove(at: k)
                            cont = true
                        }
                    }
                }
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count == 0 ? 0 : data_.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 0.0
        let cell = FinanceCalcComm3Cell.fromNib()
        if indexPath.row != data_.count {
            cell?.display(data_[indexPath.row], pay: self, indexPath: indexPath)
        } else {
            var sumAccured  = 0.0
            var sumDebt     = 0.0
            var sumPay      = 0.0
            
            data_.forEach {
                sumAccured  += $0.sumAccrued    ?? 0.0
                sumDebt     += $0.sumDebt       ?? 0.0
                sumPay      += $0.sumPay        ?? 0.0
            }
            if sumDebt > 0.00{
                height = 85
            }else{
                height = 0
            }
            cell?.display( AccountCalculationsJson(type: "Итого", sumAccrued: 0, sumDebt: 0, sumPay: 0), pay: self, indexPath: indexPath)
        }
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width - 32, height: size.height + height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FinanceCalcComm3Cell", for: indexPath) as! FinanceCalcComm3Cell
        if indexPath.row != data_.count {
            cell.display(data_[indexPath.row], pay: self, indexPath: indexPath)
        } else {
            var sumAccured  = 0.0
            var sumDebt     = 0.0
            var sumPay      = 0.0
            
            data_.forEach {
                sumAccured  += $0.sumAccrued    ?? 0.0
                sumDebt     += $0.sumDebt       ?? 0.0
                sumPay      += $0.sumPay        ?? 0.0
            }
            
            cell.display( AccountCalculationsJson(type: "Итого", sumAccrued: sumAccured, sumDebt: sumDebt, sumPay: sumPay), pay: self, indexPath: indexPath)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "FinanceCalcComm3Header", for: indexPath) as! FinanceCalcComm3Header
        header.display(getNameAndMonth(data_.first?.numMonthSet ?? 0) + " \(data_.first?.numYearSet ?? 0)")
        return header
    }
    private var url: URLRequest!
    var billsData_: AccountBillsJson?
    var debtA = ""
    func requestPay(debt: String, indexPath: IndexPath) {
        self.debtA = debt
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
}

final class FinanceCalcComm3Header: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    fileprivate func display(_ title: String) {
        self.title.text = title
    }
}

final class FinanceCalcComm3Cell: UICollectionViewCell {
    
    @IBOutlet private weak var botConst:    NSLayoutConstraint!
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
            botConst.constant = 0
        }else{
            if item.sumDebt! > 0.00{
                payBtn.isHidden = false
                payHeight.constant = 48
                payTop.constant = 15
                botConst.constant = 20
            }else{
                payBtn.isHidden = true
                payHeight.constant = 0
                payTop.constant = 15
                botConst.constant = 0
            }
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
    
    class func fromNib() -> FinanceCalcComm3Cell? {
        var cell: FinanceCalcComm3Cell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? FinanceCalcComm3Cell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 75
        return cell
    }
}
