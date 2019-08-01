//
//  NewAppsUser.swift
//  Sminex
//
//  Created by Sergey Ivanov on 01/08/2019.
//

import UIKit
import CoreData
import Gloss
import SwiftyXMLParser

final class NewAppsUser: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AppsUserDelegate {
    
    @IBOutlet         weak var collection:      UICollectionView?
    @IBOutlet         weak var collectionHeader:UICollectionView?
    @IBOutlet private weak var createButton:    UIButton?
    @IBOutlet private weak var activity:        UIActivityIndicatorView?
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func addRequestPressed(_ sender: UIButton?) {
        
        startAnimator()
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        prepareGroup?.enter()
        
        collection?.delegate                     = self
        collection?.dataSource                   = self
        collectionHeader?.delegate               = self
        collectionHeader?.dataSource             = self
        automaticallyAdjustsScrollViewInsets     = false
        
        startAnimator()
        if TemporaryHolder.instance.requestTypes == nil {
            getRequestTypes()
        }
        if xml_ != nil {
            collection?.alpha   = 0
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
                collection?.refreshControl = refreshControl
            } else {
                collection?.addSubview(refreshControl!)
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cell = AppsUserCell.fromNib()
        cell?.display(data[indexPath.row])
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppsUserCell", for: indexPath) as! AppsUserCell
        cell.display(data[indexPath.row])
        if indexPath.row == self.data.count - 1 {
            self.loadMore()
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        startAnimator()
        prepareTapped(indexPath)
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
                    
                    // append the new items to the data source for the table view
                    self.data += thisBatchOfItems
                    // reload the table view
                    self.collection?.reloadData()
                    self.stopAnimatior()
                    if #available(iOS 10.0, *) {
                        self.collection?.refreshControl?.endRefreshing()
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
            //            print(request)
            
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
                //                    print(String(data: data!, encoding: .utf8)!)
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
                if lastComm != nil && (lastComm?.text?.contains(find: "Отправлен новый файл:"))! && v != 0 && v <= 10{
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
                                                     stickTitle: isAnswered ? name! : "", isPaid: curr.isPaid!))
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
                                                     stickTitle: isAnswered ? descText : "", isPaid: curr.isPaid ?? ""))
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
                
                self.collection?.reloadData()
                
