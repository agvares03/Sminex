//
//  MainScreenVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/22/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import SwiftyXMLParser
import FSPagerView
import DeviceKit

private protocol MainDataProtocol:  class {}
private protocol CellsDelegate:     class {
    func tapped(name: String)
    func pressed(at indexPath: IndexPath, title: String)
    func stockCellPressed(currImg: Int, section: Int, selItem: Int)
}
protocol MainScreenDelegate: class {
    func update(method: String)
}

final class MainScreenVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CellsDelegate, UICollectionViewDelegateFlowLayout, MainScreenDelegate, AppsUserDelegate {
    
    private var business_center_info: Bool?
    private var busines_center_denyInvoiceFiles: Bool?
    private var busines_center_denyTotalOnlinePayments: Bool?
    // выводить или нет qr-код
    private var busines_center_denyQRCode: Bool?
    
    // Можно ли добавить транспорт в пропуск
    private var business_center_PassSingle: Bool?
    private var business_center_PassSingleWithAuto: Bool?
    
    private var business_center_OnlyViewMeterReadings: Bool?
    
    private var busines_center_dayFrom: Int?
    private var busines_center_dayTo: Int?
    
    private var busines_center_CompanyService: Bool? = false
    private var busines_center_denyShowFine: Bool?
    @IBOutlet private weak var collection: UICollectionView!
    @IBOutlet private weak var loader: UIActivityIndicatorView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func payButtonPressed(_ sender: UIButton) {
//        if UserDefaults.standard.string(forKey: "typeBuilding") != "commercial"{
//            performSegue(withIdentifier: Segues.fromMainScreenVC.toFinancePay, sender: self)
//        }else{
        if (UserDefaults.standard.bool(forKey: "denyTotalOnlinePayments")) {
            performSegue(withIdentifier: Segues.fromFinanceVC.toBillsArchive, sender: self)
        }else{
            performSegue(withIdentifier: Segues.fromMainScreenVC.toFinancePayComm, sender: self)
        }
//        }
    }
    
    @IBAction func addRequestByTitle(_ sender: Any) {
        performSegue(withIdentifier: Segues.fromMainScreenVC.toCreateRequest, sender: self)
    }
    
    private var requestId  = ""
    private var surveyName = ""
    private var canCount = true
    private var data: [Int:[Int:MainDataProtocol]] = [
        0 : [
            0 : CellsHeaderData(title: "ЗАЯВКИ"),
            1 : NewRequestCellData(requestData: [])
        ],
        1 : [
            0 : CellsHeaderData(title: "К ОПЛАТЕ")
        ],
        2 : [
            0 : CellsHeaderData(title: "СЧЕТЧИКИ"),
//            1 : SchetCellData(title: "Осталось 4 дня для передачи показаний", date: "Передача с 20 по 25 января")],
            1 : SchetCellData(title: "", date: "")],
        3 : [
            0 : CellsHeaderData(title: "АКЦИИ И ПРЕДЛОЖЕНИЕ"),
            1 : StockCellData(images: [])
        ],
        4 : [
            0 : CellsHeaderData(title: "НОВОСТИ"),
            1 : NewNewsCellData(newsData: [])
        ],
        5 : [
            0 : CellsHeaderData(title: "ОПРОСЫ"),
            1 : NewSurveyCellData(surveyData: [])
        ],
        6 : [
            0 : CellsHeaderData(title: "ВЕРСИЯ")]]
    //            1 : VersionCellData()]]
    private var questionSize:   CGSize?
    private var newsSize:       CGSize?
    private var dealsSize:      CGSize?
    private var debtSize:       CGSize?
    private var url:            URLRequest?
    private var debt:           AccountDebtJson?
    private var refreshControl: UIRefreshControl?
    private var mainScreenXml:  XML.Accessor?
    private var tappedNews: NewsJson?
    private var deals:  [DealsJson] = []
    private var filteredNews: [NewsJson] = []
    private var dealsIndex = 0
    private var numSections = 0
    private var appsUser: TestAppsUser?
    private var appealUser: AppealUser?
    private var dataService: [ServicesUKJson] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.stopAnimating()
        loader.isHidden = true
        // Получим данные по Бизнес-центру (выводить или нет Оплаты)
        get_info_business_center()
        getAccIcon()
        title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"
        canCount = UserDefaults.standard.integer(forKey: "can_count") == 1 ? true : false
        
        fetchDebt()
        var notifi = false
        if UserDefaults.standard.bool(forKey: "openNotification"){
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async {
                    self.loader.isHidden = false
                    self.collection.isHidden = true
                    self.loader.startAnimating()
                }
                if ((UserDefaults.standard.string(forKey: "typeNotifi")?.containsIgnoringCase(find: "question"))!){
                    UserDefaults.standard.set(false, forKey: "openNotification")
                    DispatchQueue.main.async {
                        self.loader.isHidden = true
                        self.collection.isHidden = false
                        self.loader.stopAnimating()
                        //                    UserDefaults.standard.set(false, forKey: "openNotification")
                        if self.activeQuestionCount == 1{
                            UserDefaults.standard.set((self.activeQuestion_?.name!)!, forKey: "titleNotifi")
                        }else{
                            UserDefaults.standard.set("У вас есть непройденные ОПРОСЫ", forKey: "titleNotifi")
                        }
                        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CustomNotifiAlertController") as! CustomNotifiAlert
                        vc.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
                        self.addChildViewController(vc)
                        self.view.addSubview(vc.view)
                    }
                }else if (UserDefaults.standard.string(forKey: "typeNotifi") == "REQUEST_COMMENT") || (UserDefaults.standard.string(forKey: "typeNotifi") == "REQUEST_STATUS"){
//                    UserDefaults.standard.set(false, forKey: "openNotification")
                    notifi = true
                    self.requestId = UserDefaults.standard.string(forKey: "identNotifi") ?? ""
                    self.getServices()
                    
//                    self.appsUser = TestAppsUser()
//                    self.appsUser?.dataService = self.dataService
//                    self.appsUser?.requestId_ = self.requestId
//                    self.appsUser?.pushReqID = self.requestId
//                    self.appsUser?.xml_ = self.mainScreenXml
//                    self.appsUser?.isFromMain = true
//                    self.appsUser?.delegate = self
//                    self.appsUser?.prepareGroup = DispatchGroup()
//                    self.appsUser?.viewDidLoad()
//                    DispatchQueue.global(qos: .userInitiated).async {
//                        self.appsUser?.prepareGroup?.wait()
//                        DispatchQueue.main.async {
//                            if self.appsUser?.admission != nil {
//                                self.performSegue(withIdentifier: Segues.fromMainScreenVC.toAdmission, sender: self)
//                            } else if self.appsUser?.techService != nil {
//                                self.performSegue(withIdentifier: Segues.fromMainScreenVC.toService, sender: self)
//                            } else if self.appsUser?.serviceUK != nil {
//                                self.performSegue(withIdentifier: Segues.fromAppsUser.toServiceUK, sender: self)
//                            } else if self.appsUser?.appeal != nil {
//                                self.performSegue(withIdentifier: Segues.fromAppsUser.toAppeal, sender: self)
//                            }
//                        }
//                    }
//                    self.appsUser = TestAppsUser()
//                    self.appsUser?.dataService = self.dataService
//                    self.appsUser?.requestId_ = self.requestId
//                    self.appsUser?.pushAppealID = self.requestId
//                    self.appsUser?.xml_ = self.mainScreenXml
//                    self.appsUser?.isFromMain = true
//                    self.appsUser?.delegate = self
//                    self.appsUser?.prepareGroup = DispatchGroup()
//                    self.appsUser?.viewDidLoad()
//                    DispatchQueue.global(qos: .userInitiated).async {
//                        self.appsUser?.prepareGroup?.wait()
//                        DispatchQueue.main.async {
//                            if self.appsUser?.appeal != nil {
//                                self.performSegue(withIdentifier: Segues.fromAppsUser.toAppeal, sender: self)
//                            }
//                        }
//                    }
                } else if (UserDefaults.standard.string(forKey: "typeNotifi") == "NEWS") {
                    self.fetchNews(newsId: UserDefaults.standard.string(forKey: "identNotifi") ?? "")
                    //                filteredNews.forEach{
                    //                    if String($0.newsId!) == UserDefaults.standard.string(forKey: "identNotifi") ?? ""{
                    //                        self.tappedNews = $0
                    //                    }
                    //                }
                    //                self.performSegue(withIdentifier: Segues.fromMainScreenVC.toNewsWAnim, sender: self)
                } else if (UserDefaults.standard.string(forKey: "typeNotifi") == "DEBT") {
                    UserDefaults.standard.set(false, forKey: "openNotification")
//                    if UserDefaults.standard.string(forKey: "typeBuilding") != "commercial"{
                        self.performSegue(withIdentifier: Segues.fromMainScreenVC.toFinanceComm, sender: self)
//                    }else{
//                        self.performSegue(withIdentifier: Segues.fromMainScreenVC.toFinance, sender: self)
//                    }
                } else if (UserDefaults.standard.string(forKey: "typeNotifi") == "METER_VALUE") {
                    UserDefaults.standard.set(false, forKey: "openNotification")
                    //                DB().del_db(table_name: "Counters")
                    //                DB().del_db(table_name: "TypesCounters")
                    //                DB().parse_Countrers(login: UserDefaults.standard.string(forKey: "login") ?? "", pass: UserDefaults.standard.string(forKey: "pwd") ?? "", history: "0")
                    self.performSegue(withIdentifier: Segues.fromMainScreenVC.toSchet, sender: self)
                }
            }
        }
        if !notifi{
            getServices()
        }
        fetchNews(newsId: "")
        fetchDeals()
        getRequestTypes()
        fetchRequests()
        fetchQuestions()
        collection.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        collection.delegate     = self
        collection.dataSource   = self
        automaticallyAdjustsScrollViewInsets = false
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        navigationController?.navigationBar.barStyle = .black
        tabBarController?.tabBar.tintColor = mainGreenColor
        tabBarController?.tabBar.selectedItem?.title = "Главная"
        tabBarController?.tabBar.isHidden = false
//        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 22, weight: .bold) ]
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
        updateUserInterface()
        UserDefaults.standard.set(true, forKey: "startApp")
    }
    var startApp = true
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
    
    func getAccIcon(){
        var imageList   : [String:Data] = [:]
        
        let login = UserDefaults.standard.string(forKey: "login")!
        if UserDefaults.standard.dictionary(forKey: "allIcon") != nil{
            imageList = UserDefaults.standard.dictionary(forKey: "allIcon") as! [String : Data]
            if imageList.keys.firstIndex(of: login) != nil{
                let image = imageList[login]
                UserDefaults.standard.setValue(image, forKey: "accountIcon")
            }
        }
        
    }
    var refresh = false
    @objc private func refresh(_ sender: UIRefreshControl) {
        refresh = true
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.global(qos: .background).async {
                let res = self.getRequests()
                var count = 1
                sleep(2)
                DispatchQueue.main.sync {
                    self.data[0] = [0 : CellsHeaderData(title: "ЗАЯВКИ")]
                    self.data[0]![1] = NewRequestCellData(requestData: res)
                }
            }
            DB().del_db(table_name: "Notifications")
            DB().parse_Notifications(id_account: UserDefaults.standard.string(forKey: "id_account")  ?? "")
            self.fetchQuestions()
//            self.fetchDeals()
//            self.fetchDebt()
//            self.fetchNews(newsId: "")
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    self.collection.refreshControl?.endRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.collection.isHidden = false
//        loader.stopAnimating()
//        loader.isHidden = true
        notifiPressed = false
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
        if UserDefaults.standard.bool(forKey: "backBtn"){
//            fetchNews(newsId: "")
//            fetchDeals()
//            fetchQuestions()
            self.viewDidLoad()
            //            title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"
            //            canCount = UserDefaults.standard.integer(forKey: "can_count") == 1 ? true : false
            //            DispatchQueue.global(qos: .userInitiated).async {
            //                DispatchQueue.global(qos: .background).async {
            //                    let res = self.getRequests()
            //                    var count = 1
            //                    sleep(2)
            //                    DispatchQueue.main.sync {
            //                        self.data[0] = [0 : CellsHeaderData(title: "ЗАЯВКИ")]
            //                        res.forEach {
            //                            self.data[0]![count] = $0
            //                            count += 1
            //                        }
            //                        self.data[0]![count] = RequestAddCellData(title: "Оставить заявку")
            //                        self.collection.reloadData()
            //                    }
            //                }
            //
            //                self.get_info_business_center()
            //                self.fetchQuestions()
            //                self.fetchDeals()
            //                self.fetchDebt()
            //                self.fetchNews()
            //                DispatchQueue.main.async {
            //                    if #available(iOS 10.0, *) {
            //                        self.collection.refreshControl?.endRefreshing()
            //                    } else {
            //                        self.refreshControl?.endRefreshing()
            //                    }
            //                }
            //            }
        }
        UserDefaults.standard.set(false, forKey: "backBtn")
        tabBarController?.tabBar.tintColor = mainGreenColor
        tabBarController?.tabBar.selectedItem?.title = "Главная"
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
//        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 22, weight: .bold) ]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.async {
            self.loader.isHidden = true
            self.collection.isHidden = false
            self.loader.stopAnimating()
        }
        startApp = false
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
//        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17, weight: .bold) ]
    }
    
    private func get_info_business_center() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_SERVICES + "ident=\(login)")!)
        request.httpMethod = "GET"
                print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
                    //                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            #if DEBUG
