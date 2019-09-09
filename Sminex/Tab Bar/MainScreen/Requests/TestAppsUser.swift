//
//  TestAppsUser.swift
//  Sminex
//
//  Created by Sergey Ivanov on 26/08/2019.
//

import UIKit
import CoreData
import Gloss
import SwiftyXMLParser

class TestAppsUser: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AppsUserDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet         weak var table:           UITableView!
    @IBOutlet         weak var collectionHeader:UICollectionView?
    @IBOutlet private weak var createButton:    UIButton?
    @IBOutlet private weak var activity:        UIActivityIndicatorView?
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    var index = 0
    @IBAction func SwipeRight(_ sender: UISwipeGestureRecognizer) {
        if index > 0{
            index -= 1
            self.startAnimator()
            collectionHeader?.selectItem(at: [0, index], animated: true, scrollPosition: .centeredVertically)
            self.collectionHeader!.reloadData()
            if self.collectionHeader?.dataSource?.collectionView(self.collectionHeader!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
                self.collectionHeader!.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
            selType = index
            dataWithType()
        }
    }
    
    @IBAction func SwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if index < dataType.count - 1{
            index += 1
            self.startAnimator()
            collectionHeader?.selectItem(at: [0, index], animated: true, scrollPosition: .centeredVertically)
            collectionHeader?.reloadData()
            if self.collectionHeader?.dataSource?.collectionView(self.collectionHeader!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
//                let rect = self.collectionHeader!.layoutAttributesForItem(at: IndexPath(item: index, section: 0))?.frame
                if index >= dataType.count - 2{
                    let pointX = (self.collectionHeader?.contentSize.width)! - self.view.frame.size.width
                    self.collectionHeader!.setContentOffset(CGPoint(x: pointX + 8, y: 0), animated: true)
                    self.collectionHeader!.setContentOffset(CGPoint(x: pointX, y: 0), animated: true)
                }
            }
            selType = index
            dataWithType()
        }
    }
    
    @IBAction private func addRequestPressed(_ sender: UIButton?) {
        
        self.startAnimator()
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.typeGroup.wait()
            
            DispatchQueue.main.async {
                self.stopAnimatior()
                self.performSegue(withIdentifier: Segues.fromAppsUser.toRequestType, sender: self)
            }
        }
    }
    
    public var requestId_ = ""
    public var isCreatingRequest_ = false
    public var delegate: MainScreenDelegate?
    public var xml_: XML.Accessor?
    public var isFromMain: Bool = false
    public var isFromNotifi_: Bool = false
    private var refreshControl: UIRefreshControl?
    var typeName = ""
    var reqId = ""
    private var responceString = ""
    private let typeGroup      = DispatchGroup()
    var prepareGroup: DispatchGroup? = nil
    private var data: [AppsUserCellData] = []
    private var fullData: [AppsUserCellData] = []
    private var rowComms: [String : [RequestComment]]  = [:]
    private var rowPersons: [String : [RequestPerson]] = [:]
    private var rowAutos:   [String : [RequestAuto]]   = [:]
    private var rowFiles:   [RequestFile] = []
    var admission: AdmissionHeaderData?
    var techService: ServiceHeaderData?
    var serviceUK: ServiceAppHeaderData?
    var admissionComm: [AdmissionCommentCellData] = []
    var techServiceComm: [ServiceCommentCellData] = []
    var serviceUKComm: [ServiceAppCommentCellData] = []
    private var rows: [String:Request] = [:]
    public var dataService: [ServicesUKJson] = []
    private var dataType: [TestAppsUserHeaderData] = []
    private var dataT = [RequestTypeStruct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(isFromMain, isFromNotifi_)
        
        updateUserInterface()
        prepareGroup?.enter()
        
        table?.delegate                         = self
        table?.dataSource                       = self
        collectionHeader?.delegate              = self
        collectionHeader?.dataSource            = self
        automaticallyAdjustsScrollViewInsets    = false
        
        self.startAnimator()
        self.dataType.append(TestAppsUserHeaderData(title: "Все", id: "0"))
        if TemporaryHolder.instance.requestTypes == nil {
            getRequestTypes()
        }else{
            if var types = TemporaryHolder.instance.requestTypes?.types {
                for i in 0...types.count - 1{
                    if types[i].name == "Обращение"{
                        types.remove(at: i)
                    }
                }
                self.dataT = types
                self.dataT.forEach{
                    self.dataType.append(TestAppsUserHeaderData(title: $0.name!, id: $0.id!))
                }
            }
        }
        self.dataType.append(TestAppsUserHeaderData(title: "Дополнительные услуги", id: "0"))
        if xml_ != nil && !isFromNotifi_{
            table?.alpha   = 0
            createButton?.alpha = 0
            DispatchQueue.global(qos: .userInitiated).async {
                self.parse(xml: self.xml_!)
            }
            
        } else {
            
            DispatchQueue.main.async {
                self.getRequests()
            }
            
            if isCreatingRequest_ {
                addRequestPressed(nil)
            }
            
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            if #available(iOS 10.0, *) {
                table?.refreshControl = refreshControl
            } else {
                table?.addSubview(refreshControl!)
            }
        }
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        DispatchQueue.main.async {
            self.getRequests()
        }
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.isHidden = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TestAppsUserCell", for: indexPath) as! TestAppsUserCell
//        if data[indexPath.row] != nil{
            cell.display(data[indexPath.row])