                if self.requestId_ != "" {
                    for (index, item) in self.data.enumerated() {
                        if item.id == self.requestId_ {
                            if self.collection != nil {
                                self.collectionView(self.collection!, didSelectItemAt: IndexPath(row: index, section: 0))
                                
                            } else {
                                self.prepareTapped(IndexPath(row: index, section: 0))
                            }
                        }
                    }
                    
                } else {
                    self.stopAnimatior()
                    if #available(iOS 10.0, *) {
                        self.collection?.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
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
                var itsNever: Bool = false
                print(type)
                TemporaryHolder.instance.requestTypes?.types?.forEach {
                    if $0.id == type {
                        type = $0.name ?? ""
                        itsNever = true
                    }
                    
                }
                print(TemporaryHolder.instance.requestTypes?.types)
                print(type)
                //                if (!itsNever) {
                //                    type = "Гостевой пропуск"
                //                }
                
                if type.contains(find: "ропуск") {
                    self.typeName = type
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
                    self.rowFiles.forEach {
                        if self.dateTeck($0.dateTime!) == self.dateTeck(row.dateFrom!) {
                            images.append($0.fileId!)
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
                    self.admissionComm = []
                    //                    if row.text != ""{
                    //                        self.admissionComm.append ( AdmissionCommentCellData(image: UIImage(named: "account")!,
                    //                                                                             title: "Примечание",
                    //                                                                             comment: row.text ?? "",
                    //                                                                             date: row.added ?? "",
                    //                                                                             commImg: nil,
                    //                                                                             commImgUrl: nil,
                    //                                                                             id: "-1") )
                    //                    }
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if $0.fileId == comm.idFile {
                                commImg = $0.fileId
                            }
                        }
                        
                        self.admissionComm.append ( AdmissionCommentCellData(image: UIImage(named: "account")!,
                                                                             title: comm.name ?? "",
                                                                             comment: comm.text ?? "",
                                                                             date: comm.createdDate ?? "",
                                                                             commImg: nil,
                                                                             commImgUrl: commImg,
                                                                             id: comm.id ?? "") )
                    }
                    
                    self.reqId = row.id ?? ""
                    if self.collection != nil {
                        self.performSegue(withIdentifier: Segues.fromAppsUser.toAdmission, sender: self)
                    }
                    self.prepareGroup?.leave()
                    
                } else if self.data[indexPath.row].title.containsIgnoringCase(find: "услуг"){
                    let row = self.rows[self.data[indexPath.row].id]!
                    var images: [String] = []
                    
                    self.rowFiles.forEach {
                        
                        if self.dateTeck($0.dateTime!) == self.dateTeck(row.dateFrom!) {
                            images.append($0.fileId!)
                        }
                    }
                    var dataServ: ServicesUKJson!
                    self.dataService.forEach{
                        if $0.name == self.data[indexPath.row].desc{
                            dataServ = $0
                        }
                    }
                    print(dataServ)
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
                    self.serviceUK = ServiceAppHeaderData(icon: UIImage(named: "account")!, price: dataServ.cost ?? "", mobileNumber: row.phoneNum ?? "", servDesc: serviceDesc, email: row.emails ?? "", date: (row.dateTo != "" ? row.dateTo : row.planDate) ?? "", status: row.status ?? "", images: [], imagesUrl: images, desc: row.comment ?? "", placeHome: row.premises!, soonPossible: row.soonPossible, title: dataServ.name ?? "", servIcon: imageIcon)
                    
                    self.techServiceComm = []
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if $0.fileId == comm.idFile {
                                commImg = $0.fileId!
                            }
                        }
                        
                        self.serviceUKComm.append( ServiceAppCommentCellData(image: UIImage(named: "account")!,
                                                                             title: comm.name ?? "",
                                                                             comment: comm.text ?? "",
                                                                             date: comm.createdDate ?? "",
                                                                             commImg: nil,
                                                                             commImgUrl: commImg,
                                                                             id: comm.id ?? ""))
                    }
                    self.reqId = row.id ?? ""
                    if self.collection != nil {
                        self.performSegue(withIdentifier: Segues.fromAppsUser.toServiceUK, sender: self)
                    }
                    self.prepareGroup?.leave()
                    
                } else {
                    let row = self.rows[self.data[indexPath.row].id]!
                    var images: [String] = []
                    
                    self.rowFiles.forEach {
                        
                        if self.dateTeck($0.dateTime!) == self.dateTeck(row.dateFrom!) {
                            images.append($0.fileId!)
                        }
                    }
                    
                    self.techService = ServiceHeaderData(icon: self.data[indexPath.row].icon,
                                                         problem: row.text ?? "",
                                                         date: (row.dateTo != "" ? row.dateTo : row.planDate) ?? "",
                                                         status: row.status ?? "",
                                                         images: [],
                                                         imagesUrl: images, isPaid: row.isPaid ?? "", placeHome: row.premises ?? "", soonPossible: row.soonPossible)
                    
                    self.techServiceComm = []
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if $0.fileId == comm.idFile {
                                commImg = $0.fileId!
                            }
                        }
                        
                        self.techServiceComm.append( ServiceCommentCellData(icon: UIImage(named: "account")!,
                                                                            title: comm.name ?? "",
                                                                            desc: comm.text ?? "",
                                                                            date: comm.createdDate ?? "",
                                                                            image: nil,
                                                                            imageUrl: commImg,
                                                                            id: comm.id ?? ""))
                    }
                    self.reqId = row.id ?? ""
                    if self.collection != nil {
                        self.performSegue(withIdentifier: Segues.fromAppsUser.toService, sender: self)
                    }
                    self.prepareGroup?.leave()
                    
                }
            }
        }
    }
    
    private func startAnimator() {
        
        activity?.isHidden       = false
        createButton?.isHidden   = true
        
        activity?.startAnimating()
    }
    
    private func stopAnimatior() {
        
        activity?.stopAnimating()
        
        activity?.isHidden       = true
        createButton?.isHidden   = false
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
                vc.isFromMain_ = true
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
            vc.data_ = serviceUK!
            vc.reqId_ = reqId
            vc.delegate = self
        } else if segue.identifier == Segues.fromAppsUser.toService {
            let vc = segue.destination as! TechServiceVC
            vc.data_ = techService!
            vc.comments_ = techServiceComm
            vc.reqId_ = reqId
            vc.delegate = self
            if self.requestId_ != "" {
                self.requestId_ = ""
                self.xml_ = nil
                vc.isFromMain_ = true
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
        self.createButton?.isHidden = true
        DispatchQueue.main.async {
            self.delegate?.update(method: "Request")
            self.getRequests()
        }
    }
}

private final class AppsUserCell: UICollectionViewCell {
    
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
        if item.desc.contains(find: "Отправлен новый файл:"){
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
            skTitleBottm.constant = 8
            skTitleHeight.constant = 30
            stickTitle.text = item.stickTitle
            let k = stickTitle.calculateMaxLines()
            if k == 1{
                skTitleBottm.constant = 8
                skTitleHeight.constant = 15
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
    
    class func fromNib() -> AppsUserCell? {
        var cell: AppsUserCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AppsUserCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width ?? 0.0
        return cell
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
    
    init(title: String, desc: String, icon: UIImage, status: String, date: String, isBack: Bool, type: String, id: String, updateDate: String, stickTitle: String, isPaid: String) {
        
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
    }
}
