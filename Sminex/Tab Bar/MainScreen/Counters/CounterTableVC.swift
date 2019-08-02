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
    
    public var canCount = true
    
    private var refreshControl: UIRefreshControl?
    private var barTitle = ""
    private var index = 0
    private var meterArr: [MeterValue] = []
    private var periods: [CounterPeriod] = []
    private var delegate: CounterVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barTitle = tabBarController?.tabBar.selectedItem?.title ?? ""
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        delegate?.startAnimator()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
            collection.alwaysBounceVertical = true
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.getCounters()
        }
        updateUserInterface()
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        DispatchQueue.global(qos: .userInteractive).async {
            self.getCounters()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.selectedItem?.title = barTitle
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
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
        return CGSize(width: view.frame.size.width, height: 73)
        
        // Цель нижеследующей логики не понятна, поэтому закоментирована
        
        /*let cell = CounterTableCell.fromNib()
        cell?.display(meterArr[indexPath.row])
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        
        // Разное определение высоты для разных устройств
        var numb_to_move:CGFloat = 25;
        if (UIDevice.current.modelName.contains(find: "iPhone 4")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 4s")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5c")) ||
            (UIDevice.current.modelName.contains(find: "iPhone 5s")) ||
            (UIDevice.current.modelName.contains(find: "Simulator")) {
            numb_to_move = 15;
        }
        
        if (size.height < 78) {
            if (size.height < 71) {
                return CGSize(width: view.frame.size.width, height: size.height)
            } else {
                return CGSize(width: view.frame.size.width, height: 78 - numb_to_move)
            }
        } else {
            return CGSize(width: view.frame.size.width, height: size.height - numb_to_move)
        }*/
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CounterTableHeaderCell", for: indexPath) as! CounterTableHeaderCell
            
            if periods.count > 0 {
                header.display(getNameAndMonth(periods.first?.numMonth ?? "1") + " " + (periods.first?.year ?? ""), delegate: self)
                
            } else {
                header.display("", delegate: self)
            }
            return header
            
        } else {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CounterTableFooterCell", for: indexPath) as! CounterTableFooterCell
            footer.display("", PeriodsCount: periods.count)
            return footer
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if let headerView = collectionView.visibleSupplementaryViews(ofKind: UICollectionElementKindSectionHeader).first as? CounterTableHeaderCell {
            headerView.layoutIfNeeded()
            
            if periods.count > 0 {
                return CGSize(width: collectionView.frame.width, height: 60)
            } else {
                return CGSize(width: collectionView.frame.width, height: 0)
            }
        }
        
        return CGSize(width: collectionView.frame.width, height: 60)
    }
    
    func pressed(_ named: String) {
        performSegue(withIdentifier: Segues.fromCounterTableVC.toHistory, sender: self)
    }
    
    func setDelegate(_ delegate: CounterVCDelegate) {
        self.delegate = delegate
    }
    
    private func getCounters() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass =  UserDefaults.standard.string(forKey: "pwd") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_METERS + "login=" + login.stringByAddingPercentEncodingForRFC3986()! + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            guard data != nil else { return }
            if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
                self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
            }
            if (String(data: data!, encoding: .utf8)?.contains(find: "error"))! {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            #if DEBUG
            print("счетчики:", String(data: data!, encoding: .utf8)!)
            #endif
            
            let xml = XML.parse(data!)
            let metersValues = xml["MetersValues"]
            let period = metersValues["Period"].reversed()
            guard period.count != 0 else {
                DispatchQueue.main.sync {
                    self.collection.reloadData()
                    self.delegate?.stopAnimator()
                    if #available(iOS 10.0, *) {
                        self.collection.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
                    }
                }
                return
            }
            let meterValue = period.first!["MeterValue"]
            
            var newMeters: [MeterValue] = []
            meterValue.forEach {
                newMeters.append( MeterValue($0, period: period.first?.attributes["NumMonth"] ?? "1") )
            }
            
            var newPeriods: [CounterPeriod] = []
            period.forEach {
                newPeriods.append( CounterPeriod($0) )
            }
            
            DispatchQueue.main.sync {
                self.meterArr = newMeters
                self.periods  = newPeriods
                self.collection.reloadData()
                self.delegate?.stopAnimator()
                
                if #available(iOS 10.0, *) {
                    self.collection.refreshControl?.endRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
                
            }
            
        }.resume()
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
            vc.period_ = periods
//            vc.month_   = getNameAndMonth(periods.last?.numMonth ?? "1")
            vc.month_   = getNameAndMonth(periods[0].numMonth ?? "1")
            vc.year_    = periods[0].year ?? ""
            vc.date_    = date[0] + " "
            vc.date_ = vc.date_! + getNameAndMonth(periods[0].numMonth ?? "1") + " " + (periods[0].year ?? "")
            vc.delegate = self
            
        
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
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

