//
//  AppsUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData
import Gloss
import SwiftyXMLParser

protocol AppsUserDelegate: class {
    func update()
}

final class AppsUser: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AppsUserDelegate {
    
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var createButton:    UIButton!
    @IBOutlet private weak var activity:        UIActivityIndicatorView!
    
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
    
    open var isCreatingRequest_ = false
    open var delegate: MainScreenDelegate?
    
    private var refreshControl: UIRefreshControl?
    private var typeName = ""
    private var reqId = ""
    private var responceString = ""
    private let typeGroup      = DispatchGroup()
    private var data: [AppsUserCellData] = []
    private var rowComms: [String : [RequestComment]]  = [:]
    private var rowPersons: [String : [RequestPerson]] = [:]
    private var rowAutos:   [String : [RequestAuto]]   = [:]
    private var rowFiles:   [RequestFile] = []
    private var admission: AdmissionHeaderData?
    private var techService: ServiceHeaderData?
    private var admissionComm: [AdmissionCommentCellData] = []
    private var techServiceComm: [ServiceCommentCellData] = []
    private var rows: [Request] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collection.delegate                     = self
        collection.dataSource                   = self
        automaticallyAdjustsScrollViewInsets    = false
        
        startAnimator()
        if TemporaryHolder.instance.requestTypes == nil {
            getRequestTypes()
        }
        
        getRequests()
        
