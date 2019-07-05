//
//  NewsListVC_Table.swift
//  Sminex
//
//  Created by Роман Тузин on 18.07.2018.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

class NewsListTVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loader: UIActivityIndicatorView!
    
    // MARK: Properties
    
    private var data: [NewsJson] = []
    private var index = 0
    open var tappedNews: NewsJson?
    private var rControl: UIRefreshControl?
    
    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 70
        tableView.register(UINib(nibName: "NewsTableCell", bundle: nil), forCellReuseIdentifier: "NewsTableCell")
        
        rControl = UIRefreshControl()
        rControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            tableView.refreshControl = rControl
        } else {
            tableView.addSubview(rControl!)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        if TemporaryHolder.instance.newsNew != nil {
            data = TemporaryHolder.instance.newsNew!
        }
        
        if tappedNews != nil {
            performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
        }
        startAnimation()
        getNews()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    @objc private func appDidBecomeActive() {
//        if TemporaryHolder.instance.news != nil {
//            self.data = TemporaryHolder.instance.news!
//        }
        getAllNews()
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
//        if TemporaryHolder.instance.news != nil {
//            self.data = TemporaryHolder.instance.news!
//        }
        getAllNews()
    }
    
    // MARK: Private functions
    
    private func getNews() {
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let lastId = TemporaryHolder.instance.newsLastId
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + "&lastId=" + lastId)!)
        print("REQUEST = \(request)")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    if #available(iOS 10.0, *) {
                        self.tableView.refreshControl?.endRefreshing()
                    } else {
                        self.rControl?.endRefreshing()
                    }
                    self.tableView.reloadData()
                    self.stopAnimation()
                }
            }
            
            guard data != nil else { return }
            print(String(data: data!, encoding: .utf8) ?? "")
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
//            self.data.removeAll()
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                if let newsArr = NewsJsonData(json: json!)?.data {
                    if newsArr.count != 0 {
                        TemporaryHolder.instance.newsNew?.append(contentsOf: newsArr)
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
//                        TemporaryHolder.instance.news = TemporaryHolder.instance.news?.sorted(by: { dateFormatter.date(from: $0.dateStart!)!.compare(dateFormatter.date(from: $1.dateStart!)!) == .orderedAscending })
                        TemporaryHolder.instance.newsNew?.forEach{
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                            var dateStart = Date()
                            var dateEnd = Date()
                            if $0.dateStart != "" && $0.dateEnd != ""{
                                dateStart = dateFormatter.date(from: $0.dateStart!)!
                                dateEnd = dateFormatter.date(from: $0.dateEnd!)!
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
                            if $0.isDraft == false{
                                if (currYear == startYear && currMonth == startMonth && currDay == startDay) && (currHour >= startHour && currMinutes >= startMinutes){
                                    self.data.append($0)
                                }else if (currentDate <= dateEnd) && (currYear >= startYear && currMonth >= startMonth && currDay >= startDay){
                                    self.data.append($0)
                                }
                                
                            }
                        }
//                        self.data = TemporaryHolder.instance.news!
                        
                    }
                }
            }
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    self.tableView.refreshControl?.endRefreshing()
                } else {
                    self.rControl?.endRefreshing()
                }
                self.tableView.reloadData()
                self.stopAnimation()
            }
            
            if self.data.count != 0 {
                DispatchQueue.global(qos: .background).async {
                    UserDefaults.standard.set(String(self.data.first?.newsId ?? 0), forKey: "newsLastId")
                    TemporaryHolder.instance.newsLastId = String(self.data.first?.newsId ?? 0)
                    UserDefaults.standard.synchronize()
                    let dataDict =
                        [
                            0 : self.data,
                            1 : self.data.filter { $0.isShowOnMainPage ?? false }
                    ]
                    let encoded = NSKeyedArchiver.archivedData(withRootObject: dataDict)
                    UserDefaults.standard.set(encoded, forKey: "newsList")
                    UserDefaults.standard.synchronize()
                }
            }
            
            #if DEBUG
