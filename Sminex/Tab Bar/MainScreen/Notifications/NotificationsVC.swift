//
//  NotificationsVC.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit
import CoreData
import Gloss
import SwiftyXMLParser

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, MainScreenDelegate, AppsUserDelegate {
    func update() {
        tableView.reloadData()
    }
    
    func update(method: String) {
        tableView.reloadData()
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet private weak var indicator:   UIActivityIndicatorView!
    private var appsUser: TestAppsUser?
    private var appealUser: AppealUser?
    private var dataService: [ServicesUKJson] = []
    private var mainScreenXml:  XML.Accessor?
    private var refreshControl: UIRefreshControl?
    var fetchedResultsController: NSFetchedResultsController<Notifications>?
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    var timer: Timer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TemporaryHolder.instance.menuNotifications = 0
        self.stopAnimation()
        updateUserInterface()
        let _ = getRequests()
        tableView.delegate = self
        tableView.dataSource = self
        fetchedResultsController = self.funcFetchedResultsController(entityName: "Notifications", keysForSort: ["date1"], predicateFormat: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        self.getServices()
        UserDefaults.standard.set(false, forKey: "successParse")
        if let sections = fetchedResultsController?.sections {
            for i in 0...sections[0].numberOfObjects - 1{
                let indexPath = IndexPath(row: i, section: 0)
                let push = (fetchedResultsController?.object(at: indexPath))! as Notifications
                readNotifi(id: Int(push.id))
            }
        }
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl!)
        }
//        timer = Timer(timeInterval: 5, target: self, selector: #selector(ref), userInfo: ["start" : "ok"], repeats: true)
//        RunLoop.main.add(timer!, forMode: .defaultRunLoopMode)
//        timer?.invalidate()
    }
    
    var refresh = false
    @objc private func refresh(_ sender: UIRefreshControl) {
        if !refresh{
            refresh = true
            tableView.isUserInteractionEnabled = false
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.global(qos: .background).async {
                    sleep(2)
                    DispatchQueue.main.sync {
                        self.load_new_data()
                    }
                }
            }
        }
    }
    
    func load_new_data() {
        // Экземпляр класса DB
        let db = DB()
        
        // КОММЕНТАРИИ ПО УКАЗАННОЙ ЗАЯВКЕ
        db.del_db(table_name: "Notifications")
        db.parse_Notifications(id_account: UserDefaults.standard.string(forKey: "id_account")  ?? "", readed: true)
        TemporaryHolder.instance.menuNotifications = 0
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if UserDefaults.standard.bool(forKey: "successParse"){
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.global(qos: .background).async {
                    DispatchQueue.main.sync {
                        UserDefaults.standard.set(false, forKey: "successParse")
                        self.load_data()
                        self.tableView.reloadData()
                        self.tableView.isUserInteractionEnabled = true
//                        self.stopAnimation()
                        self.refresh = false
                        if #available(iOS 10.0, *) {
                            self.tableView.refreshControl?.endRefreshing()
                        } else {
                            self.refreshControl?.endRefreshing()
                        }
                    }
                }
            }
        }
    }
    
    func load_data() {
        fetchedResultsController = self.funcFetchedResultsController(entityName: "Notifications", keysForSort: ["date1"], predicateFormat: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    func funcFetchedResultsController(entityName: String, keysForSort: [String], predicateFormat: String? = nil) -> NSFetchedResultsController<Notifications> {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)

        var sortDescriptors = [NSSortDescriptor]()
        for key in keysForSort {
            let sortDescriptor = NSSortDescriptor(key: key, ascending: false)
            sortDescriptors.append(sortDescriptor)
        }
        fetchRequest.sortDescriptors = sortDescriptors

        if predicateFormat != nil {
            fetchRequest.predicate = NSPredicate(format: predicateFormat!)
        }
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.instance.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        return fetchedResultsController as! NSFetchedResultsController<Notifications>
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключение к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
//            print(sections[section].numberOfObjects)
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let push = (fetchedResultsController?.object(at: indexPath))! as Notifications
        let cell: NotificationTableCell = self.tableView.dequeueReusableCell(withIdentifier: "NotificationTableCell") as! NotificationTableCell
        readNotifi(id: Int(push.id))
        if push.type != nil{
            cell.Name_push.text = getTitle(type: push.type!)
            cell.Body_push.text = push.name!
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            df.isLenient = true
            
            cell.Date_push.text = dayDifference(from: push.date1!, style: "dd MMMM").contains(find: "Сегодня")
                ? dayDifference(from: push.date1!, style: "HH:mm")
                : dayDifference(from: push.date1!, style: "dd MMMM")
        }
        return cell
    }
    var select = IndexPath()
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select = indexPath
        self.startAnimation()
        let push = (fetchedResultsController?.object(at: indexPath))! as Notifications
        if (push.type! == "REQUEST_COMMENT") || (push.type! == "REQUEST_STATUS") {
            let requestId = push.ident!
            appsUser = TestAppsUser()
            appsUser?.dataService = dataService
            appsUser?.requestId_ = requestId
            appsUser?.xml_ = mainScreenXml
            appsUser?.isFromNotifi_ = true
            appsUser?.isFromMain = false
            appsUser?.delegate = self
            appsUser?.prepareGroup = DispatchGroup()
            appsUser?.viewDidLoad()
            DispatchQueue.global(qos: .userInitiated).async {
                self.appsUser?.prepareGroup?.wait()
                DispatchQueue.main.async {
                    self.stopAnimation()
                    if self.appsUser?.admission != nil {
                        self.performSegue(withIdentifier: "goAdmission", sender: self)
                    } else if self.appsUser?.techService != nil {
                        self.performSegue(withIdentifier: "goTechService", sender: self)
                    } else if self.appsUser?.serviceUK != nil{
                        self.performSegue(withIdentifier: "goServiceUK", sender: self)
                    }
                }
            }
            appealUser = AppealUser()
            appealUser?.requestId_ = requestId
            appealUser?.xml_ = mainScreenXml
            appealUser?.isFromMain = false
            appealUser?.isFromNotifi_ = true
            appealUser?.delegate = self
            appealUser?.prepareGroup = DispatchGroup()
            appealUser?.viewDidLoad()
            DispatchQueue.global(qos: .userInitiated).async {
                self.appealUser?.prepareGroup?.wait()
                DispatchQueue.main.async {
                    if self.appealUser?.Appeal != nil {
                        self.stopAnimation()
                        self.performSegue(withIdentifier: "goAppeal", sender: self)
                    }
                }
            }
        } else if (push.type! == "NEWS") {
            fetchNews()
        } else if (push.type! == "QUESTION") {
            DispatchQueue.main.async {
                self.stopAnimation()
                self.performSegue(withIdentifier: "goQuestion", sender: self)
            }
            
        } else if (push.type! == "DEBT") {
            fetchDebt()
        } else if (push.type! == "METER_VALUE") {
            DispatchQueue.main.async {
                self.stopAnimation()
                self.performSegue(withIdentifier: "goCounter", sender: self)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    var index = -1
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goQuestion" {
            let vc = segue.destination as! QuestionsTableVC
            let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
            print(push.name!)
            vc.performName_ = push.name!
            vc.delegate = self
        }
        if segue.identifier == "goNews"{
            let vc = segue.destination as! NewsListTVC
            vc.tappedNews = tappedNews
            vc.isFromNotifi_ = true
        }
        if segue.identifier == "goAdmission" {
            let vc = segue.destination as! AdmissionVC
            vc.data_ = (appsUser?.admission!)!
            vc.comments_ = (appsUser?.admissionComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            vc.name_ = appsUser?.typeName
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = false
                vc.isFromNotifi_ = true
            }
            
        } else if segue.identifier == "goServiceUK"{
            let vc = segue.destination as! ServiceAppVC
            vc.data_ = (appsUser?.serviceUK!)!
            vc.comments_ = (appsUser?.serviceUKComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = false
                vc.isFromNotifi_ = true
            }
        } else if segue.identifier == "goAppeal"{
            let vc = segue.destination as! AppealVC
            vc.data_ = (appealUser?.Appeal!)!
            vc.comments_ = (appealUser?.AppealComm)!
            vc.reqId_ = appealUser?.reqId ?? ""
            //            vc.delegate = self
            vc.name_ = ""
            if appealUser?.requestId_ != "" {
                appealUser?.requestId_ = ""
                appealUser?.xml_ = nil
                vc.isFromMain_ = false
                vc.isFromNotifi_ = true
            }
        }else if segue.identifier == "goTechService" {
            
            let vc = segue.destination as! TechServiceVC
            vc.data_ = (appsUser?.techService!)!
            vc.comments_ = (appsUser?.techServiceComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = false
                vc.isFromNotifi_ = true
            }
            
        }
        if segue.identifier == "goCounter"{
            let vc = segue.destination as! CounterChoiceType
            vc.canCount = UserDefaults.standard.integer(forKey: "can_count") == 1 ? true : false
        }
//        if segue.identifier == "goFinance" {
//            let vc = segue.destination as! FinanceVC
////            vc.debt = debt
//        } else if segue.identifier == "goFinanceComm" {
//            let vc = segue.destination as! FinanceVCComm
////            vc.accountData_ = debt
//        }
    }
    public var delegate: MainScreenDelegate?
    private var questions: [QuestionDataJson]? = []
    public var questionDelegate: QuestionTableDelegate?
    
    func getTitle(type: String) -> String {
        var rezult: String = "Новое уведомление"
        if (type == "REQUEST_COMMENT") {
            rezult = "Новый комментарий"
        } else if (type == "REQUEST_STATUS") {
            rezult = "Изменен статус"
        } else if (type == "NEWS") {
            rezult = "Новая новость"
        } else if (type == "QUESTION") {
            rezult = "Новый опрос"
        } else if (type == "DEBT") {
            rezult = "Информация"
        } else if (type == "METER_VALUE") {
            rezult = "Информация по приборам"
        }
        return rezult
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UserDefaults.standard.addObserver(self, forKeyPath: "successParse", options:NSKeyValueObservingOptions.new, context: nil)
        fetchedResultsController = self.funcFetchedResultsController(entityName: "Notifications", keysForSort: ["date1"], predicateFormat: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        tableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UserDefaults.standard.removeObserver(self, forKeyPath: "successParse", context: nil)
    }
    
    private func readNotifi(id: Int) {
//        let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
        var request = URLRequest(url: URL(string: Server.SERVER + "SetNotificationReadedState.ashx?id=" + String(id))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            guard data != nil else { return }
            let responseString = String(data: data!, encoding: .utf8)!
            if responseString == "ok"{
                DispatchQueue.main.async {
                    print("OK")
//                    let db = DB()
//                    db.del_db(table_name: "Notifications")
//                    db.parse_Notifications(id_account: UserDefaults.standard.string(forKey: "id_account")  ?? "")
//                    self.tableView.reloadData()
                }
            }else{
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Ошибка серевера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
            }
            }.resume()
    }
    
    private var debt:           AccountDebtJson?
    private func fetchDebt() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_DEBT + "login=" + login + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            guard data != nil else { return }
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.debt = AccountDebtData(json: json!)?.data!
            }
            DispatchQueue.main.async {
                self.stopAnimation()
                if UserDefaults.standard.string(forKey: "typeBuilding") != ""{
                    self.performSegue(withIdentifier: "goFinanceComm", sender: self)
                }else{
                    self.performSegue(withIdentifier: "goFinance", sender: self)
                }
            }
            }.resume()
    }
    
    private var tappedNews: NewsJson?
    private func fetchNews() {
        DispatchQueue.global(qos: .userInitiated).async {
//            let decoded = UserDefaults.standard.object(forKey: "newsList") as? Data
//            var decodedNewsDict = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]]
//            TemporaryHolder.instance.newsNew = decodedNewsDict[0]!
            
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
                UserDefaults.standard.set(String(TemporaryHolder.instance.newsNew?.first?.newsId ?? 0), forKey: "newsLastId")
                
                TemporaryHolder.instance.newsLastId = String(TemporaryHolder.instance.newsNew?.first?.newsId ?? 0)
                UserDefaults.standard.synchronize()
                let filteredNews = TemporaryHolder.instance.newsNew?.filter { $0.isShowOnMainPage ?? false } ?? []
                let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
                filteredNews.forEach{
                    if String($0.newsId!) == push.ident{
                        print("OK")
                        self.tappedNews = $0
                    }
                }
                DispatchQueue.main.async {
                    self.stopAnimation()
                    self.performSegue(withIdentifier: "goNews", sender: self)
                }
                return
                }.resume()
        }
    }
    
    func getRequests() -> [RequestCellData] {
        
        var returnArr: [RequestCellData] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            let pass  = UserDefaults.standard.string(forKey: "pwd") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass + "&onlyLast=1")!)
            request.httpMethod = "GET"
            //            print(request)
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    group.leave()
                }
                guard data != nil else { return }
                
                //                print(String(data: data!, encoding: .utf8) ?? "")
                
                if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
                    self.stopAnimation()
                    self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
                    return
                }
                let xml = XML.parse(data!)
                self.mainScreenXml = xml
            }.resume()
        }
        return returnArr
    }
    
    private func getServices() {
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
            }.resume()
    }
    
    private func startAnimation() {
        indicator.isHidden = false
        indicator.startAnimating()
        tableView.isUserInteractionEnabled = false
    }
    
    private func stopAnimation() {
        indicator.isHidden = true
        indicator.stopAnimating()
        tableView.isUserInteractionEnabled = true
    }
}