        if isCreatingRequest_ {
            addRequestPressed(nil)
        }
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        DispatchQueue.main.async {
            self.getRequests()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        startAnimator()
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            self.typeGroup.wait()
            
            DispatchQueue.main.async {
                self.stopAnimatior()
                
                let type = self.data[indexPath.row].type
                
                if type.contains(find: "ропуск") {
                    
                    self.typeName = type
                    let row = self.rows[indexPath.row]
                    var persons = ""
                    var auto = ""
                    self.rowPersons[row.id!]?.forEach {
                        
                        if $0.fio != "" && $0.fio != nil {
                            persons = persons + ", " + ($0.fio ?? "")
                        }
                    }
                    self.rowAutos[row.id!]?.forEach {
                        
                        if $0.number != "" && $0.number != nil {
                            auto = auto + ($0.number ?? "")
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
                                                         mobileNumber: row.phoneNum!,
                                                         gosNumber: auto,
                                                         date: row.planDate!,
                                                         status: row.status!,
                                                         images: [],
                                                         imagesUrl: images)
                    self.admissionComm = []
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if self.dateTeck($0.dateTime!) == self.dateTeck(comm.createdDate!) {
                                commImg = $0.fileId
                            }
                        }
                        
                        self.admissionComm.append ( AdmissionCommentCellData(image: UIImage(named: "account")!,
                                                                             title: comm.name!,
                                                                             comment: comm.text!,
                                                                             date: comm.createdDate!,
                                                                             commImg: nil,
                                                                             commImgUrl: commImg) )
                    }
                    
                    self.reqId = row.id ?? ""
                    self.performSegue(withIdentifier: Segues.fromAppsUser.toAdmission, sender: self)
                    
                    
                } else if type.contains(find: "Техническое обслуживание") {
                    
                    let row = self.rows[indexPath.row]
                    
                    var images: [String] = []
                    
                    self.rowFiles.forEach {
                        
                        if self.dateTeck($0.dateTime!) == self.dateTeck(row.dateFrom!) {
                            images.append($0.fileId!)
                        }
                    }
                    
                    self.techService = ServiceHeaderData(icon: self.data[indexPath.row].icon,
                                                         problem: row.text!,
                                                         date: row.planDate!,
                                                         status: row.status!,
                                                         images: [],
                                                         imagesUrl: images)
                    
                    self.techServiceComm = []
                    self.rowComms[row.id!]!.forEach { comm in
                        
                        var commImg: String?
                        
                        self.rowFiles.forEach {
                            
                            if self.dateTeck($0.dateTime!) == self.dateTeck(comm.createdDate!) {
                                commImg = $0.fileId!
                            }
                        }
                        
                        self.techServiceComm.append( ServiceCommentCellData(icon: UIImage(named: "account")!,
                                                                       title: comm.name!,
                                                                       desc: comm.text!,
                                                                       date: comm.createdDate!,
                                                                       image: nil,
                                                                       imageUrl: commImg))
                    }
                    
                    self.reqId = row.id ?? ""
                    self.performSegue(withIdentifier: Segues.fromAppsUser.toService, sender: self)
                    
                }
            }
        }
    }
    
    private func getRequestTypes() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REQUEST_TYPE + "accountid=" + id)!)
        request.httpMethod = "GET"
        
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
                print(self.responceString)
            #endif
            
            DispatchQueue.main.sync {
                
                if self.responceString.contains(find: "error") {
                    let alert = UIAlertController(title: "Ошибка сервера", message: self.responceString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                    self.present(alert, animated: true, completion: nil)
                    
                } else {
                    TemporaryHolder.instance.choise(try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)
                }
            }
            }.resume()
    }
    
    @discardableResult
    func getRequests(isBackground: Bool = false) -> [RequestCellData] {
        
        var returnArr: [RequestCellData] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
        
            let login = UserDefaults.standard.string(forKey: "login")!
            let pass  = getHash(pass: UserDefaults.standard.string(forKey: "pass")!, salt: self.getSalt(login: login))
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    group.leave()
                }
                guard data != nil else { return }
                
                #if DEBUG
                    print(String(data: data!, encoding: .utf8)!)
                #endif
                
                let xml = XML.parse(data!)
                let requests = xml["Requests"]
                
                let row = requests["Row"]
                self.rows = []
                
                row.forEach { row in
                    
                    self.rows.append(Request(row: row))
                    self.rowComms[row.attributes["ID"]!] = []
                    self.rowPersons[row.attributes["ID"]!] = []
                    self.rowAutos[row.attributes["ID"]!] = []
                    
                    row["Comm"].forEach {
                        self.rowComms[row.attributes["ID"]!]?.append( RequestComment(row: $0) )
                    }
                    
                    row["Persons"].forEach {
                        self.rowPersons[row.attributes["ID"]!]?.append( RequestPerson(row: $0)  )
                    }
                    
                    row["Autos"].forEach {
                        self.rowAutos[row.attributes["ID"]!]?.append( RequestAuto(row: $0) )
                    }
                    
                    row["File"].forEach {
                        self.rowFiles.append( RequestFile(row: $0) )
                    }
                }
                
                let db = DB()
                if !isBackground {
                db.deleteRequests()
                }
                
                var newData: [AppsUserCellData] = []
                self.rows.forEach { curr in
                   
                    let isAnswered = (self.rowComms[curr.id!]?.count ?? 0) <= 0 ? false : true
                    
                    var date = curr.planDate!
                    if date.count > 9 {
                        date.removeLast(9)
                    }
                    
                    let lastComm = (self.rowComms[curr.id!]?.count ?? 0) <= 0 ? nil : self.rowComms[curr.id!]?[(self.rowComms[curr.id!]?.count)! - 1]
                    let icon = !(curr.status?.contains(find: "Отправлена"))! ? UIImage(named: "check_label")! : UIImage(named: "processing_label")!
                    let isPerson = curr.name?.contains(find: "ропуск") ?? false
                    
                    var persons = ""
                    if isPerson {
                        self.rowPersons[curr.id!]?.forEach {
                            
                            if $0.fio != "" && $0.fio != nil {
                                persons = persons + ", " + ($0.fio ?? "")
                            }
                        }
                    }
                    let descText = isPerson ? (persons == "" ? "Не указано" : persons) : curr.text ?? ""
                    newData.append( AppsUserCellData(title: curr.name ?? "",
                                                     desc: self.rowComms[curr.id!]?.count == 0 ? descText : lastComm?.text ?? "",
                                                     icon: icon,
                                                     status: curr.status ?? "",
                                                     date: date,
                                                     isBack: isAnswered,
                                                     type: curr.name ?? "")  )
                    if !isBackground {
                        DispatchQueue.main.sync {
                            db.setRequests(title: curr.name ?? "",
                                           desc: self.rowComms[curr.id!]?.count == 0 ? descText : lastComm?.text ?? "",
                                           icon: icon,
                                           date: date,
                                           status: curr.status ?? "",
                                           isBack: isAnswered)
                        }
                    } else {
                        returnArr.append( RequestCellData(title: curr.name ?? "",
                                                          desc: self.rowComms[curr.id!]?.count == 0 ? descText : lastComm?.text ?? "",
                                                          icon: icon,
                                                          date: date,
                                                          status: curr.status ?? "",
                                                          isBack: isAnswered) )
                    }
                }
                
                DispatchQueue.main.sync {
                    self.data = newData
                    if !isBackground {
                        self.collection.reloadData()
                        if #available(iOS 10.0, *) {
                            self.collection.refreshControl?.endRefreshing()
                        } else {
                            self.refreshControl?.endRefreshing()
                        }
                        self.stopAnimatior()
                    }
                }
                }.resume()
        }
        if isBackground {
            group.wait()
        }
        var ret: [RequestCellData] = []
        
        if returnArr.count != 0 {
            ret.append(returnArr.popLast()!)
        }
        if returnArr.count != 0 {
            ret.append(returnArr.popLast()!)
        }
        return ret
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        request.httpMethod = "GET"
        
        queue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            defer {
                queue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            
            #if DEBUG
                print("salt is = \(String(describing: String(data: data!, encoding: .utf8)))")
            #endif
            
            }.resume()
        
        queue.wait()
        return salt ?? Data()
    }
    
    private func startAnimator() {
        
        activity.isHidden       = false
        createButton.isHidden   = true
        
        activity.startAnimating()
    }
    
    private func stopAnimatior() {
        
        activity.stopAnimating()
        
        activity.isHidden       = true
        createButton.isHidden   = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromAppsUser.toAdmission {
            let vc = segue.destination as! AdmissionVC
            vc.data_ = admission!
            vc.comments_ = admissionComm
            vc.reqId_ = reqId
            vc.delegate = self
            vc.name_ = typeName
        
        } else if segue.identifier == Segues.fromAppsUser.toService {
            let vc = segue.destination as! TechServiceVC
            vc.data_ = techService!
            vc.comments_ = techServiceComm
            vc.reqId_ = reqId
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromAppsUser.toRequestType {
            let vc = segue.destination as! RequestTypeVC
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
        delegate?.update()
        getRequests()
    }
}


final class AppsUserCell: UICollectionViewCell {
    
    @IBOutlet private weak var icon:    UIImageView!
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var status:  UILabel!
    @IBOutlet private weak var date:    UILabel!
    @IBOutlet private weak var back:    UIView!
    
    private var type: String?
    
    fileprivate func display(_ item: AppsUserCellData) {
        
        desc.text       = item.desc
        icon.image      = item.icon
        status.text     = item.status
        back.isHidden   = !item.isBack
        type            = item.type
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "") : dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM")
        
        if item.isBack {
            back.isHidden = false
            
        } else {
            back.isHidden = true
        }
        
        let currTitle = item.title
        let titleDateString = currTitle.substring(fromIndex: currTitle.length - 19)
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy hh:mm:ss"
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
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 25
        cell?.desc.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 0.0) - 25
        return cell
    }
}