//            print(String(data: data!, encoding: .utf8)!)
            
            #endif
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.business_center_info = Business_Center_Data(json: json!)?.DenyOnlinePayments
                self.busines_center_denyInvoiceFiles = Business_Center_Data(json: json!)?.DenyInvoiceFiles
                self.busines_center_denyTotalOnlinePayments = Business_Center_Data(json: json!)?.DenyTotalOnlinePayments
                
                self.busines_center_denyQRCode = Business_Center_Data(json: json!)?.DenyQRCode
                
                self.business_center_PassSingle = Business_Center_Data(json: json!)?.DenyIssuanceOfPassSingle
                self.business_center_PassSingleWithAuto = Business_Center_Data(json: json!)?.DenyIssuanceOfPassSingleWithAuto
                
                self.business_center_OnlyViewMeterReadings = Business_Center_Data(json: json!)?.OnlyViewMeterReadings
                
                self.busines_center_dayFrom = Business_Center_Data(json: json!)?.DayFrom
                self.busines_center_dayTo = Business_Center_Data(json: json!)?.DayTo
                self.busines_center_CompanyService = Business_Center_Data(json: json!)?.DenyManagementCompanyServices
                self.busines_center_denyShowFine = Business_Center_Data(json: json!)?.DenyShowFine
            }
            
            let defaults = UserDefaults.standard
            defaults.set(self.business_center_info, forKey: "denyOnlinePayments")
            defaults.set(self.busines_center_denyInvoiceFiles, forKey: "denyInvoiceFiles")
            defaults.set(self.busines_center_denyTotalOnlinePayments, forKey: "denyTotalOnlinePayments")
            defaults.set(self.busines_center_denyQRCode, forKey: "denyQRCode")
            defaults.set(self.business_center_PassSingle, forKey: "denyIssuanceOfPassSingle")
            defaults.set(self.business_center_PassSingleWithAuto, forKey: "denyIssuanceOfPassSingleWithAuto")
            defaults.set(self.business_center_OnlyViewMeterReadings, forKey: "onlyViewMeterReadings")
            defaults.set(self.busines_center_dayFrom, forKey: "meterReadingsDayFrom")
            defaults.set(self.busines_center_dayTo, forKey: "meterReadingsDayTo")
            defaults.set(self.busines_center_CompanyService, forKey: "denyCompanyService")
            defaults.set(self.busines_center_denyShowFine, forKey: "denyShowFine")
            defaults.synchronize()
            let dateFrom = UserDefaults.standard.integer(forKey: "meterReadingsDayFrom")
            let dateTo = UserDefaults.standard.integer(forKey: "meterReadingsDayTo")
            UserDefaults.standard.set(false, forKey: "didntSchet")
            UserDefaults.standard.synchronize()
            if (dateFrom == 0 && dateTo == 0) && !(UserDefaults.standard.bool(forKey: "onlyViewMeterReadings")) {
                let now = NSDate()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "LLLL yyyy"
                //            dateFormatter.setLocalizedDateFormatFromTemplate("ru-Ru")
                let nameOfMonth = dateFormatter.string(from: now as Date)
                self.data[2]![1] = SchetCellData(title: "", date: "Передача показаний за \(nameOfMonth)")
                
            } else {
                let dateFormatter = DateFormatter()
                let currentDate = Date()
                let userCalendar = Calendar.current
                let requestedComponents: Set<Calendar.Component> = [
                    .year,
                    .month,
                    .day,
                    .hour,
                    .minute,
                    .second
                ]
                let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: currentDate)
                
                var leftDays = dateFrom - dateTimeComponents.day!
                var startDate = userCalendar.date(from: dateTimeComponents)
                var endDate = userCalendar.date(from: dateTimeComponents)
                if dateFrom > dateTo{
                    var dateComponents = DateComponents()
                    dateComponents.year = dateTimeComponents.year!
                    if dateTimeComponents.day! > dateTo{
                        dateComponents.month = dateTimeComponents.month! + 1
                    }else{
                        dateComponents.month = dateTimeComponents.month!
                        leftDays = dateTimeComponents.day! - dateTo
                    }
                    dateComponents.day = dateTo
                    let userCalendar = Calendar.current
                    endDate = userCalendar.date(from: dateComponents)
                }else{
                    var dateComponents = DateComponents()
                    dateComponents.year = dateTimeComponents.year!
                    dateComponents.month = dateTimeComponents.month!
                    dateComponents.day = dateTo
                    let userCalendar = Calendar.current
                    endDate = userCalendar.date(from: dateComponents)
                }
                if dateFrom != 0{
                    var dateComponents = DateComponents()
                    dateComponents.year = dateTimeComponents.year!
                    if dateFrom > dateTo && dateTimeComponents.day! > dateTo{
                        dateComponents.month = dateTimeComponents.month!
                    }else{
                        dateComponents.month = dateTimeComponents.month! - 1
                    }
                    dateComponents.day = dateFrom
                    let userCalendar = Calendar.current
                    startDate = userCalendar.date(from: dateComponents)
                }
                dateFormatter.dateFormat = dateTo < 10 ? "d MMMM" : "dd MMMM"
                dateFormatter.locale = Locale(identifier: "Ru-ru")
                if leftDays <= 0{
                    UserDefaults.standard.set(true, forKey: "didntSchet")
                    UserDefaults.standard.synchronize()
                    if dateFrom > dateTo{
                        if dateTimeComponents.day! > dateTo{
                            if dateTimeComponents.month! == 1 || dateTimeComponents.month! == 3 || dateTimeComponents.month! == 5 || dateTimeComponents.month! == 7 || dateTimeComponents.month! == 8 || dateTimeComponents.month! == 10 || dateTimeComponents.month! == 12{
                                leftDays = (31 - (dateTimeComponents.day! - 1)) + dateTo
                            }else if dateTimeComponents.month! == 2{
                                leftDays = (28 - (dateTimeComponents.day! - 1)) + dateTo
                            }else{
                                leftDays = (30 - (dateTimeComponents.day! - 1)) + dateTo
                            }
                        }else {
                            leftDays = (dateTo - dateTimeComponents.day!) + 1
                        }
                        if leftDays == 1 {
                            self.data[2]![1] = SchetCellData(title: "Остался \(leftDays) день для передачи показаний", date: "Передача с \(dateFormatter.string(from: startDate!)) по \(dateFormatter.string(from: endDate!))")
                            
                        } else if leftDays == 2 || leftDays == 3 || leftDays == 4 {
                            self.data[2]![1] = SchetCellData(title: "Осталось \(leftDays) дня для передачи показаний", date: "Передача с \(dateFormatter.string(from: startDate!)) по \(dateFormatter.string(from: endDate!))")
                            
                        } else {
                            self.data[2]![1] = SchetCellData(title: "Осталось \(leftDays) дней для передачи показаний", date: "Передача с \(dateFormatter.string(from: startDate!)) по \(dateFormatter.string(from: endDate!))")
                        }
                    }else{
                        leftDays = dateTo - dateTimeComponents.day!
                        if leftDays == 1 {
                            self.data[2]![1] = SchetCellData(title: "Остался \(leftDays) день для передачи показаний", date: "Передача с \(dateFrom) по \(dateFormatter.string(from: endDate!))")
                            
                        } else if leftDays == 2 || leftDays == 3 || leftDays == 4 {
                            self.data[2]![1] = SchetCellData(title: "Осталось \(leftDays) дня для передачи показаний", date: "Передача с \(dateFrom) по \(dateFormatter.string(from: endDate!))")
                            
                        } else {
                            self.data[2]![1] = SchetCellData(title: "Осталось \(leftDays) дней для передачи показаний", date: "Передача с \(dateFrom) по \(dateFormatter.string(from: endDate!))")
                        }
                    }
                }else if leftDays == 1 {
                    if dateTimeComponents.day! > dateTo{
                        self.data[2]![1] = SchetCellData(title: "До передачи показаний остался \(leftDays) день", date: "Передача с \(dateFormatter.string(from: startDate!)) по \(dateFormatter.string(from: endDate!))")
                    }else{
                        self.data[2]![1] = SchetCellData(title: "До передачи показаний осталось \(leftDays) день", date: "Передача с \(dateFrom) по \(dateFormatter.string(from: endDate!))")
                    }
                } else if leftDays == 2 || leftDays == 3 || leftDays == 4 {
                    if dateTimeComponents.day! > dateTo{
                        self.data[2]![1] = SchetCellData(title: "До передачи показаний осталось \(leftDays) дня", date: "Передача с \(dateFormatter.string(from: startDate!)) по \(dateFormatter.string(from: endDate!))")
                    }else{
                        self.data[2]![1] = SchetCellData(title: "До передачи показаний осталось \(leftDays) дня", date: "Передача с \(dateFrom) по \(dateFormatter.string(from: endDate!))")
                    }
                } else {
                    if dateTimeComponents.day! > dateTo{
                        self.data[2]![1] = SchetCellData(title: "До передачи показаний осталось \(leftDays) дней", date: "Передача с \(dateFormatter.string(from: startDate!)) по \(dateFormatter.string(from: endDate!))")
                    }else{
                        self.data[2]![1] = SchetCellData(title: "До передачи показаний осталось \(leftDays) дней", date: "Передача с \(dateFrom) по \(dateFormatter.string(from: endDate!))")
                    }
                }
            }
            DispatchQueue.main.async{
                self.collection.reloadData()
            }
            }.resume()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 5 && questionSize != nil {
            return 0
            
        } else if section == 4 && newsSize != nil {
            return 0
        } else if data.keys.contains(section) {
            return (data[section]?.count ?? 2) - 1
            
        } else {
            return 0
        }
    }
    
    func remove(index: Int) {
        self.data.removeValue(forKey: index)
        
        let indexPath = IndexPath(row: index, section: 0)
        collection.performBatchUpdates({
            collection.deleteItems(at: [indexPath])
        }, completion: {
            (finished: Bool) in
            self.collection.reloadItems(at: self.collection.indexPathsForVisibleItems)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        //        if kind == UICollectionElementKindSectionHeader {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CellsHeader", for: indexPath) as! CellsHeader
        //        if  indexPath.section != 4 && self.debtSize == nil{
        header.display(data[indexPath.section]![0] as! CellsHeaderData, delegate: self)
        //        } else {
        //            header.frame.size.height = 0
        //        }
        header.frame.size.width = view.frame.size.width
        header.frame.origin.x = 0
        
        if header.title.text == "ВЕРСИЯ" {
            header.title.text = ""
        }
        if indexPath.section == 1 || indexPath.section == 2{
            header.title.isHidden = true
            header.detail.isHidden = true
        }else{
            header.title.isHidden = false
            header.detail.isHidden = false
        }
//        if #available(iOS 11.0, *) {
//            header.clipsToBounds = false
//            header.layer.cornerRadius = 4
//            header.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//        } else {
//            let rectShape = CAShapeLayer()
//            rectShape.bounds = header.frame
//            rectShape.position = header.center
//            rectShape.path = UIBezierPath(roundedRect: header.bounds, byRoundingCorners: [.topRight , .topLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
//            header.layer.mask = rectShape
//        }
        return header
        
        //        } else {
        
        //            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EnableCell", for: indexPath) as! EnableCell
        //            footer.display("")
        //            return footer
        
        //        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "ОПРОСЫ" {
//            let cell = SurveyCell.fromNib()
//            cell?.display(data[indexPath.section]![indexPath.row + 1] as! SurveyCellData, indexPath: indexPath, delegate: self)
//            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
//            return CGSize(width: view.frame.size.width - 32, height: size.height)
            let reqDat = data[indexPath.section]![indexPath.row + 1] as! NewSurveyCellData
            if reqDat.surveyData.count > 0{
                return CGSize(width: view.frame.size.width - 32, height: 230)
            }else{
                return CGSize(width: view.frame.size.width - 32, height: 0)
            }
        } else if title == "НОВОСТИ" {
//            let cell = NewsCell.fromNib(viewWidth: view.frame.size.width)
//            cell?.display(data[indexPath.section]![indexPath.row + 1] as! NewsCellData)
//            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
            return CGSize(width: view.frame.size.width - 32, height: 153)
            
        } else if title == "АКЦИИ И ПРЕДЛОЖЕНИЕ" {
            if (self.dealsSize == nil) {
                //                self.dealsSize = CGSize(width: view.frame.size.width, height: 204.0)
                return CGSize(width: view.frame.size.width - 32, height: 1.0)
            } else {
                let points = Double(UIScreen.pixelsPerInch ?? 0.0)
                if (250.0...280.0).contains(points) {
                    return CGSize(width: view.frame.size.width - 32, height: 455.0)
                }
                if Device().isOneOf([.iPhone5, .iPhone5s, .iPhone5c, .iPhoneSE, .simulator(.iPhoneSE)]){
                    return CGSize(width: view.frame.size.width - 32, height: 176.0)
                }
                return CGSize(width: view.frame.size.width - 32, height: 204.0)
            }
        } else if title == "ЗАЯВКИ" {
            let reqDat = data[indexPath.section]![indexPath.row + 1] as! NewRequestCellData
            if reqDat.requestData.count > 0{
                return CGSize(width: view.frame.size.width, height: 255)
            }else{
                return CGSize(width: view.frame.size.width, height: 96)
            }
        } else if title == "К ОПЛАТЕ" {
//            if busines_center_denyTotalOnlinePayments == true || business_center_info == true || self.payNil {
//                return CGSize(width: view.frame.size.width - 32, height: 112.0)
//            } else {
                return CGSize(width: view.frame.size.width - 32, height: 207.0)
//            }
        } else if title == "СЧЕТЧИКИ" {
//            let cell = SchetCell.fromNib()
//            cell?.display(data[indexPath.section]![indexPath.row + 1] as! SchetCellData)
//            var size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
//            if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
//                size.height = 15
//            }
            if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
                return CGSize(width: view.frame.size.width - 32, height: 140)
            }
            if (data[indexPath.section]![indexPath.row + 1] as! SchetCellData).title.contains(find: "для передачи показаний"){
                return CGSize(width: view.frame.size.width - 32, height: 180)
            }
            return CGSize(width: view.frame.size.width - 32, height: 150)
        } else if title == "ВЕРСИЯ" {
            
            return CGSize(width: view.frame.size.width - 32, height: 0.0)
            
        } else {
            return CGSize(width: view.frame.size.width, height: 100.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "ОПРОСЫ" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SurveyCell", for: indexPath) as! NewSurveyCell
//            cell.display(data[indexPath.section]![indexPath.row + 1] as! SurveyCellData, indexPath: indexPath, delegate: self, isLast: data[indexPath.section]!.count == indexPath.row + 2)
//            if indexPath.row + 2 == data[indexPath.section]?.count {
//                if #available(iOS 11.0, *) {
//                    cell.clipsToBounds = false
//                    cell.layer.cornerRadius = 4
//                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
//                } else {
//                    let rectShape = CAShapeLayer()
//                    rectShape.bounds = cell.frame
//                    rectShape.position = cell.center
//                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
//                    cell.layer.mask = rectShape
//                }
//            }
//            return cell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! NewSurveyCellData, delegate: self, indexPath: indexPath)
            return cell
        } else if title == "НОВОСТИ" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as! NewNewsCell
//            cell.display(data[indexPath.section]![indexPath.row + 1] as! NewsCellData, isLast: data[indexPath.section]!.count == indexPath.row + 2)
//            if indexPath.row + 2 == data[indexPath.section]?.count {
//                if #available(iOS 11.0, *) {
//                    cell.clipsToBounds = false
//                    cell.layer.cornerRadius = 4
//                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
//                } else {
//                    let rectShape = CAShapeLayer()
//                    rectShape.bounds = cell.frame
//                    rectShape.position = cell.center
//                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
//                    cell.layer.mask = rectShape
//                }
//            }
            cell.display(data[indexPath.section]![indexPath.row + 1] as! NewNewsCellData, delegate: self, indexPath: indexPath)
            return cell
            
        } else if title == "АКЦИИ И ПРЕДЛОЖЕНИЕ" {
            
            //            if (self.dealsSize == nil) {
            //                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EnableCell", for: indexPath) as! EnableCell
            //                return cell
            //            } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StockCell", for: indexPath) as! StockCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! StockCellData, delegate: self, indexPath: indexPath)
            return cell
            //            }
            
        } else if title == "ЗАЯВКИ" {
            
//            if indexPath.row == data[indexPath.section]!.count - 2 {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestAddCell", for: indexPath) as! RequestAddCell
//                cell.display(data[indexPath.section]![indexPath.row + 1] as! RequestAddCellData, delegate: self)
//                if #available(iOS 11.0, *) {
//                    cell.clipsToBounds = false
//                    cell.layer.cornerRadius = 4
//                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
//                } else {
//                    let rectShape = CAShapeLayer()
//                    rectShape.bounds = cell.frame
//                    rectShape.position = cell.center
//                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
//                    cell.layer.mask = rectShape
//                }
//                return cell
//
//            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestCell", for: indexPath) as! NewRequestCell
                cell.display(data[indexPath.section]![indexPath.row + 1] as! NewRequestCellData, delegate: self, indexPath: indexPath)
                return cell
//            }
            
        } else if title == "К ОПЛАТЕ" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ForPayCell", for: indexPath) as! ForPayCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! ForPayCellData)
            if indexPath.row + 2 == data[indexPath.section]?.count {
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
            }
            return cell
            
        } else if title == "СЧЕТЧИКИ" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SchetCell", for: indexPath) as! SchetCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! SchetCellData, delegate: self)
            if indexPath.row + 2 == data[indexPath.section]?.count {
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
            }
            return cell
            
        } else if title == "ВЕРСИЯ" {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VersionCell", for: indexPath) as! VersionCell
            return cell
            
        } else {
            return SurveyCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        pressed(at: indexPath, title: "")
        if indexPath.section == 2 {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toSchet, sender: self)
        }else if indexPath.section == 1 {
//            if UserDefaults.standard.string(forKey: "typeBuilding") != "commercial"{
                performSegue(withIdentifier: Segues.fromMainScreenVC.toFinanceComm, sender: self)
//            }else{
//                performSegue(withIdentifier: Segues.fromMainScreenVC.toFinance, sender: self)
//            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 5 && questionSize != nil {
            return CGSize(width: 0.0, height: 0.0)
        } else if section == 4 && newsSize != nil {
            return CGSize(width: 0.0, height: 0.0)
        } else if section == 3 && dealsSize == nil {
            return CGSize(width: 0.0, height: 0.0)
        } else if section == 0 {
            return CGSize(width: view.frame.size.width, height: 160.0)
        } else if section == 3 {
            return CGSize(width: view.frame.size.width, height: 60.0)
        } else if section == 1 || section == 2{
            return CGSize(width: view.frame.size.width, height: 30.0)
        } else {
            return CGSize(width: view.frame.size.width, height: 50.0)
        }
    }
    
    func pressed(at indexPath: IndexPath, title: String) {
        if title != "" {
            surveyName = title
            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestionAnim, sender: self)
            
        } else if let _ = collection.cellForItem(at: indexPath) as? StockCell {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
            
        }
    }
    
    func tapped(name: String) {
        
        if name == "ЗАЯВКИ" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toRequest, sender: self)
            
        } else if name == "Передать показания" {
            if !UserDefaults.standard.bool(forKey: "onlyViewMeterReadings") {
                performSegue(withIdentifier: Segues.fromMainScreenVC.toSchet, sender: self)
            }
            
        } else if name == "ОПРОСЫ" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestions, sender: self)
            
        } else if name == "АКЦИИ И ПРЕДЛОЖЕНИЕ" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toDealsList, sender: self)
            
        } else if name == "НОВОСТИ" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toNews, sender: self)
        }
    }
    
    func stockCellPressed(currImg: Int, section: Int, selItem: Int) {
        if section == 3{
            self.dealsIndex = currImg
            performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
        }else if section == 0{
            let reqData = self.data[0]![1] as! NewRequestCellData
            self.requestId = reqData.requestData[selItem].id ?? ""
            appsUser = TestAppsUser()
            appsUser?.dataService = dataService
            appsUser?.requestId_ = requestId
            appsUser?.xml_ = mainScreenXml
            appsUser?.isFromMain = true
            appsUser?.delegate = self
            appsUser?.prepareGroup = DispatchGroup()
            appsUser?.viewDidLoad()
            DispatchQueue.global(qos: .userInitiated).async {
                self.appsUser?.prepareGroup?.wait()
                DispatchQueue.main.async {
                    if self.appsUser?.admission != nil {
                        self.performSegue(withIdentifier: Segues.fromMainScreenVC.toAdmission, sender: self)
                        
                    } else if self.appsUser?.techService != nil {
                        self.performSegue(withIdentifier: Segues.fromMainScreenVC.toService, sender: self)
                    } else {
                        self.performSegue(withIdentifier: Segues.fromAppsUser.toServiceUK, sender: self)
                    }
                }
            }
        }else if section == 4{
//            let reqData = self.data[4]![1] as! NewNewsCellData
            tappedNews = self.filteredNews[safe: selItem]
            self.performSegue(withIdentifier: Segues.fromMainScreenVC.toNewsWAnim, sender: self)
        }else if section == 5{
            let reqData = self.data[5]![1] as! NewSurveyCellData
            surveyName = reqData.surveyData[selItem].title
            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestionAnim, sender: self)
        }
    }
    
    private func fetchRequests() {
        
        DispatchQueue.global(qos: .background).async {
            let res = self.getRequests()
            var count = 1
            DispatchQueue.main.sync {
                self.data[0] = [0 : CellsHeaderData(title: "ЗАЯВКИ")]
                self.data[0]![1] = NewRequestCellData(requestData: res)
                self.collection.reloadData()
            }
        }
    }
    var onePush = false
    private func getServices() {
        if !self.onePush{
            self.onePush = true
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_SERVICES + "ident=\(login)")!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else {
                    let alert = UIAlertController(title: "Ошибка серевера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    self.dataService = ServicesUKDataJson(json: json!)?.data ?? []
                }
                
                #if DEBUG
                //            print(String(data: data!, encoding: .utf8) ?? "")
                #endif
                if UserDefaults.standard.bool(forKey: "openNotification"){
                    if (UserDefaults.standard.string(forKey: "typeNotifi") == "REQUEST_COMMENT") || (UserDefaults.standard.string(forKey: "typeNotifi") == "REQUEST_STATUS"){
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: Segues.fromMainScreenVC.toRequest, sender: self)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func getRequestTypes() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REQUEST_TYPE + "accountid=" + id)!)
        request.httpMethod = "GET"
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, responce, error in
            
            if error != nil {
//                DispatchQueue.main.sync {
//                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
//                    self.present(alert, animated: true, completion: nil)
//                }
                return
            }
            
            let responceString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
//            print(responceString)
            
            #endif
            
            DispatchQueue.main.sync {
                var denyImportExportPropertyRequest = false
                if responceString.contains(find: "error") {
                    let alert = UIAlertController(title: "Ошибка сервера", message: responceString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                        if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                            TemporaryHolder.instance.choise(json!)
                        }
                        let responseString = String(data: data!, encoding: .utf8) ?? ""
                        if responseString.containsIgnoringCase(find: "premises"){
                            let parkingsPlace = (Business_Center_Data(json: json!)?.ParkingPlace)!
                            UserDefaults.standard.set(parkingsPlace, forKey: "parkingsPlace")
                        }
                        denyImportExportPropertyRequest = (Business_Center_Data(json: json!)?.DenyImportExportProperty)!
                        UserDefaults.standard.set(denyImportExportPropertyRequest, forKey: "denyImportExportPropertyRequest")
                    }
                }
            }
            }.resume()
    }
    
    func getRequests() -> [RequestCellData] {
        
        var returnArr: [RequestCellData] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            let pass  = UserDefaults.standard.string(forKey: "pwd") ?? ""
            
//            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass + "&onlyLast=1")!)
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass)!)
            request.httpMethod = "GET"
            print(request)
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    group.leave()
                }
                guard data != nil else { return }
                