//        }
        if indexPath.row == self.data.count - 1 {
            self.loadMore()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.startAnimator()
        prepareTapped(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataType.count
    }
    var firstLoad = true
    var selType = 0
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = TestAppsUserHeader.fromNib()
        if firstLoad && indexPath.row == 0{
            firstLoad = false
            cell?.display(dataType[indexPath.row], selectIndex: true)
        }else if selType == indexPath.row{
            cell?.display(dataType[indexPath.row], selectIndex: true)
        }else{
            cell?.display(dataType[indexPath.row], selectIndex: false)
        }
        
        var size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        if size.width < 50{
            size.width = 50
        }
        return CGSize(width: size.width + 4, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestAppsUserHeader", for: indexPath) as! TestAppsUserHeader
        if firstLoad && indexPath.row == 0{
            firstLoad = false
            cell.display(dataType[indexPath.row], selectIndex: true)
        }else if selType == indexPath.row{
            cell.display(dataType[indexPath.row], selectIndex: true)
        }else{
            cell.display(dataType[indexPath.row], selectIndex: false)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.startAnimator()
        collectionHeader?.reloadData()
        selType = indexPath.row
        if self.collectionHeader?.dataSource?.collectionView(self.collectionHeader!, cellForItemAt: IndexPath(row: 0, section: 0)) != nil {
            if selType >= dataType.count - 2 && index < selType{
                let pointX = (self.collectionHeader?.contentSize.width)! - self.view.frame.size.width
                self.collectionHeader!.setContentOffset(CGPoint(x: pointX + 8, y: 0), animated: true)
            }else{
                self.collectionHeader!.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
        }
        index = selType
        dataWithType()
    }
    
    func dataWithType(){
        if selType != 0{
            DispatchQueue.global(qos: .background).async {
                self.data.removeAll()
                let dat = self.fullData
                self.data.removeAll()
                self.dataChoice = dat.filter(){ $0.title == self.dataType[self.selType].title || ($0.title == "Заявка на услугу" && self.dataType[self.selType].title == "Дополнительные услуги") }
                self.choiceCount = self.dataChoice.count
                self.data.removeAll()
                if self.dataChoice.count > 20{
                    for i in 0...19{
                        self.data.append(self.dataChoice[i])
                    }
                }else{
                    for i in 0...self.dataChoice.count - 1{
                        self.data.append(self.dataChoice[i])
                    }
                }
                self.offset = 19
                self.self.reachedEndOfItems = false
                DispatchQueue.main.async {
                    self.table?.reloadData()
                    self.stopAnimatior()
                    if #available(iOS 10.0, *) {
                        self.table?.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }else{
            DispatchQueue.global(qos: .background).async {
                self.offset = 19
                self.reachedEndOfItems = false
                self.data.removeAll()
                if self.fullData.count > 20{
                    for i in 0...19{
                        self.data.append(self.fullData[i])
                        //                        firstArr.removeFirst()
                    }
                }else{
                    for i in 0...self.fullData.count - 1{
                        self.data.append(self.fullData[i])
                        //                        firstArr.removeFirst()
                    }
                }
                DispatchQueue.main.async {
                    self.table?.reloadData()
                    self.stopAnimatior()
                    if #available(iOS 10.0, *) {
                        self.table?.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
        
    }
    // number of items to be fetched each time (i.e., database LIMIT)
    let itemsPerBatch = 19
    private var dataChoice: [AppsUserCellData] = []
    // Where to start fetching items (database OFFSET)
    var offset = 19
    var fullCount = 0
    var choiceCount = 0
    // a flag for when all database items have already been loaded
    var reachedEndOfItems = false
    
    func loadMore() {
        // don't bother doing another db query if already have everything
        if selType != 0{
            guard !self.reachedEndOfItems else {
                return
            }
            if choiceCount < 20{
                return
            }
            self.startAnimator()
            // query the db on a background thread
            DispatchQueue.global(qos: .background).async {
                
                // determine the range of data items to fetch
                var thisBatchOfItems: [AppsUserCellData] = []
                let start = self.offset
                var end = self.offset + self.itemsPerBatch
                if end > self.choiceCount{
                    end = self.choiceCount - 1
                }
                for i in start...end{
                    thisBatchOfItems.append(self.dataChoice[i])
                }
                // update UITableView with new batch of items on main thread after query finishes
                DispatchQueue.main.async {
                    
                    if thisBatchOfItems.count != 0 {
                        //                    if thisBatchOfItems.title
                        // append the new items to the data source for the table view
                        self.data += thisBatchOfItems
                        // reload the table view
                        self.table?.reloadData()
                        
                        self.stopAnimatior()
                        if #available(iOS 10.0, *) {
                            self.table?.refreshControl?.endRefreshing()
                        } else {
                            self.refreshControl?.endRefreshing()
                        }
                        // check if this was the last of the data
                        if thisBatchOfItems.count < self.itemsPerBatch {
                            self.reachedEndOfItems = true
                        }
                        
                        // reset the offset for the next data query
                        self.offset += self.itemsPerBatch
                    }else{
                        self.stopAnimatior()
                    }
                }
            }
        }else{
            guard !self.reachedEndOfItems else {
                return
            }
            if fullCount < 20{
                return
            }
            self.startAnimator()
            // query the db on a background thread
            DispatchQueue.global(qos: .background).async {
                
                // determine the range of data items to fetch
                var thisBatchOfItems: [AppsUserCellData] = []
                let start = self.offset
                var end = self.offset + self.itemsPerBatch
                if end > self.fullCount{
                    end = self.fullCount - 1
                }
                for i in start...end{
                    thisBatchOfItems.append(self.fullData[i])
                }
                // update UITableView with new batch of items on main thread after query finishes
                DispatchQueue.main.async {
                    
                    if thisBatchOfItems.count != 0 {
                        //                    if thisBatchOfItems.title
                        // append the new items to the data source for the table view
                        self.data += thisBatchOfItems
                        // reload the table view
                        self.table?.reloadData()
                        
                        self.stopAnimatior()
                        if #available(iOS 10.0, *) {
                            self.table?.refreshControl?.endRefreshing()
                        } else {
                            self.refreshControl?.endRefreshing()
                        }
                        // check if this was the last of the data
                        if thisBatchOfItems.count < self.itemsPerBatch {
                            self.reachedEndOfItems = true
                        }
                        
                        // reset the offset for the next data query
                        self.offset += self.itemsPerBatch
                    }else{
                        self.stopAnimatior()
                    }
                }
            }
        }
    }
    
    func getRequestTypes() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REQUEST_TYPE + "accountid=" + id)!)
        request.httpMethod = "GET"
        print(request)
        self.typeGroup.enter()
        URLSession.shared.dataTask(with: request) {
            data, responce, error in
            
            defer {
                self.typeGroup.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.responceString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
            //                print(self.responceString)
            #endif
            
            DispatchQueue.main.sync {
                
                if self.responceString.contains(find: "error") {
                    let alert = UIAlertController(title: "Ошибка сервера", message: self.responceString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                        TemporaryHolder.instance.choise(json!)
                        
                    }
                    //                    let type: RequestTypeStruct
                    //                    type = .init(id: "3", name: "Услуги службы комфорта")
                    if var types = TemporaryHolder.instance.requestTypes?.types {
                        for i in 0...types.count - 1{
                            if types[i].name == "Обращение"{
                                types.remove(at: i)
                            }
                        }
                        self.dataT = types
                        self.dataT.forEach{
                            self.dataType.append(TestAppsUserHeaderData(title: $0.name!, id: $0.id!))
                        }
                    }
                }
            }
            }.resume()
    }
    
    func getRequests(isBackground: Bool = false) {
        
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            
            let login = UserDefaults.standard.string(forKey: "login")!
            let pass  = UserDefaults.standard.string(forKey: "pwd") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass)!)
            request.httpMethod = "GET"
                        print(request)
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                //                defer {
                //                    group.leave()
                //                }
                guard data != nil else { return }
                if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
                    self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
                    return
                }
                #if DEBUG
                                print(String(data: data!, encoding: .utf8)!)
                
                #endif
                let xml = XML.parse(data!)
                self.parse(xml: xml)
                group.leave()
                }.resume()
        }
    }
    
    func parse(xml: XML.Accessor) {
        let requests = xml["Requests"]
        rowFiles.removeAll()
        let row = requests["Row"]
        self.rows.removeAll()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            row.forEach { row in
                
                self.rows[row.attributes["ID"]!] = Request(row: row)
                self.rowComms[row.attributes["ID"]!] = []
                self.rowPersons[row.attributes["ID"]!] = []
                self.rowAutos[row.attributes["ID"]!] = []
                
                row["Comm"].forEach {
                    self.rowComms[row.attributes["ID"]!]?.append( RequestComment(row: $0) )
                }
                
                row["Persons"].all?.forEach {
                    $0.childElements.forEach {
                        self.rowPersons[row.attributes["ID"]!]?.append( RequestPerson(row: $0)  )
                    }
                }
                
                row["Autos"].all?.forEach {
                    $0.childElements.forEach {
                        self.rowAutos[row.attributes["ID"]!]?.append( RequestAuto(row: $0) )
                    }
                }
                
                row["File"].forEach {
                    self.rowFiles.append( RequestFile(row: $0) )
                }
            }
            
            var newData: [AppsUserCellData] = []
            self.rows.forEach { _, curr in
                var isAnswered = (self.rowComms[curr.id!]?.count ?? 0) <= 0 ? false : true
                
                var lastComm = (self.rowComms[curr.id!]?.count ?? 0) <= 0 ? nil : self.rowComms[curr.id!]?[(self.rowComms[curr.id!]?.count)! - 1]
                let df = DateFormatter()
                df.dateFormat = "dd.MM.yyyy HH:mm:ss"
                let addReq = df.date(from: curr.added!)
                let updateDate = df.date(from: curr.updateDate!)
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
                if lastComm != nil && curr.isPaid == "1" && (self.rowComms[curr.id!]?.count)! == 1{
                    lastComm = nil
                    isAnswered = false
                }
                let icon = !(curr.status?.contains(find: "Отправлена") ?? false) ? UIImage(named: "check_label")! : UIImage(named: "processing_label")!
                let isPerson = curr.name?.contains(find: "ропуск") ?? false
                
                var persons = ""//curr.responsiblePerson ?? ""
                
                if persons == "" {
                    self.rowPersons[curr.id ?? ""]?.forEach {
                        if $0.id == self.rowPersons[curr.id ?? ""]?.last?.id {
                            persons += ($0.fio ?? "") + " "
                            
                        } else {
                            persons += ($0.fio ?? "") + ", "
                        }
                    }
                }
                
                let descText = isPerson ? (persons == "" ? "Не указано" : persons) : curr.text ?? ""
                if curr.isPaid == "1"{
                    var name = curr.name
                    if (curr.name?.contains(find: "Заказ услуги: "))!{
                        name = curr.name?.replacingOccurrences(of: "Заказ услуги: ", with: "")
                    }
                    if (curr.name?.contains(find: "Заказ услуги "))!{
                        name = curr.name?.replacingOccurrences(of: "Заказ услуги ", with: "")
                    }
                    newData.append( AppsUserCellData(title: "Заявка на услугу",
                                                     desc: (self.rowComms[curr.id!]?.count == 0 || lastComm == nil) ? name! : lastComm?.text ?? "",
                                                     icon: icon,
                                                     status: curr.status ?? "",
                                                     date: curr.updateDate ?? "",
                                                     isBack: isAnswered,
                                                     type: curr.idType ?? "",
                                                     id: curr.id ?? "",
                                                     updateDate: (curr.updateDate == "" ? curr.dateFrom : curr.updateDate) ?? "",
                                                     stickTitle: isAnswered ? name! : "", isPaid: curr.isPaid!, webID: curr.webID ?? ""))
                }else{
                    newData.append( AppsUserCellData(title: curr.name ?? "",
                                                     desc: (self.rowComms[curr.id!]?.count == 0 || lastComm == nil) ? descText : lastComm?.text ?? "",
                                                     icon: icon,
                                                     status: curr.status ?? "",
                                                     date: curr.updateDate ?? "",
                                                     isBack: isAnswered,
                                                     type: curr.idType ?? "",
                                                     id: curr.id ?? "",
                                                     updateDate: (curr.updateDate == "" ? curr.dateFrom : curr.updateDate) ?? "",
                                                     stickTitle: isAnswered ? descText : "", isPaid: curr.isPaid ?? "", webID: curr.webID ?? ""))
                }
                
            }
            
            var firstArr = newData.filter {
                $0.status.contains(find: "обработке")
                    ||  $0.status.contains(find: "Отправлена")
                    ||  $0.status.contains(find: "выполнению")
                    ||  $0.status.contains(find: "Черновик")
                    ||  $0.status.contains(find: "Закрыта")
                    ||  $0.status.contains(find: "Закрыто")
            }
            var secondArr = newData.filter {
                $0.status.contains(find: "Отклонена")
                    ||  $0.status.contains(find: "Оформленно")
                    ||  $0.status.contains(find: "Выдан")
                    ||  $0.status.contains(find: "Отклонено")
            }
            
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            df.isLenient = true
            df.timeZone = TimeZone(identifier: "GMT+3:00")
            
            firstArr  = firstArr.sorted  { (df.date(from: $0.updateDate) ?? Date()).compare((df.date(from: $1.updateDate)) ?? Date()) == .orderedDescending }
            secondArr = secondArr.sorted { (df.date(from: $0.updateDate) ?? Date()).compare((df.date(from: $1.updateDate)) ?? Date()) == .orderedDescending }
            firstArr.append(contentsOf: secondArr)
            DispatchQueue.main.sync {
                self.createButton?.isUserInteractionEnabled = false
                if firstArr.count != 0{
                    self.fullData = firstArr
                    self.fullCount = self.fullData.count
                    self.data.removeAll()
                    if self.selType != 0{
                        self.dataWithType()
                    }else{
                        if self.isFromMain{
                            self.data = firstArr
                        }else{
                            if firstArr.count > 20{
                                for i in 0...19{
                                    self.data.append(firstArr[i])
                                    //                        firstArr.removeFirst()
                                }
                            }else{
                                for i in 0...firstArr.count - 1{
                                    self.data.append(firstArr[i])
                                    //                        firstArr.removeFirst()
                                }
                            }
                            
                        }
                        var typeIn = false
                        let dataType1 = self.dataType
                        self.dataType.removeAll()
                        self.dataType.append(TestAppsUserHeaderData(title: "Все", id: "0"))
                        for k in 0...dataType1.count - 1{
                            for i in 0...self.fullData.count - 1{
                                if self.fullData[i].title.containsIgnoringCase(find: "услугу"){
                                    if dataType1[k].title == "Дополнительные услуги" && !typeIn{
                                        typeIn = true
                                    }
                                }else{
                                    
                                    if (self.fullData[i].title == dataType1[k].title) && !typeIn{
                                        typeIn = true
                                    }
                                }
                            }
                            if typeIn{
                                if self.dataType.count == 0{
                                    self.dataType.append(dataType1[k])
                                }else{
                                    var addT = false
                                    self.dataType.forEach{
                                        if $0.title == dataType1[k].title{
                                            addT = true
                                        }
                                    }
                                    if !addT{
                                        self.dataType.append(dataType1[k])
                                    }
                                }
                            }
                            typeIn = false
                        }
                        self.collectionHeader?.reloadData()
                        self.table?.reloadData()
                        self.stopAnimatior()
                        if #available(iOS 10.0, *) {
                            self.table?.refreshControl?.endRefreshing()
                        } else {
                            self.refreshControl?.endRefreshing()
                        }
                    }
                }else{
                    self.collectionHeader?.isHidden = true
                }
                
                if self.requestId_ != "" {
                    for index in 0...self.fullCount - 1{
                        if self.fullData[index].id == self.requestId_ || self.fullData[index].webID == self.requestId_{
                            if self.table != nil {
                                self.tableView(self.table, didSelectRowAt: IndexPath(row: index, section: 0))
                            } else {
                                print(self.fullData[index].title, self.fullData[index].stickTitle, self.fullData[index].desc)
                                self.prepareTapped(IndexPath(row: index, section: 0))
                            }
                        }
                    }
                    
                }
            }
            sleep(2)
            DispatchQueue.main.async {
                self.createButton?.isUserInteractionEnabled = true
                self.createButton?.isHidden = false
            }
        }
    }
    
    func prepareTapped(_ indexPath: IndexPath) {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.typeGroup.wait()
            
            DispatchQueue.main.async {
                self.stopAnimatior()
                
                var type = self.data[indexPath.row].type
                // Это костыль - думать, как лучше сделать.
//                var itsNever: Bool = false
                print(type)
                TemporaryHolder.instance.requestTypes?.types?.forEach {
                    if $0.id == type {
                        type = $0.name ?? ""
//                        itsNever = true
                    }
                    
                }
//                print(TemporaryHolder.instance.requestTypes?.types)
                print(type)
                //                if (!itsNever) {
                //                    type = "Гостевой пропуск"
                //                }
                
                if self.data[indexPath.row].title.contains(find: "ропуск") {
                    self.typeName = type
                    print(self.rows)
                    let row = self.rows[self.data[indexPath.row].id]!
                    var persons = row.responsiblePerson ?? ""
                    
                    if persons == "" {
                        self.rowPersons[row.id ?? ""]?.forEach {
                            if $0.id == self.rowPersons[row.id ?? ""]?.last?.id {
                                persons += ($0.fio ?? "") + " "
                                
                            } else {
                                persons += ($0.fio ?? "") + ", "
                            }
                        }
                    }
                    
                    var auto = ""
                    var mark = ""
                    self.rowAutos[row.id!]?.forEach {
                        if $0.number != "" && $0.number != nil {
                            auto = auto + ($0.number ?? "")
                        }
                        if $0.number != self.rowAutos[row.id!]?.last?.number {
                            auto = auto + ", "
                        }
                        if $0.mark != "" && $0.mark != nil {
                            mark = mark + ($0.mark ?? "")
                        }
                        if $0.mark != self.rowAutos[row.id!]?.last?.mark {
                            mark = mark + ", "
                        }
                    }
                    
                    var images: [String] = []
                    
                    self.admissionComm = []
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if $0.fileId == comm.idFile {
                                commImg = $0.fileId
                            }
                        }
                        if !(comm.text?.containsIgnoringCase(find: "+skip"))!{
                            self.admissionComm.append ( AdmissionCommentCellData(image: UIImage(named: "account")!,
                                                                                 title: comm.name ?? "",
                                                                                 comment: comm.text ?? "",
                                                                                 date: comm.createdDate ?? "",
                                                                                 commImg: nil,
                                                                                 commImgUrl: commImg,
                                                                                 id: comm.id ?? "") )
                        }else{
                            images.append(commImg!)
                        }
                    }
                    if images.count == 0{
                        self.rowFiles.forEach { files in
                            if files.reqID == row.id{
                                var i = false
                                self.techServiceComm.forEach { comm in
                                    if comm.imgUrl == files.fileId!{
                                        i = true
                                    }
                                }
                                if i == false{
                                    images.append(files.fileId!)
                                }
                            }
                        }
                    }
                    self.admission = AdmissionHeaderData(icon: self.data[indexPath.row].icon,
                                                         gosti: persons == "" ? "Не указано" : persons,
                                                         mobileNumber: row.phoneNum ?? "",
                                                         gosNumber: auto, mark: mark,
                                                         date: (row.dateTo != "" ? row.dateTo : row.planDate) ?? "",
                                                         status: row.status ?? "",
                                                         images: [],
                                                         imagesUrl: images, desc: row.text!, placeHome: row.premises!)
                    self.reqId = row.id ?? ""
                    if self.table != nil {
                        self.performSegue(withIdentifier: Segues.fromAppsUser.toAdmission, sender: self)
                    }
                    self.prepareGroup?.leave()
                    
                } else if self.data[indexPath.row].title.containsIgnoringCase(find: "услуг"){
                    let row = self.rows[self.data[indexPath.row].id]!
                    var images: [String] = []
                    var dataServ: ServicesUKJson!
                    self.dataService.forEach{
                        if $0.name == self.data[indexPath.row].desc || $0.name == self.data[indexPath.row].stickTitle{
                            dataServ = $0
                        }
                    }
                    if dataServ != nil{
                        var serviceDesc = ""
                        if dataServ?.shortDesc == "" || dataServ?.shortDesc == " "{
                            serviceDesc  = String((dataServ?.desc?.prefix(100))!) + "..."
                        }else{
                            serviceDesc  = dataServ?.shortDesc ?? ""
                        }
                        var imageIcon = UIImage()
                        if let imageV = UIImage(data: Data(base64Encoded: ((dataServ?.picture!.replacingOccurrences(of: "data:image/png;base64,", with: ""))!)) ?? Data()) {
                            imageIcon = imageV
                        }
                        var emails = ""
                        if row.emails == ""{
                            emails = UserDefaults.standard.string(forKey: "mail")!
                        }else{
                            emails = row.emails!
                        }
                        var place = ""
                        let parkingsPlace = UserDefaults.standard.stringArray(forKey: "parkingsPlace")!
                        if row.premises == ""{
                            parkingsPlace.forEach{
                                place = place + $0
                            }
                        }else{
                            place = row.premises!
                        }
                        
                        self.serviceUKComm = []
                        self.rowComms[row.id!]!.forEach { comm in
                            
                            var commImg: String?
                            
                            self.rowFiles.forEach {
                                
                                if $0.fileId == comm.idFile {
                                    commImg = $0.fileId!
                                }
                            }
                            if !(comm.text?.containsIgnoringCase(find: "+skip"))!{
                                self.serviceUKComm.append( ServiceAppCommentCellData(image: UIImage(named: "account")!,
                                                                                     title: comm.name ?? "",
                                                                                     comment: comm.text ?? "",
                                                                                     date: comm.createdDate ?? "",
                                                                                     commImg: nil,
                                                                                     commImgUrl: commImg,
                                                                                     id: comm.id ?? ""))
                            }else{
                                images.append(commImg!)
                            }
                        }
                        if images.count == 0{
                            self.rowFiles.forEach { files in
                                if files.reqID == row.id{
                                    var i = false
                                    self.techServiceComm.forEach { comm in
                                        if comm.imgUrl == files.fileId!{
                                            i = true
                                        }
                                    }
                                    if i == false{
                                        images.append(files.fileId!)
                                    }
                                }
                            }
                        }
                        self.serviceUK = ServiceAppHeaderData(icon: UIImage(named: "account")!, price: dataServ.cost ?? "", mobileNumber: row.phoneNum ?? "", servDesc: serviceDesc, email: emails, date: (row.dateTo != "" ? row.dateTo : row.planDate) ?? "", status: row.status ?? "", images: [], imagesUrl: images, desc: row.text ?? "", placeHome: place, soonPossible: row.soonPossible, title: dataServ.name ?? "", servIcon: imageIcon, selectPrice: dataServ.selectCost!, selectPlace: dataServ.selectPlace!)
                        self.reqId = row.id ?? ""
                        if self.table != nil {
                            self.performSegue(withIdentifier: Segues.fromAppsUser.toServiceUK, sender: self)
                        }
                        self.prepareGroup?.leave()
                    }
                    
                } else {
                    let row = self.rows[self.fullData[indexPath.row].id]!
                    var images: [String] = []
                    
                    self.techServiceComm = []
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if $0.fileId == comm.idFile{
                                commImg = $0.fileId!
                            }
                        }
                        if !(comm.text?.containsIgnoringCase(find: "+skip"))!{
                            self.techServiceComm.append( ServiceCommentCellData(icon: UIImage(named: "account")!,
                                                                                title: comm.name ?? "",
                                                                                desc: comm.text ?? "",
                                                                                date: comm.createdDate ?? "",
                                                                                image: nil,
                                                                                imageUrl: commImg,
                                                                                id: comm.id ?? ""))
                        }else{
                            images.append(commImg!)
                        }
                        
                    }
                    if images.count == 0{
                        self.rowFiles.forEach { files in
                            if files.reqID == row.id{
                                var i = false
                                self.techServiceComm.forEach { comm in
                                    if comm.imgUrl == files.fileId!{
                                        i = true
                                    }
                                }
                                if i == false{
                                    images.append(files.fileId!)
                                }
                            }
                        }
                    }
                    self.techService = ServiceHeaderData(icon: self.fullData[indexPath.row].icon,
                                                         problem: row.text ?? "",
                                                         date: (row.dateTo != "" ? row.dateTo : row.planDate) ?? "",
                                                         status: row.status ?? "",
                                                         images: [],
                                                         imagesUrl: images, isPaid: row.isPaid ?? "", placeHome: row.premises ?? "", soonPossible: row.soonPossible)
                    self.reqId = row.id ?? ""
                    if self.table != nil {
                        self.performSegue(withIdentifier: Segues.fromAppsUser.toService, sender: self)
                    }
                    self.prepareGroup?.leave()
                    
                }
            }
        }
    }
    
    private func startAnimator() {
        //        DispatchQueue.main.sync{
        self.activity?.isHidden       = false
        //            self.createButton?.isHidden   = true
        //            self.collectionHeader?.isHidden = true
        self.activity?.startAnimating()
        //        }
    }
    
    private func stopAnimatior() {
        //        DispatchQueue.main.sync{
        self.activity?.stopAnimating()
        //            self.collectionHeader?.isHidden = false
        self.activity?.isHidden       = true
        //            self.createButton?.isHidden   = false
        //        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromAppsUser.toAdmission {
            let vc = segue.destination as! AdmissionVC
            vc.data_ = admission!
            vc.comments_ = admissionComm
            vc.reqId_ = reqId
            vc.delegate = self
            vc.name_ = typeName
            if self.requestId_ != "" {
                self.requestId_ = ""
                self.xml_ = nil
                if isFromMain{
                    vc.isFromMain_ = true
                }
                if isFromNotifi_{
                    vc.isFromMain_ = false
                    vc.isFromNotifi_ = true
                }
            }
            
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
        }else if segue.identifier == Segues.fromAppsUser.toServiceUK {
            let vc = segue.destination as! ServiceAppVC
            var data: ServicesUKJson!
            dataService.forEach{
                if $0.name == serviceUK?.title{
                    data = $0
                }
            }
            vc.serviceData = data
            vc.comments_ = serviceUKComm
            vc.data_ = serviceUK!
            vc.reqId_ = reqId
            vc.delegate = self
            if self.requestId_ != "" {
                self.requestId_ = ""
                self.xml_ = nil
                if isFromMain{
                    vc.isFromMain_ = true
                }
                if isFromNotifi_{
                    vc.isFromMain_ = false
                    vc.isFromNotifi_ = true
                }
            }
        } else if segue.identifier == Segues.fromAppsUser.toService {
            let vc = segue.destination as! TechServiceVC
            vc.data_ = techService!
            vc.comments_ = techServiceComm
            vc.reqId_ = reqId
            vc.delegate = self
            if self.requestId_ != "" {
                self.requestId_ = ""
                self.xml_ = nil
                if isFromMain{
                    vc.isFromMain_ = true
                }
                if isFromNotifi_{
                    vc.isFromMain_ = false
                    vc.isFromNotifi_ = true
                }
            }
            
        } else if segue.identifier == Segues.fromAppsUser.toRequestType {
            let vc = segue.destination as! NewRequestTypeVC
            vc.delegate = self
        }
    }
    
    private func dateTeck(_ date: String) -> (String)? {
        
        if date == "" {
            return ""
        }
        
        let dateFormatter           = DateFormatter()
        dateFormatter.dateFormat    = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.date(from: date)
        
        return DateFormatter.localizedString(from: dateString!, dateStyle: .short, timeStyle: .short)
    }
    
    func update() {
        startAnimator()
        DispatchQueue.main.async {
            self.delegate?.update(method: "Request")
            self.getRequests()
        }
    }
}