//            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            }.resume()
    }
    private func getAllNews() {
        let login  = UserDefaults.standard.string(forKey: "id_account") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login)!)
        print("REQUEST = \(request)")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    if #available(iOS 10.0, *) {
                        self.tableView.refreshControl?.endRefreshing()
                    } else {
                        self.rControl?.endRefreshing()
                    }
                    self.tableView.reloadData()
                    self.stopAnimation()
                }
            }
            
            guard data != nil else { return }
            //            print(String(data: data!, encoding: .utf8) ?? "")
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            TemporaryHolder.instance.newsNew?.removeAll()
            self.data.removeAll()
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                if let newsArr = NewsJsonData(json: json!)?.data {
                    if newsArr.count != 0 {
                        
                        TemporaryHolder.instance.newsNew = newsArr
//                        let dateFormatter = DateFormatter()
//                        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
//                        TemporaryHolder.instance.news = TemporaryHolder.instance.news?.sorted(by: { dateFormatter.date(from: $0.dateStart!)!.compare(dateFormatter.date(from: $1.dateStart!)!) == .orderedAscending })
//                        print(TemporaryHolder.instance.news?.count)
                        
                        TemporaryHolder.instance.newsNew?.forEach{
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                            var dateStart = Date()
                            var dateEnd = Date()
                            if $0.dateStart != "" && $0.dateEnd != ""{
                                dateStart = dateFormatter.date(from: $0.dateStart!)!
                                dateEnd = dateFormatter.date(from: $0.dateEnd!)!
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
                            if $0.isDraft == false{
//                                if (currentDate <= dateEnd) && (currYear >= startYear && currMonth >= startMonth && currDay >= startDay){
                                if (Date() < dateEnd) && (Date() >= dateStart){
                                    self.data.append($0)
                                }
//                                else if (currYear == startYear && currMonth == startMonth && currDay == startDay) && (currHour >= startHour && currMinutes >= startMinutes){
//                                    self.data.append($0)
//                                }
                                
                            }
                        }
                        print(self.data.count)
                    }
                }
            }
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    self.tableView.refreshControl?.endRefreshing()
                } else {
                    self.rControl?.endRefreshing()
                }
                self.tableView.reloadData()
                self.stopAnimation()
            }
            
            if self.data.count != 0 {
                DispatchQueue.global(qos: .background).async {
                    UserDefaults.standard.set(String(self.data.first?.newsId ?? 0), forKey: "newsLastId")
                    TemporaryHolder.instance.newsLastId = String(self.data.first?.newsId ?? 0)
                    UserDefaults.standard.synchronize()
                    let dataDict =
                        [
                            0 : self.data,
                            1 : self.data.filter { $0.isShowOnMainPage ?? false }
                    ]
                    let encoded = NSKeyedArchiver.archivedData(withRootObject: dataDict)
                    UserDefaults.standard.set(encoded, forKey: "newsList")
                    UserDefaults.standard.synchronize()
                }
            }
            
            #if DEBUG
//            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if data.count > 0{
            return data.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "NewsTableCell", for: indexPath) as! NewsTableCell
        if data.count > indexPath.row{
            let news: NewsJson? = data[indexPath.row]
            cell.configure(item: news)
        }
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromNewsList.toNews, sender: self)
    }
    
    private func startAnimation() {
        loader.isHidden     = false
        tableView.isHidden = true
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        tableView.isHidden = false
        loader.stopAnimating()
        loader.isHidden     = true
    }
    
    // MARK: Actions
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromNewsList.toNews {
            let vc = segue.destination as! CurrentNews
            vc.data_ = tappedNews == nil ? data[index] : tappedNews
            vc.isFromMain_ = tappedNews != nil
            tappedNews = nil
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
        }
    }

}