//                print(String(data: data!, encoding: .utf8) ?? "")
                let responceString = String(data: data!, encoding: .utf8) ?? ""
                if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
                    self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
                    return
                }
                let xml = XML.parse(data!)
                self.mainScreenXml = xml
                let requests = xml["Requests"]
                let row = requests["Row"]
                var rows: [Request] = []
                var rowComms: [String : [RequestComment]]  = [:]
                var rowPersons: [String : [RequestPerson]] = [:]
                
                row.forEach { row in
                    rows.append(Request(row: row))
                    rowComms[row.attributes["ID"]!] = []
                    rowPersons[row.attributes["ID"]!] = []
                    
                    row["Comm"].forEach {
                        rowComms[row.attributes["ID"]!]?.append( RequestComment(row: $0) )
                    }
                    row["Persons"].all?.forEach {
                        $0.childElements.forEach {
                            rowPersons[row.attributes["ID"]!]?.append( RequestPerson(row: $0)  )
                        }
                    }
                }
                
                let s = "IsReadedOnDevice=\"0\""
                let commentCount = responceString.components(separatedBy: s).count - 1
                var rows2: [Request] = []
                rows.forEach { row in
                    if rows2.count < 3{
                        rows2.append(row)
                    }
                }
                rows2.forEach { row in
                    var isAnswered = (rowComms[row.id!]?.count ?? 0) <= 0 ? false : true
                    
                    var lastComm = (rowComms[row.id!]?.count ?? 0) <= 0 ? nil : rowComms[row.id!]?[(rowComms[row.id!]?.count ?? 1) - 1]
                    let df = DateFormatter()
                    df.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    let addReq = df.date(from: row.added!)
                    let updateDate = df.date(from: row.updateDate!)
                    let calendar = Calendar.current
                    let componentsAdd = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: addReq!)
                    let componentsUpd = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: updateDate!)
                    var v = 0
                    if componentsUpd.day == componentsAdd.day && componentsUpd.month == componentsAdd.month && componentsUpd.year == componentsAdd.year && componentsUpd.hour == componentsAdd.hour && componentsUpd.minute == componentsAdd.minute{
                        v = componentsUpd.second! - componentsAdd.second!
                    }
                    if lastComm != nil && ((lastComm?.text?.contains(find: "Отправлен новый файл:"))! || (lastComm?.text?.contains(find: "Прикреплён файл"))!) && v != 0 && v <= 10{
                        lastComm = nil
                        isAnswered = false
                    }
                    if lastComm != nil && row.isPaid == "1" && (rowComms[row.id!]?.count)! == 1{
                        lastComm = nil
                        isAnswered = false
                    }
                    var icon = UIImage(named: "orangeStatus")!
                    if (row.status?.containsIgnoringCase(find: "закрыта"))! || (row.status?.containsIgnoringCase(find: "выполнена"))!{
                        icon = UIImage(named: "grayStatus")!
                    }else if (row.status?.containsIgnoringCase(find: "принята"))!{
                        icon = UIImage(named: "greenStatus")!
                    }else if (row.status?.containsIgnoringCase(find: "отправлена"))! || (row.status?.containsIgnoringCase(find: "в обработке"))!{
                        icon = UIImage(named: "orangeStatus")!
                    }
                    var type = row.idType
                    TemporaryHolder.instance.requestTypes?.types?.forEach {
                        if $0.id == type {
                            type = $0.name ?? ""
                        }
                    }
                    //                    let isPerson = row.name?.contains(find: "ропуск") ?? false
                    let isPerson = type!.contains(find: "ропуск")
                    
                    var persons = ""//row.responsiblePerson ?? ""
                    
                    if persons == "" {
                        rowPersons[row.id ?? ""]?.forEach { person in
                            if person.id == rowPersons[row.id ?? ""]?.last?.id {
                                persons += (person.fio ?? "") + " "
                                
                            } else {
                                persons += (person.fio ?? "") + ", "
                            }
                        }
                    }
                    
                    let descText = isPerson ? (persons == "" ? "Не указано" : persons) : row.text ?? ""
                    var isRead = false
                    if row.isReadedByClient == "0"{
                        isRead = false
                    }else{
                        isRead = true
                    }
                    if row.isPaid == "1"{
                        var name = row.name
                        if (row.name?.contains(find: "Заказ услуги: "))!{
                            name = row.name?.replacingOccurrences(of: "Заказ услуги: ", with: "")
                        }
                        if (row.name?.contains(find: "Заказ услуги "))!{
                            name = row.name?.replacingOccurrences(of: "Заказ услуги ", with: "")
                        }
                        returnArr.append( RequestCellData(title: "Заявка на услугу",
                                                          desc: (rowComms[row.id!]?.count == 0 || lastComm == nil) ? name ?? "" : lastComm?.text ?? "",
                                                          icon: icon,
                                                          date: row.updateDate ?? "",
                                                          status: row.status ?? "",
                                                          isBack: isAnswered,
                                                          id: row.id ?? "", isPaid: row.isPaid!, stickTitle: name ?? "", isReaded: isRead, webID: row.webID ?? "" ) )
                    }else{
                        returnArr.append( RequestCellData(title: row.name ?? "",
                                                          desc: (rowComms[row.id!]?.count == 0 || lastComm == nil) ? descText : lastComm?.text ?? "",
                                                          icon: icon,
                                                          date: row.updateDate ?? "",
                                                          status: row.status ?? "",
                                                          isBack: isAnswered,
                                                          id: row.id ?? "", isPaid: row.isPaid ?? "", stickTitle: descText, isReaded: isRead, webID: row.webID ?? "" ) )
                    }
                }
                TemporaryHolder.instance.menuRequests = commentCount
                }.resume()
        }
        
        group.wait()
        return returnArr
    }
    
    private func fetchQuestions() {
        DispatchQueue.global().async {
            
            let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                guard data != nil else { return }
                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    let unfilteredData = QuestionsJson(json: json!)?.data
                    var filtered: [QuestionDataJson] = []
                    var questArr: [SurveyCellData] = []
                    unfilteredData?.forEach { json in
                        
                        var isContains = true
                        json.questions?.forEach {
                            if !($0.isCompleteByUser ?? false) {
                                isContains = false
                            }
                        }
                        if json.dateStop != nil{
                            let df = DateFormatter()
                            df.dateFormat = "dd.MM.yyyy"
                            let dat: Date = df.date(from: json.dateStop!)!
                            let teckS: String = df.string(from: Date())
                            let teckDat: Date = df.date(from: teckS)!
                            if !isContains && dat >= teckDat{
                                filtered.append(json)
                            }
                        }else{
                            if !isContains{
                                filtered.append(json)
                            }
                        }
                    }
                    var kol = 0
                    if filtered.count == 0 {
                        self.questionSize = CGSize(width: 0, height: 0)
                        
                    } else {
                        self.questionSize = nil
                        DispatchQueue.main.sync {
                            self.data.removeValue(forKey: 5)
                            self.data[5] = [0:CellsHeaderData(title: "ОПРОСЫ")]
                            var count = 1
                            filtered.forEach {
                                if !$0.isReaded!{
                                    kol += 1
                                }
                                var txt = " вопроса"
                                let col_questions = ($0.questions?.count)!
                                if (col_questions > 4) {
                                    txt = " вопросов"
                                } else if (col_questions == 1) {
                                    txt = " вопрос"
                                }
                                if (col_questions > 20) {
                                    let ostatok = col_questions % 10
                                    if (ostatok > 4) {
                                        txt = " вопросов"
                                    } else if ostatok == 1 {
                                        txt = " вопрос"
                                    } else {
                                        txt = " вопроса"
                                    }
                                }
                                
                                var isAnsvered = false
                                let defaults = UserDefaults.standard
                                let array = defaults.array(forKey: "PollsStarted") as? [Int] ?? [Int]()
                                if array.contains($0.id!) {
                                    isAnsvered = true
                                }
                                if isAnsvered {
                                    questArr.append(SurveyCellData(title: $0.name ?? "", question: "Вы начали опрос", dateStart: $0.dateStart ?? "", dateStop: $0.dateStop ?? ""))
//                                    self.data[5]![count] = SurveyCellData(title: $0.name ?? "", question: "Вы начали опрос", dateStart: $0.dateStart ?? "", dateStop: $0.dateStop ?? "")
                                } else {
                                    questArr.append(SurveyCellData(title: $0.name ?? "", question: "\($0.questions?.count ?? 0)" + txt, dateStart: $0.dateStart ?? "", dateStop: $0.dateStop ?? ""))
//                                    self.data[5]![count] = SurveyCellData(title: $0.name ?? "", question: "\($0.questions?.count ?? 0)" + txt, dateStart: $0.dateStart ?? "", dateStop: $0.dateStop ?? "")
                                    self.activeQuestionCount += 1
                                    self.activeQuestion_ = $0
                                }
                                
                                count += 1
                            }
                            self.data[5]![1] = NewSurveyCellData(surveyData: questArr)
                            UserDefaults.standard.set(self.activeQuestionCount, forKey: "activeQuestion")
                        }
                    }
                    TemporaryHolder.instance.menuQuesions = kol
                    if !self.refresh{
                        DispatchQueue.main.sync {
                            self.collection.reloadData()
                        }
                        
                        if unfilteredData?.count == 0 {
                            DispatchQueue.main.sync {
                                self.questionSize = CGSize(width: 0, height: 0)
                                self.collection.reloadData()
                            }
                        }
                    }else{
                        self.fetchDeals()
                    }
                }
                
                }.resume()
        }
    }
    var activeQuestionCount = 0
    var activeQuestion_: QuestionDataJson?
    private final func fetchDeals() {
        var idArray:[String] = []
        if UserDefaults.standard.array(forKey: "deals") != nil{
            idArray = UserDefaults.standard.array(forKey: "deals") as! [String]
        }
        if idArray.count == 0{
            var request = URLRequest(url: URL(string: Server.SERVER + Server.PROPOSALS + "ident=\(UserDefaults.standard.string(forKey: "login") ?? "")" + "&isIOS=1")!)
            request.httpMethod = "GET"
            print(request)
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    if !self.refresh{
                        DispatchQueue.main.async {
                            self.collection.reloadData()
                        }
                    }else{
                        self.fetchDebt()
                    }
                }
                guard data != nil else { return }
                
                if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                    
                    DispatchQueue.main.sync {
                        //                    self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    self.deals = (DealsDataJson(json: json!)?.data)!
                }
                var imgs: [UIImage] = []
                
                if (self.deals.count == 0) {
                    self.dealsSize = nil
                    self.data[3]![1] = StockCellData(images: [])
                } else {
                    self.dealsSize = CGSize(width: 0, height: 0)
                    var kol = 0
                    var idArr: [String] = []
                    self.deals.forEach {
                        if !$0.isReaded!{
                            kol += 1
                        }
                        imgs.append( $0.img ?? UIImage() )
                        let id: Int = $0.id!
                        idArr.append(String(id))
                    }
                    self.data[3]![1] = StockCellData(images: imgs)
                    TemporaryHolder.instance.menuDeals = kol
                    TemporaryHolder.instance.oldDeals = self.deals
                    UserDefaults.standard.set(String(data: data!, encoding: .utf8) ?? "", forKey: "dealsJSON")
                    UserDefaults.standard.set(idArr, forKey: "deals")
                    #if DEBUG
                    //                print(String(data: data!, encoding: .utf8) ?? "")
                    #endif
                    
                }
                
            }.resume()
        }else{
            var request = URLRequest(url: URL(string: Server.SERVER + Server.PROPOSALS_NEW + "ident=\(UserDefaults.standard.string(forKey: "login") ?? "")" + "&isIOS=1")!)
            request.httpMethod = "POST"
            if let json = try? JSONSerialization.data(withJSONObject: idArray, options: .prettyPrinted) {
                request.httpBody = Data(json)
            }
            print(request, idArray)
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in

                defer {
                    if !self.refresh{
                        DispatchQueue.main.async {
                            self.collection.reloadData()
                        }
                    }else{
                        self.fetchDebt()
                    }
                }
//                #if DEBUG
//                print(String(data: data!, encoding: .utf8) ?? "")
//                #endif
                guard data != nil else { return }

                if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )

                    DispatchQueue.main.sync {
                        //                    self.present(alert, animated: true, completion: nil)
                    }
                    return
                }

                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    self.deals = (DealsDataJson(json: json!)?.data)!
                }
                let dealsJSON: String = UserDefaults.standard.string(forKey: "dealsJSON") ?? ""
                let jsonData = dealsJSON.data(using: .utf8)!
                var dealsOld:  [DealsJson] = []
                if let json = try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? JSON {
                    dealsOld = (DealsDataJson(json: json!)?.data)!
                }
                dealsOld.forEach{
                    self.deals.append($0)
                }
                var imgs: [UIImage] = []

                if (self.deals.count == 0) {
                    self.dealsSize = CGSize(width: 0, height: 0)
                    var kol = 0
                    TemporaryHolder.instance.oldDeals.forEach {
                        if !$0.isReaded!{
                            kol += 1
                        }
                        imgs.append( $0.img ?? UIImage() )
                    }
                    self.data[3]![1] = StockCellData(images: imgs)
                } else {
                    self.dealsSize = CGSize(width: 0, height: 0)
                    var kol = 0
                    var idArr: [String] = []
                    self.deals.forEach {
                        if !$0.isReaded!{
                            kol += 1
                        }
                        imgs.append( $0.img ?? UIImage() )
                        let id: Int = $0.id!
                        idArr.append(String(id))
                    }
                    self.data[3]![1] = StockCellData(images: imgs)
                    TemporaryHolder.instance.menuDeals = TemporaryHolder.instance.menuDeals + kol
                    TemporaryHolder.instance.oldDeals = self.deals
                    UserDefaults.standard.set(idArr, forKey: "deals")
                    
                    var request = URLRequest(url: URL(string: Server.SERVER + Server.PROPOSALS + "ident=\(UserDefaults.standard.string(forKey: "login") ?? "")" + "&isIOS=1")!)
                    request.httpMethod = "GET"
                    URLSession.shared.dataTask(with: request) {
                        data, error, responce in
                        guard data != nil else { return }
                        UserDefaults.standard.set(String(data: data!, encoding: .utf8) ?? "", forKey: "dealsJSON")
                    }.resume()
                    #if DEBUG
                    //                print(String(data: data!, encoding: .utf8) ?? "")
                    #endif

                }

            }.resume()
        }
        
    }
    var payNil = false
    private func fetchDebt() {
        
        let defaults = UserDefaults.standard
        
        self.data[1]![1] = ForPayCellData(title: defaults.string(forKey: "ForPayTitle") ?? "", date: defaults.string(forKey: "ForPayDate") ?? "")
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_DEBT + "login=" + login + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                if !self.refresh{
                    DispatchQueue.main.sync {
                        self.collection.reloadData()
                    }
                }else{
                    self.fetchNews(newsId: "")
                }
            }
            guard data != nil else { return }
            //            if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
            //                self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
            //                return
            //            }
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
                    //                    self.present(alert, animated: true, completion: nil)
                }
                
                //                self.data.removeValue(forKey: 4)
                
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
                
                var datePay = dateText
                if (datePay.count) > 9 {
                    datePay.removeLast(8)
                }
                self.payNil = true
                self.data[1]![1] = ForPayCellData(title: (0).formattedWithSeparator + " ₽", date: datePay)
                defaults.setValue(String(0) + " ₽", forKey: "ForPayTitle")
                defaults.setValue(datePay, forKey: "ForPayDate")
                defaults.synchronize()
                if !self.refresh{
                    DispatchQueue.main.sync {
                        self.collection.reloadData()
                    }
                }else{
                    self.fetchNews(newsId: "")
                }
                return
            }
            self.payNil = false
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.debt = AccountDebtData(json: json!)?.data!
            }
            var datePay = self.debt?.datePay
            if (datePay?.count ?? 0) > 9 {
                datePay?.removeLast(9)
            }
            if self.debt?.sumPay == nil{
                self.data[1]![1] = ForPayCellData(title: (0).formattedWithSeparator + " ₽", date: datePay ?? "")
                defaults.setValue(String(0) + " ₽", forKey: "ForPayTitle")
                defaults.setValue(datePay, forKey: "ForPayDate")
                defaults.synchronize()
            }else{
                var sum = String(format:"%.2f", self.debt?.sumPay ?? 0.0)
                if Double(self.debt?.sumPay ?? 0.0) > 999.00 || Double(self.debt?.sumPay ?? 0.0) < -999.00{
                    let i = Int(sum.distance(from: sum.startIndex, to: sum.index(of: ".")!)) - 3
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: i))
                }
                if sum.first == "-" {
                    sum.insert(" ", at: sum.index(sum.startIndex, offsetBy: 1))
                }
                self.data[1]![1] = ForPayCellData(title: sum + " ₽", date: datePay ?? "")
                defaults.setValue(String(self.debt?.sumPay ?? 0.0) + " ₽", forKey: "ForPayTitle")
                defaults.setValue(datePay, forKey: "ForPayDate")
                defaults.synchronize()
            }
