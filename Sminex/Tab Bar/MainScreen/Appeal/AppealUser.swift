//
//  AppealUser.swift
//  Sminex
//
//  Created by Sergey Ivanov on 22/07/2019.
//

import UIKit
import CoreData
import Gloss
import SwiftyXMLParser

protocol AppealUserDelegate: class {
    func update()
}

class AppealUser: UIViewController, UITableViewDelegate, UITableViewDataSource, AppealUserDelegate {
    
    @IBOutlet private weak var tableView:      UITableView!
    @IBOutlet private weak var activity:        UIActivityIndicatorView?
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    var typeName = ""
    private var dataType = [RequestTypeStruct]()
    func addRequestPressed() {
        
        startAnimator()
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.typeGroup.wait()
            if var types = TemporaryHolder.instance.requestTypes?.types {
                for i in 0...types.count - 1{
                    if types[i].name == "Обращение"{
                        self.typeName = types[i].name!
                    }
                }
                self.dataType = types
            }
            DispatchQueue.main.async {
                self.stopAnimatior()
                self.performSegue(withIdentifier: "addAppeal", sender: self)
            }
        }
    }
    
    public var requestId_ = ""
    public var isCreatingRequest_ = false
    public var typeReq = ""
    public var selEmail = ""
    public var delegate: MainScreenDelegate?
    public var xml_: XML.Accessor?
    public var isFromMain: Bool = false
    public var isFromNotifi_: Bool = false
    private var refreshControl: UIRefreshControl?
    var reqId = ""
    private var responceString = ""
    private let typeGroup      = DispatchGroup()
    var prepareGroup: DispatchGroup? = nil
    private var data: [AppealUserCellData] = []
    private var fullData: [AppealUserCellData] = []
    private var rowComms: [String : [RequestComment]]  = [:]
    private var rowPersons: [String : [RequestPerson]] = [:]
    private var rowAutos:   [String : [RequestAuto]]   = [:]
    private var rowFiles:   [RequestFile] = []
    var Appeal: AppealHeaderData?
    var techService: ServiceHeaderData?
    var AppealComm: [AppealCommentCellData] = []
    var techServiceComm: [ServiceCommentCellData] = []
    private var rows: [String:Request] = [:]
    var isHidNav = false
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        prepareGroup?.enter()
        isHidNav = isCreatingRequest_
        tableView?.delegate                     = self
        tableView?.dataSource                   = self
        automaticallyAdjustsScrollViewInsets    = false
        
        startAnimator()
        
        if TemporaryHolder.instance.requestTypes == nil {
            getRequestTypes()
        }
        
        if xml_ != nil && !isFromNotifi_{
            tableView?.alpha   = 0
            DispatchQueue.global(qos: .userInitiated).async {
                self.parse(xml: self.xml_!)
            }
            
        } else {
            
            DispatchQueue.main.async {
                self.getRequests()
            }
            
            if isCreatingRequest_ {
                addRequestPressed()
            }
            
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
            if #available(iOS 10.0, *) {
                tableView?.refreshControl = refreshControl
            } else {
                tableView?.addSubview(refreshControl!)
            }
        }
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            tableView?.refreshControl = refreshControl
        } else {
            tableView?.addSubview(refreshControl!)
        }
        title = "Обращения"
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
        isHidNav = false
        navigationController?.setNavigationBarHidden(false, animated: animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isHidNav {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }else{
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppealUserCell", for: indexPath) as! AppealUserCell
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
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // number of items to be fetched each time (i.e., database LIMIT)
    let itemsPerBatch = 19
    
    // Where to start fetching items (database OFFSET)
    var offset = 19
    var fullCount = 0
    // a flag for when all database items have already been loaded
    var reachedEndOfItems = false
    
    func loadMore() {
        
        // don't bother doing another db query if already have everything
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
            var thisBatchOfItems: [AppealUserCellData] = []
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
                    
                    // append the new items to the data source for the table view
                    self.data += thisBatchOfItems
                    // reload the table view
                    self.tableView?.reloadData()
                    self.stopAnimatior()
                    if #available(iOS 10.0, *) {
                        self.tableView?.refreshControl?.endRefreshing()
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
//            print(self.responceString)
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
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass + "&appealsOnly=1")!)
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
            
            var newData: [AppealUserCellData] = []
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
                var name = "Обращение"
                if (curr.responsiblePerson?.contains("онсьерж"))! || (curr.name?.contains("онсьерж"))!{
                    name                = "Обращение к консьержу"
                } else if (curr.responsiblePerson?.contains("поддержк"))! || (curr.name?.contains("поддержк"))!{
                    name                = "Обращение в техподдержку"
                } else if (curr.responsiblePerson?.contains("иректор"))! || (curr.name?.contains("иректор"))! || (curr.responsiblePerson?.containsIgnoringCase(find: "предложения"))! || (curr.name?.containsIgnoringCase(find: "предложения"))!{
                    name                = " Обращение к директору службы комфорта"
                }
                newData.append( AppealUserCellData(title: name,
                                                 desc: (self.rowComms[curr.id!]?.count == 0 || lastComm == nil) ? descText : lastComm?.text ?? "",
                                                 icon: icon,
                                                 status: curr.status ?? "",
                                                 date: curr.updateDate ?? "",
                                                 isBack: isAnswered,
                                                 type: curr.idType ?? "",
                                                 id: curr.id ?? "", webId: curr.webID ?? "",
                                                 updateDate: (curr.updateDate == "" ? curr.dateFrom : curr.updateDate) ?? "",
                                                 stickTitle: isAnswered ? descText : "", isPaid: curr.isPaid ?? "", respPerson: curr.responsiblePerson ?? ""))
                
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
                if firstArr.count != 0{
                    self.fullData = firstArr
                    self.fullCount = self.fullData.count
                    self.data.removeAll()
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
                }
                
                self.tableView?.reloadData()
                
                if self.requestId_ != "" {
                    print(self.requestId_)
                    for (index, item) in self.data.enumerated() {
                        if item.id == self.requestId_ || item.webId == self.requestId_{
                            if self.tableView != nil {
                                self.tableView(self.tableView, didSelectRowAt: IndexPath(row: index, section: 0))
                                
                            } else {
                                self.prepareTapped(IndexPath(row: index, section: 0))
                            }
                        }
                    }
                    
                } else {
                    self.stopAnimatior()
                    if #available(iOS 10.0, *) {
                        self.tableView?.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
                    }
                }
            }
        }
    }
    
    func prepareTapped(_ indexPath: IndexPath) {
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.typeGroup.wait()
            
            DispatchQueue.main.async {
                self.stopAnimatior()
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
                self.rowAutos[row.id!]?.forEach {
                    if $0.number != "" && $0.number != nil {
                        auto = auto + ($0.number ?? "")
                    }
                    if $0.number != self.rowAutos[row.id!]?.last?.number {
                        auto = auto + ", "
                    }
                }
                
                var images: [String] = []
                var name = ""
                if (row.responsiblePerson?.contains("онсьерж"))! || (row.name?.contains("онсьерж"))!{
                    name                = "Консьержу"
                } else if (row.responsiblePerson?.contains("поддержк"))! || (row.name?.contains("поддержк"))!{
                    name                = "в Техподдержку"
                } else if (row.responsiblePerson?.contains("иректор"))! || (row.name?.contains("иректор"))!{
                    name                = "Директору службы комфорта"
                }
                self.AppealComm = []
                self.rowComms[row.id!]!.forEach { comm in
                    
                    var commImg: String?
                    
                    self.rowFiles.forEach {
                        
                        if $0.fileId == comm.idFile {
                            commImg = $0.fileId
                        }
                    }
                    if !(comm.text?.containsIgnoringCase(find: "+skip"))!{
                        self.AppealComm.append ( AppealCommentCellData(image: UIImage(named: "account")!,
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
                self.Appeal = AppealHeaderData(title: name, mobileNumber: row.phoneNum ?? "", ident: row.ident ?? "", email: row.emails ?? "", desc: row.text!, imagesUrl: images)
                self.reqId = row.id ?? ""
                if self.tableView != nil {
                    self.performSegue(withIdentifier: "showAppeal", sender: self)
                }
                self.prepareGroup?.leave()
                
            }
        }
    }
    
    private func startAnimator() {
        activity?.isHidden       = false
        activity?.startAnimating()
    }
    
    private func stopAnimatior() {
        activity?.stopAnimating()
        activity?.isHidden       = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showAppeal" {
            let vc = segue.destination as! AppealVC
            vc.data_ = Appeal!
            vc.comments_ = AppealComm
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
            
        } else if segue.identifier == "addAppeal"{
            let vc = segue.destination as! CreateAppeal
            vc.delegate = self
            vc.typeReq = typeReq
            vc.selEmail = selEmail
            vc.name_ = typeName
            for i in 0...dataType.count - 1{
                if dataType[i].name == "Обращение"{
                    vc.type_ = dataType[i]
                }
            }
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
        DispatchQueue.main.async {
            self.delegate?.update(method: "Request")
            self.getRequests()
        }
    }
}

final class AppealUserCell: UITableViewCell {
    
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
    
    fileprivate func display(_ item: AppealUserCellData) {
        desc.isHidden = false
        if item.desc.contains(find: "Отправлен новый файл:") || item.desc.contains(find: "Прикреплён файл"){
            desc.text = "Добавлен файл"
        }else{
            //            let mySubstring = item.desc.prefix(30)
            desc.text   = item.desc
        }
        icon.image      = item.icon
        status.text     = item.status.uppercased()
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
    
//    class func fromNib() -> AppealUserCell? {
//        var cell: AppealUserCell?
//        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
//        views?.forEach {
//            if let view = $0 as? AppealUserCell {
//                cell = view
//            }
//        }
//        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
//        cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width ?? 0.0
//        return cell
//    }
}

private final class AppealUserCellData {
    
    let icon:       UIImage
    let updateDate: String
    let type:       String
    let title:      String
    let desc:       String
    let status:     String
    let date:       String
    let id:         String
    let webId:      String
    let stickTitle: String
    let isBack:     Bool
    let isPaid:     String
    let respPerson: String
    
    init(title: String, desc: String, icon: UIImage, status: String, date: String, isBack: Bool, type: String, id: String, webId: String, updateDate: String, stickTitle: String, isPaid: String, respPerson: String) {
        
        self.updateDate = updateDate
        self.title      = title
        self.desc       = desc
        self.icon       = icon
        self.status     = status
        self.date       = date
        self.isBack     = isBack
        self.type       = type
        self.id         = id
        self.webId       = webId
        self.stickTitle = stickTitle
        self.isPaid     = isPaid
        self.respPerson = respPerson
    }
}