private final class AppsUserCellData {
    
    let type:   String
    let title:  String
    let desc:   String
    let icon:   UIImage
    let status: String
    let date:   String
    let isBack: Bool
    
    init(title: String, desc: String, icon: UIImage, status: String, date: String, isBack: Bool, type: String) {
        
        self.title  = title
        self.desc   = desc
        self.icon   = icon
        self.status = status
        self.date   = date
        self.isBack = isBack
        self.type   = type
    }
}

struct Request {
    
    let isWait:                 String?
    let isReadedByClient:   	String?
    let cusName:            	String?
    let idWorktype:         	String?
    let siteUrl: 	        	String?
    let isLauncher: 	        String?
    let IsPotentialClient:      String?
    let ident: 	                String?
    let isPerformed:            String?
    let responsiblePerson:      String?
    let phoneNum:               String?
    let id:                     String?
    let status:                 String?
    let text:                   String?
    let dateServiceDesired:     String?
    let isReaded:               String?
    let addressStreet:          String?
    let emergencyRequestType:   String?
    let isCorrected:            String?
    let isNeedNotify:           String?
    let adressFlat:             String?
    let isBlockPerform: 	    String?
    let addressCorps:           String?
    let dateTo: 	            String?
    let added: 	                String?
    let idConsultant: 	        String?
    let dateFrom: 	            String?
    let addressHome: 	        String?
    let housesAddress: 	        String?
    let isCons: 	            String?
    let isAnswered: 	        String?
    let idPriority: 	        String?
    let idType: 	            String?
    let isRegister: 	        String?
    let isActive: 	            String?
    let emails: 	            String?
    let isCallCenter:           String?
    let guid: 	                String?
    let idAuthor:               String?
    let isPay: 	                String?
    let idHouseProfile: 	    String?
    let isProcessing:           String?
    let onlyForConsultant: 	    String?
    let name:                   String?
    let clearAfterWork: 	    String?
    let idDepartment:           String?
    let comment: 	            String?
    let idStatus: 	            String?
    let paymentAmount:          String?
    let isLowMark:              String?
    let planDate:               String?
    let ipAddr: 	            String?
    let callUniqueID: 	        String?
    let flatNumber: 	        String?
    