//            DispatchQueue.main.sync {
//                self.collection.reloadData()
//            }
            
            #if DEBUG
            //            print(String(data: data!, encoding: .utf8)!)
            #endif
            
            }.resume()
    }
    
    private func fetchNews(newsId: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let decoded = UserDefaults.standard.object(forKey: "newsList") as? Data
            
            guard decoded != nil && ((NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]])[0]?.count ?? 0) != 0 else {
                let login = UserDefaults.standard.string(forKey: "id_account") ?? ""
                
                var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login)!)
                request.httpMethod = "GET"
                //                print("REQUEST = \(request)")
                
                URLSession.shared.dataTask(with: request) {
                    data, error, responce in
                    
                    guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else { return }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                        TemporaryHolder.instance.newsNew = NewsJsonData(json: json!)!.data!
                    }
                    UserDefaults.standard.set(String(TemporaryHolder.instance.newsNew?.first?.newsId ?? 0), forKey: "newsLastId")
                    
                    TemporaryHolder.instance.newsLastId = String(TemporaryHolder.instance.newsNew?.first?.newsId ?? 0)
                    UserDefaults.standard.synchronize()
                    self.filteredNews = TemporaryHolder.instance.newsNew?.filter { $0.isShowOnMainPage ?? false } ?? []
                    var newsArr: [NewsCellData] = []
                    //                    let dateFormatter = DateFormatter()
                    //                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    //                    self.filteredNews = self.filteredNews.sorted(by: { dateFormatter.date(from: $0.dateStart!)!.compare(dateFormatter.date(from: $1.dateStart!)!) == .orderedAscending })
                    var i = 0
                    for (_, item) in self.filteredNews.enumerated() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                        var dateStart = Date()
                        var dateEnd = Date()
                        if item.dateStart != "" && item.dateEnd != ""{
                            dateStart = dateFormatter.date(from: item.dateStart!)!
                            dateEnd = dateFormatter.date(from: item.dateEnd!)!
                        }
                        let currentDate = Date()
                        let calendar = Calendar.current
                        let currHour = calendar.component(.hour, from: currentDate)
                        let currMinutes = calendar.component(.minute, from: currentDate)
                        let currDay = calendar.component(.day, from: currentDate)
                        let currMonth = calendar.component(.month, from: currentDate)
                        let currYear = calendar.component(.year, from: currentDate)
                        
                        let startHour = calendar.component(.hour, from: dateStart)
                        let startMinutes = calendar.component(.minute, from: dateStart)
                        let startDay = calendar.component(.day, from: currentDate)
                        let startMonth = calendar.component(.month, from: currentDate)
                        let startYear = calendar.component(.year, from: currentDate)
                        if i < 3 && item.isDraft == false{
                            //                            self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                            if (currYear == startYear && currMonth == startMonth && currDay == startDay) && (currHour >= startHour && currMinutes >= startMinutes){
                                newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!))