final class CounterTableFooterCell: UICollectionReusableView, CounterVCDelegate {
    func startAnimator() {
    }
    
    func stopAnimator() {
    }
    
    @IBOutlet weak var sendTo: UILabel!
    
    fileprivate func display(_ item: String, PeriodsCount: Int) {
        
        let dateFormatter = DateFormatter()
        let date = Date()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let comp: DateComponents = Calendar.current.dateComponents([.year, .month], from: date)
        let startOfMonth = Calendar.current.date(from: comp)!
        
        var comps2 = DateComponents()
        comps2.month = 1
        comps2.day = -1
        let endOfMonth = Calendar.current.date(byAdding: comps2, to: startOfMonth)
        let dateText = dateFormatter.string(from: endOfMonth!)
        
        if PeriodsCount > 0 {
            sendTo.text = "Передать до " + dateText
        } else {
            sendTo.text = "Нет данных по приборам учета"
        }
        
    }
    
}



final class CounterTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var count:   UILabel!
    
    fileprivate func display(_ item: MeterValue) {
        
        title.text = item.resource
        desc.text  = item.meterType! + ", " + item.meterUniqueNum!
        
        let value = String((item.value1?.split(separator: ",")[0])!)
        count.text = value != "0" ? value : ""
    }
    
    class func fromNib() -> CounterTableCell? {
        var cell: CounterTableCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? CounterTableCell {
                cell = view
            }
        }
        //cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        //cell?.desc.preferredMaxLayoutWidth = cell?.desc.bounds.size.width ?? 0.0
        return cell
    }
}

struct MeterValue {
    
    let fractionalNumber:   String?
    let units:              String?
    let previousValue1:     String?
    let previousValue2:     String?
    let previousValue3:     String?
    let name:               String?
    let resource:           String?
    let previousValueInput: String?
    let difference1: 	    String?
    let difference2:        String?
    let difference3:        String?
    let differenceInput: 	String?
    let meterUniqueNum:     String?
    let value1:             String?
    let value2:             String?
    let value3:             String?
    let valueInput1: 	    String?
    let valueInput2:        String?
    let valueInput3:        String?
    let previousPeriod:     String?
    let period:             String?
    let guid:               String?
    let meterType:          String?
    let typeTarif:          String?
    let tarifName1:         String?
    let tarifName2:         String?
    let tarifName3:         String?
    let tarifPrice1:        String?
    let tarifPrice2:        String?
    let tarifPrice3:        String?
    let checkDate:          String?
    
    init(_ row: XML.Accessor, period: String) {
        
        self.period         = period
        fractionalNumber    = row.attributes["FractionalNumber"] ?? ""
        units               = row.attributes["Units"] ?? ""
        previousValue1      = row.attributes["PreviousValue"] ?? ""
        previousValue2      = row.attributes["PreviousValue2"] ?? ""
        previousValue3      = row.attributes["PreviousValue3"] ?? ""
        name                = row.attributes["Name"] ?? ""
        resource            = row.attributes["Resource"] ?? ""
        previousValueInput  = row.attributes["PreviousValueInput"] ?? ""
        difference1         = row.attributes["Difference1"] ?? ""
        difference2         = row.attributes["Difference2"] ?? ""
        difference3         = row.attributes["Difference3"] ?? ""
        differenceInput     = row.attributes["DifferenceInput"] ?? ""
        meterUniqueNum      = row.attributes["MeterUniqueNum"] ?? ""
        value1              = row.attributes["Value"] ?? ""
        value2              = row.attributes["Value2"] ?? ""
        value3              = row.attributes["Value3"] ?? ""
        valueInput1         = row.attributes["ValueInput1"] ?? ""
        valueInput2         = row.attributes["ValueInput2"] ?? ""
        valueInput3         = row.attributes["ValueInput3"] ?? ""
        tarifName1          = row.attributes["Tarif_name1"] ?? ""
        tarifName2          = row.attributes["Tarif_name2"] ?? ""
        tarifName3          = row.attributes["Tarif_name3"] ?? ""
        tarifPrice1         = row.attributes["TarifPrice1"] ?? ""
        tarifPrice2         = row.attributes["TarifPrice2"] ?? ""
        tarifPrice3         = row.attributes["TarifPrice3"] ?? ""
        typeTarif           = row.attributes["Type_of_tariff"] ?? ""
        previousPeriod      = row.attributes["PreviousPeriod"] ?? ""
        guid                = row.attributes["GUID"] ?? ""
        meterType           = row.attributes["MeterType"] ?? ""
        checkDate           = row.attributes["Check_date"] ?? ""
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