    init(row: XML.Accessor) {
        isWait                  = row.attributes["isWait"]
        isReadedByClient        = row.attributes["isReadedByClient"]
        cusName                 = row.attributes["cusName"]
        idWorktype              = row.attributes["id_worktype"]
        siteUrl                 = row.attributes["SiteURL"]
        isLauncher              = row.attributes["isLauncher"]
        IsPotentialClient       = row.attributes["IsPotentialClient"]
        ident                   = row.attributes["ident"]
        isPerformed             = row.attributes["isPerformed"]
        responsiblePerson       = row.attributes["ResponsiblePerson"]
        phoneNum                = row.attributes["PhoneNum"]
        id                      = row.attributes["ID"]
        status                  = row.attributes["Status"]
        text                    = row.attributes["text"]
        dateServiceDesired      = row.attributes["DateServiceDesired"]
        isReaded                = row.attributes["IsReaded"]
        addressStreet           = row.attributes["AddressStreet"]
        emergencyRequestType    = row.attributes["EmergencyRequestType"]
        isCorrected             = row.attributes["IsCorrected"]
        isNeedNotify            = row.attributes["IsNeedNotify"]
        adressFlat              = row.attributes["AddressFlat"]
        isBlockPerform          = row.attributes["IsBlockPerform"]
        addressCorps            = row.attributes["AddressCorps"]
        dateTo                  = row.attributes["DateTo"]
        added                   = row.attributes["added"]
        idConsultant            = row.attributes["id_Consultant"]
        dateFrom                = row.attributes["DateFrom"]
        addressHome             = row.attributes["AddressHome"]
        housesAddress           = row.attributes["HouseAddress"]
        isCons                  = row.attributes["isCons"]
        isAnswered              = row.attributes["IsAnswered"]
        idPriority              = row.attributes["id_priority"]
        idType                  = row.attributes["id_type"]
        isRegister              = row.attributes["IsRegister"]
        isActive                = row.attributes["isActive"]
        emails                  = row.attributes["Emails"]
        isCallCenter            = row.attributes["IsCallCenter"]
        guid                    = row.attributes["GUID"]
        idAuthor                = row.attributes["id_Author"]
        isPay                   = row.attributes["IsPay"]
        idHouseProfile          = row.attributes["id_HouseProfile"]
        isProcessing            = row.attributes["IsProcessing"]
        onlyForConsultant       = row.attributes["onlyForConsultant"]
        name                    = row.attributes["name"]
        clearAfterWork          = row.attributes["ClearAfterWork"]
        idDepartment            = row.attributes["id_department"]
        comment                 = row.attributes["Comment"]
        idStatus                = row.attributes["id_status"]
        paymentAmount           = row.attributes["PaymentAmount"]
        isLowMark               = row.attributes["IsLowMark"]
        planDate                = row.attributes["PlanDate"]
        ipAddr                  = row.attributes["ip_addr"]
        callUniqueID            = row.attributes["CallUniqueID"]
        flatNumber              = row.attributes["FlatNumber"]
    }
}

struct RequestPerson {
    
    let id:             String?
    let fio:            String?
    let passportData:   String?
    
    init(row: XML.Accessor) {
        
        id = row.attributes["ID"]
        fio = row.attributes["FIO"]
        passportData = row.attributes["PassportData"]
    }
}

struct RequestAuto {
    
    let id:         String?
    let mark:       String?
    let color:      String?
    let number:     String?
    let parking:    String?
    
    init(row: XML.Accessor) {
        
        id      = row.attributes["ID"]
        mark    = row.attributes["Mark"]
        color   = row.attributes["Color"]
        number  = row.attributes["Number"]
        parking = row.attributes["Parking"]
    }
}

struct RequestComment {
    
    let id:     		String?
    let idFile:     	String?
    let idAuthor:       String?
    let text:       	String?
    let name:   	    String?
    let isHidden:       String?
    let createdDate:    String?
    let idRequest:      String?
    let phoneNum:       String?
    
    init(row: XML.Accessor) {
        
        id          = row.attributes["ID"]
        idFile      = row.attributes["id_file"]
        idAuthor    = row.attributes["id_Author"]
        text        = row.attributes["text"]
        name        = row.attributes["Name"]
        isHidden    = row.attributes["isHidden"]
        createdDate = row.attributes["CreatedDate"]
        idRequest   = row.attributes["id_request"]
        phoneNum    = row.attributes["PhoneNum"]
    }
}

struct RequestFile {
    
    let fileId:     String?
    let fileName:   String?
    let dateTime:   String?
    let userName:   String?
    let isCons:     String?
    let isCurrUsr:  String?
    let userId:     String?
    
    init(row: XML.Accessor) {
        
        fileId      = row.attributes["FileID"]
        fileName    = row.attributes["FileName"]
        dateTime    = row.attributes["DateTime"]
        userName    = row.attributes["UserName"]
        isCons      = row.attributes["IsConsultant"]
        isCurrUsr   = row.attributes["IsCurrentUser"]
        userId      = row.attributes["UserID"]
    }
}