//                                self.data[4]![i + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!)
                            }else if (currentDate <= dateEnd) && (currYear >= startYear && currMonth >= startMonth && currDay >= startDay){
                                newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!))
//                                self.data[4]![i + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!)
                            }
                            i += 1
                        }
                    }
                    self.data[4]![1] = NewNewsCellData(newsData: newsArr)
                    if (newsArr.count) < 2 {
                        self.newsSize = CGSize(width: 0, height: 0)
                    } else {
                        self.newsSize = nil
                    }
                    if UserDefaults.standard.bool(forKey: "openNotification"){
                        if (UserDefaults.standard.string(forKey: "typeNotifi") == "NEWS"){
                            UserDefaults.standard.set(false, forKey: "openNotification")
                            self.filteredNews.forEach{
                                if String($0.newsId!) == UserDefaults.standard.string(forKey: "identNotifi") ?? ""{
                                    self.tappedNews = $0
                                }
                            }
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: Segues.fromMainScreenVC.toNewsWAnim, sender: self)
                            }
                        }
                    }else{
                        DispatchQueue.main.sync {
                            self.collection.reloadData()
                        }
                        DispatchQueue.main.async {
                            self.refresh = false
//                            if #available(iOS 10.0, *) {
//                                self.collection.refreshControl?.endRefreshing()
//                            } else {
//                                self.refreshControl?.endRefreshing()
//                            }
                        }
                    }
                    return
                    }.resume()
                return
            }
            var newsArr: [NewsCellData] = []
            var decodedNewsDict = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]]
            TemporaryHolder.instance.newsNew = decodedNewsDict[0]!
            for (ind, item) in decodedNewsDict[1]!.enumerated() {
                if ind < 3 {
                    //                    self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                    if item.isImportant != nil{
                        newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!))
//                        self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!)
                    }else{
                        newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: false))
