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
    private var appsUser: NewAppsUser?
    private var dataService: [ServicesUKJson] = []
    private var mainScreenXml:  XML.Accessor?
    var fetchedResultsController: NSFetchedResultsController<Notifications>?
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUserInterface()
        let _ = getRequests()
        tableView.delegate = self
        tableView.dataSource = self
        
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Notifications", keysForSort: ["date"], predicateFormat: nil) as? NSFetchedResultsController<Notifications>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        
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
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let push = (fetchedResultsController?.object(at: indexPath))! as Notifications
        print(push.date!, push.id, push.ident!, push.isReaded, push.name!, " --", push.type!)
        let cell: NotificationTableCell = self.tableView.dequeueReusableCell(withIdentifier: "NotificationTableCell") as! NotificationTableCell
        
        cell.Name_push.text = getTitle(type: push.type!)
        cell.Body_push.text = push.name!
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        df.isLenient = true
        
        cell.Date_push.text = dayDifference(from: df.date(from: push.date!) ?? Date(), style: "dd MMMM").contains(find: "Сегодня")
            ? dayDifference(from: df.date(from: push.date!) ?? Date(), style: "HH:mm")
            : dayDifference(from: df.date(from: push.date!) ?? Date(), style: "dd MMMM")
        
        return cell
    }
    var select = IndexPath()
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        select = indexPath
        let push = (fetchedResultsController?.object(at: indexPath))! as Notifications
        if !push.isReaded{
            readNotifi()
        }
        if (push.type! == "REQUEST_COMMENT") {
            let requestId = push.ident!
            appsUser = NewAppsUser()
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
                    if self.appsUser?.admission != nil {
                        self.performSegue(withIdentifier: "goAdmission", sender: self)
                    } else if self.appsUser?.techService != nil {
                        self.performSegue(withIdentifier: "goTechService", sender: self)
                    } else {
                        self.performSegue(withIdentifier: "goServiceUK", sender: self)
                    }
                }
            }
        } else if (push.type! == "REQUEST_STATUS") {
            let requestId = push.ident!
            appsUser = NewAppsUser()
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
                    if self.appsUser?.admission != nil {
                        self.performSegue(withIdentifier: "goAdmission", sender: self)
                        
                    } else if self.appsUser?.techService != nil {
                        self.performSegue(withIdentifier: "goTechService", sender: self)
                    } else {
                        self.performSegue(withIdentifier: "goServiceUK", sender: self)
                    }
                }
            }
        } else if (push.type! == "NEWS") {
            fetchNews()
        } else if (push.type! == "QUESTION") {
            self.performSegue(withIdentifier: "goQuestion", sender: self)
        } else if (push.type! == "DEBT") {
            fetchDebt()
        } else if (push.type! == "METER_VALUE") {
            self.performSegue(withIdentifier: "goCounter", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    var index = -1
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goQuestion" {
            let vc = segue.destination as! QuestionsTableVC
            let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
            vc.performName_ = push.name!
            vc.delegate = self
        }
        if segue.identifier == "goNews"{
            let vc = segue.destination as! NewsListTVC
            vc.tappedNews = tappedNews
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
                vc.isFromMain_ = true
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
                vc.isFromMain_ = true
            }
        } else if segue.identifier == "goTechService" {
            
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
            
        }
        if segue.identifier == "goCounter"{
            let vc = segue.destination as! CounterChoiceType
            vc.canCount = UserDefaults.standard.integer(forKey: "can_count") == 1 ? true : false
        }
        if segue.identifier == "goFinance" {
            let vc = segue.destination as! FinancePayAcceptVC
            vc.accountData_ = debt
        } else if segue.identifier == "goFinanceComm" {
            let vc = segue.destination as! FinancePayAcceptVCComm
            vc.accountData_ = debt
        }
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
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Notifications", keysForSort: ["date"], predicateFormat: nil) as? NSFetchedResultsController<Notifications>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        tableView.reloadData()
    }
    
    private func readNotifi() {
        let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
        var request = URLRequest(url: URL(string: Server.SERVER + "SetNotificationReadedState.ashx?id=" + String(push.id))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            guard data != nil else { return }
            let responseString = String(data: data!, encoding: .utf8)!
            if responseString == "ok"{
                DispatchQueue.main.async {
                    let db = DB()
                    db.del_db(table_name: "Notifications")
                    db.parse_Notifications(id_account: UserDefaults.standard.string(forKey: "id_account")  ?? "")
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
                    let filteredNews = TemporaryHolder.instance.newsNew?.filter { $0.isShowOnMainPage ?? false } ?? []
                    filteredNews.forEach{
                        let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
                        if $0.text == push.name{
                            self.tappedNews = $0
                        }
                    }
                    self.performSegue(withIdentifier: "goNews", sender: self)
                    return
                    }.resume()
                return
            }
            var decodedNewsDict = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]]
            TemporaryHolder.instance.newsNew = decodedNewsDict[0]!
            
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
                filteredNews.forEach{
                    let push = (self.fetchedResultsController?.object(at: self.select))! as Notifications
                    if $0.text == push.name{
                        self.tappedNews = $0
                    }
                }
                self.performSegue(withIdentifier: "goNews", sender: self)
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
                    self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
                    return
                }
                let xml = XML.parse(data!)
                self.mainScreenXml = xml
            }.resume()
        }
        return returnArr
    }
}