final class TestAppsUserHeader: UICollectionViewCell {
    
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var selLine:         UILabel!
    
    private var type: String?
    
    fileprivate func display(_ item: TestAppsUserHeaderData, selectIndex: Bool) {
        title.text = item.title
        if selectIndex{
            selLine.backgroundColor = .darkGray
        }else{
            selLine.backgroundColor = .lightGray
        }
    }
    
    class func fromNib() -> TestAppsUserHeader? {
        var cell: TestAppsUserHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? TestAppsUserHeader {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        return cell
    }
}

final class TestAppsUserCell: UITableViewCell {
    
    @IBOutlet private weak var skTitleHeight: NSLayoutConstraint!
    @IBOutlet private weak var skTitleBottm: NSLayoutConstraint!
    @IBOutlet private weak var icon:            UIImageView!
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var stickTitle:      UILabel!
    @IBOutlet private weak var desc:            UILabel!
    @IBOutlet private weak var status:          UILabel!
    @IBOutlet private weak var date:            UILabel!
    @IBOutlet private weak var back:            UIView!
    
    private var type: String?
    
    fileprivate func display(_ item: AppsUserCellData) {
        desc.isHidden = false
        if item.desc.contains(find: "Отправлен новый файл:") || item.desc.contains(find: "Прикреплён файл"){
            desc.text = "Добавлен файл"
        }else{
            //            let mySubstring = item.desc.prefix(30)
            desc.text   = item.desc
        }
        icon.image      = item.icon
        status.text     = item.status
        back.isHidden   = !item.isBack
        type            = item.type
        if item.stickTitle == "" {
            skTitleBottm.constant = 0
            skTitleHeight.constant = 0
            stickTitle.text = ""
            
        } else {
            skTitleBottm.constant = 15
            skTitleHeight.constant = 42
            stickTitle.text = item.stickTitle
            let k = stickTitle.calculateMaxLines()
            if k == 1{
                skTitleBottm.constant = 15
                skTitleHeight.constant = 21
            }
        }
        
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        df.isLenient = true
        
        date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня")
            ? dayDifference(from: df.date(from: item.date) ?? Date(), style: "HH:mm")
            : dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
        if item.isBack {
            back.isHidden = false
            
        } else {
            back.isHidden = true
            stickTitle.text = item.desc
            desc.text = ""
            desc.isHidden = true
            skTitleBottm.constant = -25
            skTitleHeight.constant = 42
            let k = stickTitle.calculateMaxLines()
            if k == 1{
                skTitleBottm.constant = -25
                skTitleHeight.constant = 21
            }
        }
        
        let currTitle = item.title
        let titleDateString = currTitle.substring(fromIndex: currTitle.length - 19)
        df.dateFormat = "dd.MM.yyyy HH:mm:ss"
        if let titleDate = df.date(from: titleDateString) {
            df.dateFormat = "dd MMMM"
            df.locale = Locale(identifier: "Ru-ru")
            title.text = String(currTitle.dropLast(19)) + "на " + df.string(from: titleDate)
            
        } else {
            title.text = item.title
        }
    }
    
    class func fromNib() -> TestAppsUserCell? {
        var cell: TestAppsUserCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? TestAppsUserCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width ?? 0.0
        return cell
    }
}
private final class TestAppsUserHeaderData {
    
    let title:      String
    let id:         String
    
    init(title: String, id: String) {
        
        self.title      = title
        self.id         = id
    }
}
private final class AppsUserCellData {
    
    let icon:       UIImage
    let updateDate: String
    let type:       String
    let title:      String
    let desc:       String
    let status:     String
    let date:       String
    let id:         String
    let stickTitle: String
    let isBack:     Bool
    let isPaid:     String
    let webID:      String
    
    init(title: String, desc: String, icon: UIImage, status: String, date: String, isBack: Bool, type: String, id: String, updateDate: String, stickTitle: String, isPaid: String, webID: String) {
        
        self.updateDate = updateDate
        self.title      = title
        self.desc       = desc
        self.icon       = icon
        self.status     = status
        self.date       = date
        self.isBack     = isBack
        self.type       = type
        self.id         = id
        self.stickTitle = stickTitle
        self.isPaid     = isPaid
        self.webID      = webID
    }
}