//                        self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: false)
                    }
                }
            }
            self.data[4]![1] = NewNewsCellData(newsData: newsArr)
            if (newsArr.count) < 2 {
                self.newsSize = CGSize(width: 0, height: 0)
                
            } else {
                self.newsSize = nil
            }
            DispatchQueue.main.sync {
                self.collection.reloadData()
            }
            
            //            guard decoded != nil && ((NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]])[0]?.count ?? 0) != 0 else {
            let login = UserDefaults.standard.string(forKey: "id_account") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login)!)
            request.httpMethod = "GET"
            //                print("REQUEST = \(request)")
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else { return }
                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    TemporaryHolder.instance.newsNew = NewsJsonData(json: json!)!.data!
                }
                newsArr.removeAll()
                UserDefaults.standard.set(String(TemporaryHolder.instance.newsNew?.first?.newsId ?? 0), forKey: "newsLastId")
                
                TemporaryHolder.instance.newsLastId = String(TemporaryHolder.instance.newsNew?.first?.newsId ?? 0)
                UserDefaults.standard.synchronize()
                self.filteredNews = TemporaryHolder.instance.newsNew?.filter { $0.isShowOnMainPage ?? false } ?? []
                //                    let dateFormatter = DateFormatter()
                //                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                //                    self.filteredNews = self.filteredNews.sorted(by: { dateFormatter.date(from: $0.dateStart!)!.compare(dateFormatter.date(from: $1.dateStart!)!) == .orderedAscending })
                var i = 0
                for (_, item) in self.filteredNews.enumerated() {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    var dateStart = Date()
                    var dateEnd = Date()
                    if item.dateStart != "" && item.dateEnd != ""{
                        dateStart = dateFormatter.date(from: item.dateStart!)!
                        dateEnd = dateFormatter.date(from: item.dateEnd!)!
                    }
                    let currentDate = Date()
                    let calendar = Calendar.current
                    let currHour = calendar.component(.hour, from: currentDate)
                    let currMinutes = calendar.component(.minute, from: currentDate)
                    let currDay = calendar.component(.day, from: currentDate)
                    let currMonth = calendar.component(.month, from: currentDate)
                    let currYear = calendar.component(.year, from: currentDate)
                    
                    let startHour = calendar.component(.hour, from: dateStart)
                    let startMinutes = calendar.component(.minute, from: dateStart)
                    let startDay = calendar.component(.day, from: currentDate)
                    let startMonth = calendar.component(.month, from: currentDate)
                    let startYear = calendar.component(.year, from: currentDate)
                    if i < 3 && item.isDraft == false{
                        //                            self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                        if (currYear == startYear && currMonth == startMonth && currDay == startDay) && (currHour >= startHour && currMinutes >= startMinutes){
                            newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!))
//                                self.data[4]![i + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!)
                        }else if (currentDate <= dateEnd) && (currYear >= startYear && currMonth >= startMonth && currDay >= startDay){
                            newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!))
//                                self.data[4]![i + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!)
                        }
                        i += 1
                    }
                }
                self.data[4]![1] = NewNewsCellData(newsData: newsArr)
                if (newsArr.count) < 2 {
                    self.newsSize = CGSize(width: 0, height: 0)
                    
                } else {
                    self.newsSize = nil
                }
                
                DispatchQueue.main.sync {
                    self.collection.reloadData()
                }
                if UserDefaults.standard.bool(forKey: "openNotification"){
                    if (UserDefaults.standard.string(forKey: "typeNotifi") == "NEWS"){
                        UserDefaults.standard.set(false, forKey: "openNotification")
                        self.filteredNews.forEach{
                            if String($0.newsId!) == UserDefaults.standard.string(forKey: "identNotifi") ?? ""{
                                self.tappedNews = $0
                            }
                        }
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: Segues.fromMainScreenVC.toNewsWAnim, sender: self)
                        }
                    }
                }
                return
                }.resume()
            //                return
            //            }
            decodedNewsDict = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]]
            TemporaryHolder.instance.newsNew = decodedNewsDict[0]!
            for (ind, item) in decodedNewsDict[1]!.enumerated() {
                if ind < 3 {
                    //                    self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                    if item.isImportant != nil{
                        newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!))
    //                        self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: item.isImportant!)
                    }else{
                        newsArr.append(NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: false))
    //                        self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "", isImportant: false)
                    }
                }
            }
            self.data[4]![1] = NewNewsCellData(newsData: newsArr)
            if (self.data[4]?.count ?? 0) < 2 {
                self.newsSize = CGSize(width: 0, height: 0)
                
            } else {
                self.newsSize = nil
            }
            DispatchQueue.main.sync {
                self.collection.reloadData()
            }
            
            //            let login = UserDefaults.standard.string(forKey: "id_account") ?? ""
            //            let lastId = TemporaryHolder.instance.newsLastId
            //
            ////            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + ((lastId != "" && lastId != "0") ? "&lastId=" + lastId : ""))!)
            //            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login)!)
            //            request.httpMethod = "GET"
            //            print("REQUEST = \(request)")
            //
            //            URLSession.shared.dataTask(with: request) {
            //                data, error, responce in
            //
            //                guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else { return }
            //
            //                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
            //                    TemporaryHolder.instance.news?.append(contentsOf: NewsJsonData(json: json!)!.data!)
            //                }
            //                UserDefaults.standard.set(String(TemporaryHolder.instance.news?.first?.newsId ?? 0), forKey: "newsLastId")
            //                TemporaryHolder.instance.newsLastId = String(TemporaryHolder.instance.news?.first?.newsId ?? 0)
            //                UserDefaults.standard.synchronize()
            //                self.filteredNews = TemporaryHolder.instance.news?.filter { $0.isShowOnMainPage ?? false } ?? []
            //
            //                for (ind, item) in self.filteredNews.enumerated() {
            //                    if ind < 3 {
            ////                        self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
            //                        self.data[4]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "")
            //                    }
            //                }
            //
            //                if (self.data[4]?.count ?? 0) < 2 {
            //                    self.newsSize = CGSize(width: 0, height: 0)
            //
            //                } else {
            //                    self.newsSize = nil
            //                }
            //
            //                DispatchQueue.main.sync {
            //                    self.collection.reloadData()
            //                }
            //                }.resume()
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromMainScreenVC.toCreateRequest {
            let vc = segue.destination as! TestAppsUser
            vc.dataService = dataService
            vc.isCreatingRequest_ = true
            vc.delegate = self
            
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
        } else if segue.identifier == Segues.fromMainScreenVC.toRequest {
            let vc = segue.destination as! TestAppsUser
            if UserDefaults.standard.bool(forKey: "openNotification"){
                if (UserDefaults.standard.string(forKey: "typeNotifi") == "REQUEST_COMMENT") || (UserDefaults.standard.string(forKey: "typeNotifi") == "REQUEST_STATUS"){
                    UserDefaults.standard.set(false, forKey: "openNotification")
                    vc.requestId_ = self.requestId
                    vc.pushReqID = self.requestId
                }
            }
            vc.dataService = dataService
            vc.delegate = self
            
        } else if segue.identifier == Segues.fromMainScreenVC.toSchet {
            let vc = segue.destination as! CounterChoiceType
            vc.canCount = canCount
            
        } else if segue.identifier == Segues.fromMainScreenVC.toQuestionAnim {
            let vc = segue.destination as! QuestionsTableVC
            vc.performName_ = surveyName
            vc.delegate = self
            
        } else if segue.identifier == Segues.fromMainScreenVC.toQuestions {
            let vc = segue.destination as! QuestionsTableVC
            vc.delegate = self
            
        } else if segue.identifier == Segues.fromMainScreenVC.toDeals {
            let vc = segue.destination as! DealsListDescVC
            vc.data_ = deals[safe: dealsIndex]
            vc.anotherDeals_ = deals
            
        } else if segue.identifier == Segues.fromMainScreenVC.toFinancePay {
            let vc = segue.destination as! FinancePayAcceptVC
            vc.accountData_ = debt
            
        } else if segue.identifier == Segues.fromMainScreenVC.toFinancePayComm {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.accountData_ = debt
            
        }else if segue.identifier == Segues.fromFinanceVC.toBillsArchive{
            let vc = segue.destination as! FinanceDebtArchiveVCComm
            let receipts = TemporaryHolder.instance.receipts
            var bills = receipts
            bills.removeAll()
            receipts.forEach{
                if $0.payment_name == "Не оплачен" || $0.payment_name == "ОплаченЧастично"{
                    bills.append($0)
                }
            }
            vc.title = "Неоплаченные счета"
            vc.data_ = bills
        } else if segue.identifier == Segues.fromMainScreenVC.toNewsWAnim {
            let vc = segue.destination as! NewsListTVC
            vc.tappedNews = tappedNews
            
        } else if segue.identifier == Segues.fromMainScreenVC.toRequestAnim {
            let vc = segue.destination as! TestAppsUser
            vc.dataService = dataService
            vc.requestId_ = requestId
            vc.xml_ = mainScreenXml
            vc.delegate = self
            
        } else if segue.identifier == Segues.fromMainScreenVC.toAdmission {
            let vc = segue.destination as! AdmissionVC
            vc.data_ = (appsUser?.admission!)!
            vc.comments_ = (appsUser?.admissionComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            vc.name_ = appsUser?.typeName
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = true
            }
            
        } else if segue.identifier == Segues.fromAppsUser.toServiceUK{
            let vc = segue.destination as! ServiceAppVC
            vc.data_ = (appsUser?.serviceUK!)!
            vc.comments_ = (appsUser?.serviceUKComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = true
            }
        } else if segue.identifier == Segues.fromAppsUser.toAppeal{
            let vc = segue.destination as! AppealVC
            vc.data_ = (appsUser?.appeal!)!
            vc.comments_ = (appsUser?.appealComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
//            vc.delegate = self
            vc.name_ = ""
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = true
            }
        } else if segue.identifier == Segues.fromMainScreenVC.toService {
            
            let vc = segue.destination as! TechServiceVC
            vc.data_ = (appsUser?.techService!)!
            vc.comments_ = (appsUser?.techServiceComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = true
            }
            
        } else if segue.identifier == Segues.fromMainScreenVC.toDealsList {
            let vc = segue.destination as! DealsListVC
            vc.data_ = deals
        }
    }
    
    func update() {
        update(method: "Request")
    }
    
    func update(method: String) {
        if method == "" {
            fetchDeals()
            fetchDebt()
            fetchNews(newsId: "")
            
        } else if method == "Request" {
            fetchRequests()
            
        } else if method == "Questions" {
            DispatchQueue.main.async {
                self.data[5] = [0 : CellsHeaderData(title: "ОПРОСЫ")]
                self.collection.reloadData()
            }
            fetchQuestions()
        }
    }
}

final class CellsHeader: UICollectionReusableView {
    
    @IBOutlet private(set) weak var title:   UILabel!
    @IBOutlet private(set) weak var detail:  UIButton!
    @IBOutlet private(set) weak var fonIMG:  UIImageView!
    
    @IBAction private func titlePressed(_ sender: UIButton) {
        delegate?.tapped(name: title.text ?? "")
    }
    
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: CellsHeaderData, delegate: CellsDelegate? = nil) {
        
        title.text = item.title
        //
        //        if !item.isNeedDetail {
        //            detail.isHidden = true
        //
        //        } else {
        //            detail.isHidden = false
        //        }
        
        self.delegate = delegate
        if item.title == "ЗАЯВКИ"{
            fonIMG.isHidden = false
        }else{
            fonIMG.isHidden = true
        }
        if item.title == "К ОПЛАТЕ" || item.title ==  "СЧЕТЧИКИ" {
            self.detail.setTitle("Подробнее", for: .normal)
            self.detail.setTitleColor(.white, for: .normal)
        } else if item.title == "ВЕРСИЯ" {
            self.detail.setTitleColor(.white, for: .normal)
            let dictionary = Bundle.main.infoDictionary!
            let version = dictionary["CFBundleShortVersionString"] as! String
            self.detail.setTitle("ver. " + version, for: .normal)
        } else {
            self.detail.setTitle("ВСЕ", for: .normal)
            self.detail.setTitleColor(.white, for: .normal)
        }
    }
    
}

private final class CellsHeaderData: MainDataProtocol {
    
    let title:          String
    let isNeedDetail:   Bool
    
    init(title: String, isNeedDetail: Bool = true) {
        self.title          = title
        self.isNeedDetail   = isNeedDetail
    }
}

final class NewSurveyCell: UICollectionViewCell, FSPagerViewDataSource, FSPagerViewDelegate {
    @IBOutlet private weak var pagerHeight: NSLayoutConstraint!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pagerView:   FSPagerView! {
        didSet {
            self.pagerView.register(UINib(nibName:"SurveyMainCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")
        }
    }
    
    private var itemSurvey: [SurveyCellData] = []
    private var delegate:   CellsDelegate?
    private var indexPath:  IndexPath?
    private var isLoading = false
    
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return itemSurvey.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! SurveyPagerViewCell
        cell.display(self.itemSurvey[index], indexPath: self.indexPath!, delegate: delegate!)
        return cell
    }
    
    fileprivate func display(_ item: NewSurveyCellData, delegate: CellsDelegate, indexPath: IndexPath? = nil) {
        self.delegate   = delegate
        self.indexPath  = indexPath
        pagerView.interitemSpacing = 20
        pagerView.dataSource = self
        pagerView.delegate   = self
        pagerHeight.constant = 205
        isLoading = false
        self.itemSurvey.removeAll()
        if item.surveyData.count > 3{
            for i in 0...2{
                self.itemSurvey.append(item.surveyData[i])
            }
            self.pageControl.numberOfPages = 3
        }else{
            self.itemSurvey = item.surveyData
            self.pageControl.numberOfPages = self.itemSurvey.count
        }
        self.pagerView.transformer = FSPagerViewTransformer(type: .linear)
        self.pagerView.reloadData()
        self.pagerView.automaticSlidingInterval = 3.0
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        if !isLoading {
            delegate?.stockCellPressed(currImg: index, section: self.indexPath!.section, selItem: index)
        }
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

final class SurveyPagerViewCell: FSPagerViewCell{
    
    @IBOutlet weak var title:               UILabel!
    @IBOutlet private weak var questions:   UILabel!
    @IBOutlet private weak var dateStart:   UILabel!
    @IBOutlet weak var dateHeight:      NSLayoutConstraint!
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        delegate?.pressed(at: indexPath!, title: self.title.text!)
    }
    
    private var indexPath: IndexPath?
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: SurveyCellData, indexPath: IndexPath, delegate: CellsDelegate) {
        
        self.indexPath   = indexPath
        self.delegate    = delegate
        
        title.text       = item.title
        questions.text   = item.question
        
        if item.dateStart != "" && item.dateStart != nil && !(item.dateStart.contains(find: "/")){
            dateStart.text = "Опрос проводится с \(item.dateStart.replacingOccurrences(of: " 00:00:00", with: ""))"
            dateHeight.constant = 17
            if item.dateStop != ""{
                dateStart.text = "Опрос проводится с \(item.dateStart.replacingOccurrences(of: " 00:00:00", with: "")) по \(item.dateStop.replacingOccurrences(of: " 00:00:00", with: ""))"
                dateHeight.constant = 42
            }
            dateStart.isHidden = false
        }else{
            dateHeight.constant = 0
            dateStart.text = ""
            dateStart.isHidden = true
        }
    }
}

private final class NewSurveyCellData: MainDataProtocol{
    let surveyData: [SurveyCellData]
    
    init(surveyData: [SurveyCellData]) {
        self.surveyData = surveyData
    }
}

class SurveyCell: UICollectionViewCell {
    
    @IBOutlet weak var title:               UILabel!
    @IBOutlet private weak var questions:   UILabel!
    @IBOutlet private weak var divider:     UILabel!
    @IBOutlet private weak var dateStart:   UILabel!
    @IBOutlet weak var dateHeight:      NSLayoutConstraint!
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        delegate?.pressed(at: indexPath!, title: "")
    }
    
    private var indexPath: IndexPath?
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: SurveyCellData, indexPath: IndexPath, delegate: CellsDelegate, isLast: Bool = false) {
        
        self.indexPath   = indexPath
        self.delegate    = delegate
        
        title.text       = item.title
        questions.text   = item.question
        divider.isHidden = isLast
        
        if item.dateStart != "" && item.dateStart != nil && !(item.dateStart.contains(find: "/")){
            dateStart.text = "Опрос проводится с \(item.dateStart.replacingOccurrences(of: " 00:00:00", with: ""))"
            dateHeight.constant = 17
            if item.dateStop != ""{
                dateStart.text = "Опрос проводится с \(item.dateStart.replacingOccurrences(of: " 00:00:00", with: "")) по \(item.dateStop.replacingOccurrences(of: " 00:00:00", with: ""))"
                dateHeight.constant = 42
            }
            dateStart.isHidden = false
        }else{
            dateHeight.constant = 0
            dateStart.text = ""
            dateStart.isHidden = true
        }
    }
    
    class func fromNib() -> SurveyCell? {
        var cell: SurveyCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? SurveyCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.questions.preferredMaxLayoutWidth = cell?.questions.bounds.size.width ?? 0.0
        return cell
    }
    
}

private final class SurveyCellData: MainDataProtocol {
    
    let title:      String
    let question:   String
    let dateStart:  String
    let dateStop:   String
    
    init(title: String, question: String, dateStart: String, dateStop: String) {
        self.title      = title
        self.question   = question
        self.dateStart  = dateStart
        self.dateStop   = dateStop
    }
}

final class NewNewsCell: UICollectionViewCell, FSPagerViewDataSource, FSPagerViewDelegate {
    @IBOutlet private weak var pagerHeight: NSLayoutConstraint!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pagerView:   FSPagerView! {
        didSet {
            self.pagerView.register(UINib(nibName:"NewsMainCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")
        }
    }
    
    private var itemNews: [NewsCellData] = []
    private var delegate:   CellsDelegate?
    private var indexPath:  IndexPath?
    private var isLoading = false
    
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return itemNews.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! NewsPagerViewCell
        cell.display(self.itemNews[index], indexPath: self.indexPath!, delegate: delegate!)
        return cell
    }
    
    fileprivate func display(_ item: NewNewsCellData, delegate: CellsDelegate, indexPath: IndexPath? = nil) {
        self.delegate   = delegate
        self.indexPath  = indexPath
        pagerView.interitemSpacing = 20
        pagerView.dataSource = self
        pagerView.delegate   = self
        
        pagerHeight.constant = 128
        isLoading = false
        self.itemNews = item.newsData
        self.pageControl.numberOfPages = self.itemNews.count
        self.pagerView.transformer = FSPagerViewTransformer(type: .linear)
        self.pagerView.reloadData()
        self.pagerView.automaticSlidingInterval = 3.0
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        if !isLoading {
            delegate?.stockCellPressed(currImg: index, section: self.indexPath!.section, selItem: index)
        }
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

final class NewsPagerViewCell: FSPagerViewCell{
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var date:    UILabel!
    @IBOutlet private weak var backView:    UIView!
    
    fileprivate func display(_ item: NewsCellData, indexPath: IndexPath, delegate: CellsDelegate) {
        title.text  = item.title
        desc.text   = item.desc
        
        if item.isImportant{
            backView.borderColor = mainGreenColor
        }else{
            backView.borderColor = .white
        }
        
        if item.date != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                //            if dayDifference(from: df.date(from: item.date)!, style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "HH:mm")
                
            } else {
                let dateI = df.date(from: item.date)
                let calendar = Calendar.current
                let year = calendar.component(.year, from: dateI!)
                let curYear = calendar.component(.year, from: Date())
                if year < curYear{
                    date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM YYYY")
                }else{
                    date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
                }
            }
        }
        
    }
}

private final class NewNewsCellData: MainDataProtocol{
    let newsData: [NewsCellData]
    
    init(newsData: [NewsCellData]) {
        self.newsData = newsData
    }
}

final class NewsCell: UICollectionViewCell {
    
    @IBOutlet private weak var divider: UILabel!
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var date:    UILabel!
    @IBOutlet private weak var alertNews: UILabel!
    
    fileprivate func display(_ item: NewsCellData, isLast: Bool = false) {
        
        if isLast {
            divider.isHidden = true
            
        } else {
            divider.isHidden = false
        }
        if item.isImportant{
            alertNews.isHidden = false
        }else{
            alertNews.isHidden = true
        }
        title.text  = item.title
        desc.text   = item.desc
        
        if item.date != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
                //            if dayDifference(from: df.date(from: item.date)!, style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "HH:mm")
                
            } else {
                let dateI = df.date(from: item.date)
                let calendar = Calendar.current
                let year = calendar.component(.year, from: dateI!)
                let curYear = calendar.component(.year, from: Date())
                if year < curYear{
                    date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM YYYY")
                }else{
                    date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
                }
            }
        }
        
    }
    
    class func fromNib(viewWidth: CGFloat) -> NewsCell? {
        var cell: NewsCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? NewsCell {
                cell = cellView
            }
        }
        if !isNeedToScroll() {
            cell?.title.preferredMaxLayoutWidth = viewWidth - 55
            cell?.desc.preferredMaxLayoutWidth  = viewWidth - 30
            cell?.date.preferredMaxLayoutWidth  = viewWidth - 30
            
        } else {
            cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 25) - 55
            cell?.desc.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 50
            cell?.date.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 55
        }
        return cell
    }
}

final class NewsCellData: MainDataProtocol {
    
    let title:  String
    let desc:   String
    let date:   String
    let isImportant: Bool
    
    init(title: String, desc: String, date: String, isImportant: Bool) {
        self.title  = title
        self.desc   = desc
        self.date   = date
        self.isImportant = isImportant
    }
}

final class EnableCell: UICollectionReusableView {
    
    fileprivate func display(_ item: String) {
        
    }
}

final class StockCell: UICollectionViewCell, FSPagerViewDataSource, FSPagerViewDelegate {
    
    @IBOutlet private weak var pagerHeight: NSLayoutConstraint!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pagerView:   FSPagerView! {
        didSet {
            self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        }
    }
    
    private var imgs: [UIImage] = []
    private var delegate:   CellsDelegate?
    private var indexPath:  IndexPath?
    private var isLoading = false
    
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return imgs.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        cell.imageView?.image = imgs[index]
        return cell
    }
    
    fileprivate func display(_ item: StockCellData, delegate: CellsDelegate? = nil, indexPath: IndexPath? = nil) {
        self.delegate   = delegate
        self.indexPath  = indexPath
        pagerView.interitemSpacing = 20
        pagerView.dataSource = self
        pagerView.delegate   = self
        
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        if (250.0...280.0).contains(points) {
            pagerView.itemSize = CGSize(width: 820, height: 450)
            pagerHeight.constant = 450
        }else if (300.0...320.0).contains(points) {
            pagerView.itemSize = CGSize(width: 288, height: 144)
            pagerHeight.constant = 144
            
        } else if (320.0...350.0).contains(points) {
            pagerView.itemSize = CGSize(width: 343, height: 174)
            pagerHeight.constant = 174
            
        } else if (350.0...400.0).contains(points) {
            pagerView.itemSize = CGSize(width: 343, height: 170)
            pagerHeight.constant = 170
            
        } else if (400.0...450.0).contains(points) {
            pagerView.itemSize = CGSize(width: 382, height: 180)
            pagerHeight.constant = 180
            
        } else {
            pagerView.itemSize = CGSize(width: 343, height: 170)
            pagerHeight.constant = 170
        }
        if Device().isOneOf([.iPhone5, .iPhone5s, .iPhone5c, .iPhoneSE, .simulator(.iPhoneSE)]){
            pagerView.itemSize = CGSize(width: 288, height: 144)
            pagerHeight.constant = 144
        }
        
        if item.images.count == 0, let imgData = UserDefaults.standard.data(forKey: "DealsImg"), let img = UIImage(data: imgData)  {
            isLoading = true
            self.imgs = [img]
            self.pageControl.numberOfPages = 1
            self.pagerView.reloadData()
            
        } else if item.images.count != 0 {
            isLoading = false
            self.imgs = item.images
            self.pageControl.numberOfPages = self.imgs.count
            self.pagerView.reloadData()
            
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.setValue(UIImagePNGRepresentation(item.images.first!), forKey: "DealsImg")
                UserDefaults.standard.synchronize()
            }
        }
        self.pagerView.automaticSlidingInterval = 3.0
        
        
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        if !isLoading {
            delegate?.stockCellPressed(currImg: index, section: self.indexPath!.section, selItem: index)
        }
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

private final class StockCellData: MainDataProtocol {
    
    let images:     [UIImage]
    
    init(images: [UIImage]) {
        self.images = images
    }
}

final class NewRequestCell: UICollectionViewCell, FSPagerViewDataSource, FSPagerViewDelegate {
    @IBOutlet private weak var pagerHeight: NSLayoutConstraint!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pagerView:   FSPagerView! {
        didSet {
            self.pagerView.register(UINib(nibName:"RequestMainCell", bundle: Bundle.main), forCellWithReuseIdentifier: "cell")
        }
    }
    
    private var itemRequest: [RequestCellData] = []
    private var delegate:   CellsDelegate?
    private var indexPath:  IndexPath?
    private var isLoading = false
    
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return itemRequest.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index) as! AppsPagerViewCell
        cell.display(itemRequest[index])
        return cell
    }
    
    fileprivate func display(_ item: NewRequestCellData, delegate: CellsDelegate, indexPath: IndexPath? = nil) {
        self.delegate   = delegate
        self.indexPath  = indexPath
        pagerView.interitemSpacing = 20
        pagerView.dataSource = self
        pagerView.delegate   = self
        
        isLoading = false
        self.itemRequest = item.requestData
        self.pageControl.numberOfPages = self.itemRequest.count
        if self.itemRequest.count == 0{
            pagerHeight.constant = 96
        }else{
            pagerHeight.constant = 233
        }
        self.pagerView.transformer = FSPagerViewTransformer(type: .linear)
        self.pagerView.reloadData()
        self.pagerView.automaticSlidingInterval = 3.0
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        if !isLoading {
            delegate?.stockCellPressed(currImg: index, section: self.indexPath!.section, selItem: index)
        }
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

final class AppsPagerViewCell: FSPagerViewCell{
//    @IBOutlet private var backBottom:  NSLayoutConstraint!
//    @IBOutlet private var backTop:     NSLayoutConstraint!
//    @IBOutlet private var descTop:     NSLayoutConstraint!
//    @IBOutlet private var descBottom:  NSLayoutConstraint!
    @IBOutlet private var stickHeight:  NSLayoutConstraint?
    
    @IBOutlet private weak var stickTitle:  UILabel?
    @IBOutlet private weak var title:       UILabel!
//    @IBOutlet private weak var desc:        UILabel!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var status:      UILabel!
//    @IBOutlet private weak var back:        UIView!
    fileprivate func display(_ item: RequestCellData) {
        title.text  = item.title
        if !item.isReaded{
            title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .bold)
        }else{
            title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .regular)
        }
        stickTitle?.text = item.stickTitle
//        if item.desc.contains(find: "Отправлен новый файл:") || item.desc.contains(find: "Прикреплён файл"){
//            desc.text = "Добавлен файл"
//        }else{
//            //            let mySubstring = item.desc.prefix(30)
//            //            desc.text   = String(mySubstring)
//            desc.text = item.desc
//        }
        if item.icon == UIImage(named: "orangeStatus"){
            icon.tintColor = mainOrangeColor
            status.textColor = mainOrangeColor
        }else if item.icon == UIImage(named: "grayStatus"){
            icon.tintColor = mainGrayColor
            status.textColor = mainGrayColor
        }else{
            icon.tintColor = mainGreenColor
            status.textColor = mainGreenColor
        }
        icon.image  = item.icon
        if item.status.containsIgnoringCase(find: "отправлена"){
            status.text = "В ОБРАБОТКЕ"
        }else{
            status.text = item.status.uppercased()
        }
        
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        df.isLenient = true
        date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня")
            ? dayDifference(from: df.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "")
            : dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
        
//        if item.isBack {
//            backTop.constant    = 6
//            backBottom.constant = 6
//            descTop.constant    = 48
//            descBottom.constant = 17
//            back.isHidden = false
//            stickTitle?.isHidden = false
//        } else {
//            backTop.constant    = 0
//            backBottom.constant = 0
//            descTop.constant    = 0
//            descBottom.constant = 12
//            back.isHidden = true
//            stickTitle?.isHidden = true
//            stickTitle?.frame.size.height = 0
//        }
        
        let currTitle = item.title
        let titleDateString = currTitle.substring(fromIndex: currTitle.length - 19)
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        if let titleDate = df.date(from: titleDateString) {
            df.dateFormat = "dd MMMM"
            df.locale = Locale(identifier: "Ru-ru")
            title.text = String(currTitle.dropLast(19)) + "на " + df.string(from: titleDate)
        }
        
    }
}

private final class NewRequestCellData: MainDataProtocol{
    let requestData: [RequestCellData]
    
    init(requestData: [RequestCellData]) {
        self.requestData = requestData
    }
}

final class RequestCell: UICollectionViewCell {
    
    @IBOutlet private var backBottom:  NSLayoutConstraint!
    @IBOutlet private var backTop:     NSLayoutConstraint!
    @IBOutlet private var descTop:     NSLayoutConstraint!
    @IBOutlet private var descBottom:  NSLayoutConstraint!
    @IBOutlet private var stickHeight:  NSLayoutConstraint?
    
    @IBOutlet private weak var stickTitle:  UILabel?
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var desc:        UILabel!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var status:      UILabel!
    @IBOutlet private weak var back:        UIView!
    
    fileprivate func display(_ item: RequestCellData) {
        title.text  = item.title
        if !item.isReaded{
            title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .bold)
        }else{
            title.font = UIFont.systemFont(ofSize: self.title.font.pointSize, weight: .regular)
        }
        stickTitle?.text = item.stickTitle
        if item.desc.contains(find: "Отправлен новый файл:") || item.desc.contains(find: "Прикреплён файл"){
            desc.text = "Добавлен файл"
        }else{
            //            let mySubstring = item.desc.prefix(30)
            //            desc.text   = String(mySubstring)
            desc.text = item.desc
        }
        icon.image  = item.icon
        status.text = item.status.uppercased()
        
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        df.isLenient = true
        date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня")
            ? dayDifference(from: df.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "")
            : dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
        
        if item.isBack {
            backTop.constant    = 6
            backBottom.constant = 6
            descTop.constant    = 48
            descBottom.constant = 17
            back.isHidden = false
            stickTitle?.isHidden = false
        } else {
            backTop.constant    = 0
            backBottom.constant = 0
            descTop.constant    = 0
            descBottom.constant = 12
            back.isHidden = true
            stickTitle?.isHidden = true
            stickTitle?.frame.size.height = 0
        }
        
        let currTitle = item.title
        let titleDateString = currTitle.substring(fromIndex: currTitle.length - 19)
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        if let titleDate = df.date(from: titleDateString) {
            df.dateFormat = "dd MMMM"
            df.locale = Locale(identifier: "Ru-ru")
            title.text = String(currTitle.dropLast(19)) + "на " + df.string(from: titleDate)
        }
        
    }
    
    class func fromNib(viewSize: CGFloat) -> RequestCell? {
        var cell: RequestCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? RequestCell {
                cell = view
            }
        }
        if isPlusDevices() {
            cell?.title.preferredMaxLayoutWidth = viewSize - 32//cell?.title.bounds.size.width ?? 0.0 + 20
            cell?.desc.preferredMaxLayoutWidth  = viewSize - 48//cell?.desc.bounds.size.width ?? 0.0 + 20
            
        } else {
            cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
            //            cell?.stickTitle.preferredMaxLayoutWidth = cell?.stickTitle.bounds.size.width ?? 0.0
            cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width  ?? 0.0
            cell?.stickTitle?.preferredMaxLayoutWidth  = cell?.stickTitle?.bounds.size.width  ?? 0.0
        }
        
        return cell
    }
}

final class RequestCellData: MainDataProtocol {
    
    let title:  String
    let stickTitle: String
    let desc:   String
    let icon:   UIImage
    let date:   String
    let status: String
    let isBack: Bool
    let id:     String
    let isPaid: String
    let isReaded: Bool
    let webID:  String
    
    init(title: String, desc: String, icon: UIImage, date: String, status: String, isBack: Bool, id: String, isPaid: String, stickTitle: String, isReaded: Bool, webID: String) {
        self.title  = title
        self.desc   = desc
        self.icon   = icon
        self.date   = date
        self.status = status
        self.isBack = isBack
        self.id     = id
        self.isPaid = isPaid
        self.stickTitle = stickTitle
        self.isReaded = isReaded
        self.webID  =   webID
    }
}

// Выведем версию приложения внизу
final class VersionCell: UICollectionViewCell {
    
    class func fromNib() -> VersionCell? {
        var cell: VersionCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? VersionCell {
                cell = cellView
            }
        }
        return cell
    }
    
}

final class ForPayCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var titlePay:   UILabel!
    @IBOutlet private weak var greenFon:    UIImageView!
    @IBOutlet private weak var whiteFon:    UIImageView!
//    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var pay:         UIButton!
    
    fileprivate func display(_ item: ForPayCellData) {
        pay.isHidden = true
        greenFon.isHidden = false
        whiteFon.isHidden = true
        let defaults = UserDefaults.standard
        pay.isHidden = defaults.bool(forKey: "denyOnlinePayments")
        whiteFon.isHidden = defaults.bool(forKey: "denyOnlinePayments")
        greenFon.isHidden = !defaults.bool(forKey: "denyOnlinePayments")
//        if (defaults.bool(forKey: "denyTotalOnlinePayments")) || item.title == "0 ₽"{
//            greenFon.isHidden = false
//            whiteFon.isHidden = true
//            pay.isHidden = true
//        }else{
            greenFon.isHidden = true
            whiteFon.isHidden = false
            pay.isHidden = false
//        }
        if item.title.contains(find: "-"){
            titlePay.text = "Переплата"
            title.text = item.title.replacingOccurrences(of: "-", with: "")
        }else{
            titlePay.text = "Оплатите"
            title.text = item.title
        }
//        if item.date != "" {
//            let df = DateFormatter()
//            df.dateFormat = "dd.MM.yyyy"
//            let currDate = df.date(from: item.date)
//            df.dateFormat = "dd MMMM"
//            df.locale = Locale(identifier: "Ru-ru")
//            date.text = "До " + df.string(from: currDate ?? Date())
//        }
        
        func fromNib() -> ForPayCell? {
            var cell: ForPayCell?
            let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
            nibViews?.forEach {
                if let cellView = $0 as? ForPayCell {
                    cell = cellView
                }
            }
            
            return cell
        }
    }
    
}

private final class ForPayCellData: MainDataProtocol {
    
    let title:  String
    let date:   String
    
    init(title: String, date: String) {
        self.title  = title
        self.date   = date
    }
}

final class SchetCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var date:            UILabel!
    @IBOutlet private weak var button:          UIButton!
    @IBOutlet private weak var buttonHeight:    NSLayoutConstraint!
    
    @IBAction private func buttonPressed(_ sender: UIButton) {
        delegate?.tapped(name: button.titleLabel?.text ?? "")
    }
    
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: SchetCellData, delegate: CellsDelegate? = nil) {
        title.text = item.title
        date.text  = item.date
        button.isHidden = false
        buttonHeight.constant = 48
        self.delegate = delegate
        let dateFrom = UserDefaults.standard.integer(forKey: "meterReadingsDayFrom")
        let dateTo = UserDefaults.standard.integer(forKey: "meterReadingsDayTo")
        UserDefaults.standard.synchronize()
        if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
            title.isHidden  = true
            date.text  = "Снятие и передача показаний осуществляется управляющей компанией"
            date.isHidden   = false
            button.isHidden = true
            buttonHeight.constant = 0
        }else{
            if dateTo == 0 && dateFrom == 0{
                button.isHidden = false
                buttonHeight.constant = 48
            }else if UserDefaults.standard.bool(forKey: "didntSchet") == false {
                button.isHidden = true
                buttonHeight.constant = 20
            }else{
                button.isHidden = false
                buttonHeight.constant = 48
            }
//            title.isHidden  = false
//            date.isHidden   = false
//            button.isHidden = false
        }
    }
    
    class func fromNib() -> SchetCell? {
        var cell: SchetCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? SchetCell {
                cell = cellView
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.date.preferredMaxLayoutWidth  = cell?.date.bounds.size.width ?? 0.0
        return cell
    }
}

// Вывод версии
private final class VersionCellData: MainDataProtocol {
    
}

private final class SchetCellData: MainDataProtocol {
    
    let title:  String
    let date:   String
    
    init(title: String, date: String) {
        self.title = title
        self.date  = date
    }
}

final class RequestAddCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UIButton!
    
    
    @IBAction func addRequestByTitle(_ sender: Any) {
        delegate?.tapped(name: "Оставить заявку")
    }
    
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: RequestAddCellData, delegate: CellsDelegate? = nil) {
        
        self.delegate = delegate
        title.setTitle(item.title, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

private final class RequestAddCellData: MainDataProtocol {
    
    let title: String
    
    init(title: String) {
        self.title = title
    }
}
