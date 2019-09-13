//
//  TechServiceVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/24/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyXMLParser
import DeviceKit

private protocol TechServiceProtocol: class { }
private protocol TechServiceCellsProtocol: class {
    func imagePressed(_ sender: UITapGestureRecognizer)
}

final class TechServiceVC: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TechServiceCellsProtocol {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var commentField:    UITextField!
    @IBOutlet private weak var sendBtn:         UIButton!
    @IBOutlet private weak var cameraButton:    UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        imgs = [:]
        if isCreate_{
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 4], animated: true)
        
        } else if isFromNotifi_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 2], animated: true)
            
        } else if isFromMain_ {
            navigationController?.popToRootViewController(animated: true)
        
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton?) {
        
        if img == nil {
            if commentField.text == ""
                || commentField.text == nil {
                commentField.placeholder = "Введите сообщение!"
                return
            }
        }
        
        startAnimator()
        if img != nil && commentField.text != "" {
            uploadPhoto(img!, isSplit: true)
            return
            
        } else if img == nil && commentField.text != "" {
            sendComment()
            return
        } else if img != nil && commentField.text == "" {
            uploadPhoto(img!)
            return
        }
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Сделать фото", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        
        if let popoverController = action.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    public var delegate:   AppsUserDelegate?
    public var reqId_      = ""
    public var isCreate_   = false
    public var isFromMain_ = false
    public var isFromNotifi_ = false
    public var data_: ServiceHeaderData = ServiceHeaderData(icon: UIImage(named: "account")!,
                                                          problem: "Нас топят соседи! Не можем с ними связаться. Срочно вызвайте сантехника",
                                                          date: "9 сентября 10:00",
                                                          status: "В ОБРАБОТКЕ",
                                                          images: [UIImage(named: "account")!, UIImage(named: "account")!, UIImage(named: "account")!], isPaid: "0", placeHome: "", soonPossible: false, isReaded: "")
    
    public var comments_: [ServiceCommentCellData] = []
    private var arr:    [TechServiceProtocol]    = []
    private var img:    UIImage?
    
    private var rowComms: [String : [RequestComment]]  = [:]
    private var rowFiles:   [RequestFile] = []
    
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        if data_.isPaid == "1"{
            self.navigationItem.title = "Заявка на услугу"
        }
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
//        if data_.images.count > 0{
//            data_.images.forEach{
//                comments_.append(ServiceCommentCellData(icon: UIImage(named: "account")!, title: UserDefaults.standard.string(forKey: "name") ?? "", desc: "", date: data_.date, image: $0, imageUrl: nil, id: "-1"))
//                print($0.accessibilityIdentifier)
//            }
//        }
        arr = comments_
        arr.insert(data_, at: 0)
        
        commentField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: commentField.frame.height))
        commentField.rightViewMode = .always
        commentField.autocorrectionType = .no
        collection.delegate     = self
        collection.dataSource   = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        collection.reloadData()
        self.view.isUserInteractionEnabled = true
        if #available(iOS 10.0, *) {
            self.collection.refreshControl?.endRefreshing()
        } else {
            self.refreshControl?.endRefreshing()
        }
        print(data_.isReaded)
        if data_.isReaded == "0"{
            sendRead()
        }
    }
    
    private func sendRead() {
        let idGroup = reqId_.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + "SetRequestReadedState.ashx?" + "id=" + idGroup)!)
        request.httpMethod = "GET"
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                let alert = UIAlertController(title: "Ошбика сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            #if DEBUG
            print(String(data: data!, encoding: .utf8)!)
            
            #endif
            TemporaryHolder.instance.menuRequests = TemporaryHolder.instance.menuRequests - 1
            }.resume()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        collection.reloadData()
        self.view.isUserInteractionEnabled = true
        if #available(iOS 10.0, *) {
            self.collection.refreshControl?.endRefreshing()
        } else {
            self.refreshControl?.endRefreshing()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        tabBarController?.tabBar.isHidden = false
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.global(qos: .background).async {
                sleep(2)
                DispatchQueue.main.async {
                    self.view.isUserInteractionEnabled = false
                }
                // Получим комментарии по одной заявке
                let defaults = UserDefaults.standard
                let login = defaults.string(forKey: "login")
//                let pass = defaults.string(forKey: "pass")
                
                var url_str = Server.SERVER
                url_str = url_str + Server.GET_COMM_ID
                url_str = url_str + "login=" + (login?.stringByAddingPercentEncodingForRFC3986())!
                url_str = url_str + "&pwd=" + UserDefaults.standard.string(forKey: "pwd")!
                url_str = url_str + "&id=" + self.reqId_
                var request = URLRequest(url: URL(string:  url_str)!)
                request.httpMethod = "GET"
                
                URLSession.shared.dataTask(with: request) {
                    data, error, responce in
                    
                    guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                        DispatchQueue.main.async {
                            self.present(alert, animated: true, completion: nil)
                            self.endAnimator()
                            self.view.isUserInteractionEnabled = true
                        }
                        return
                    }
                    #if DEBUG
                    print(String(data: data!, encoding: .utf8) ?? "")
                    #endif
                    
                    DispatchQueue.main.async {
                        let xml = XML.parse(data!)
                        self.parse(xml: xml)
                        
                        self.img = nil
//                        self.collection.reloadData()
                        self.commentField.text = ""
                        self.commentField.placeholder = "Сообщение"
                        self.view.endEditing(true)
                        self.delegate?.update()
                        
                        // Подождем пока закроется клавиатура
                        DispatchQueue.global(qos: .userInteractive).async {
                            usleep(900000)
                            
                            DispatchQueue.main.async {
                                self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                                self.endAnimator()
                            }
                        }
                    }
                    
                    }.resume()
                
            }
            
//            DispatchQueue.main.async {
//                if #available(iOS 10.0, *) {
//                    self.collection.refreshControl?.endRefreshing()
//                } else {
//                    self.refreshControl?.endRefreshing()
//                }
//            }
        }
    }
    
    func parse(xml: XML.Accessor) {
        var index = 1
        let requests = xml["Messages"]
        let row1 = requests["Request"]
        let row2 = requests["Comm"]
        var rows: [String : [Request]] = [:]
        var rowComms: [String : [RequestComment]]  = [:]
        DispatchQueue.global(qos: .userInitiated).async {
            
//            let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            
//            let uid = UUID().uuidString
//            print(uid)
            row1.forEach { row1 in
                rows[row1.attributes["Status"]!]?.append(Request(row: row1))
                rowComms[row1.attributes["ID"]!] = []
                let status = row1.attributes["Status"]!
                self.data_.status = status
                print("PrComm: ", row2)
                row2.forEach { row in
                    rowComms[row.attributes["ID"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["text"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["CreatedDate"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["id_Author"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["id_file"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["isHidden"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["id_request"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["Name"]!]?.append( RequestComment(row: row) )
                    rowComms[row.attributes["PhoneNum"]!]?.append( RequestComment(row: row) )
                    index += 1
//                    self.arr = self.comments_
                    if index > self.arr.count{
                        if !(row.attributes["text"]!.containsIgnoringCase(find: "+skip")){
                            self.arr.append( ServiceCommentCellData(icon: UIImage(named: "account")!, title: row.attributes["Name"]!, desc: row.attributes["text"]!, date: row.attributes["CreatedDate"]!, id: row.attributes["ID"]!))
                        }
                    }
//                    self.arr.append( ServiceCommentCellData(image: UIImage(named: "account")!, title: row.attributes["Name"]!, comment: row.attributes["text"]!, date: row.attributes["CreatedDate"]!, id: row.attributes["ID"]!))
//                    if index < self.arr.count{
//                        print("--REMOVE--")
//                        self.arr.removeLast()
//                    }
                }
            }
            DispatchQueue.main.async {
                self.collection.reloadData()
                self.view.isUserInteractionEnabled = true
                if #available(iOS 10.0, *) {
                    self.collection.refreshControl?.endRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(notification:NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            view.frame.origin.y = 0 - keyboardHeight
            collection.contentInset.top = keyboardHeight
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(notification:NSNotification) {
        view.frame.origin.y = 0
        collection.contentInset.top = 0
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceHeader", for: indexPath) as! ServiceHeader
            cell.display((arr[indexPath.row] as! ServiceHeaderData), delegate: self)
            return cell
        
        } else {
            let arr1 = arr[indexPath.row] as! ServiceCommentCellData
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            let calendar = Calendar.current
            var day = String(calendar.component(.day, from: dateFormatter.date(from: arr1.date)!))
            if day.count == 1{
                day = "0" + day
            }
            var month = String(calendar.component(.month, from: dateFormatter.date(from: arr1.date)!))
            if month.count == 1{
                month = "0" + month
            }
            let year = String(calendar.component(.year, from: dateFormatter.date(from: arr1.date)!))
            let date = day + "." + month + "." + year
            if arr1.title == UserDefaults.standard.string(forKey: "name") ?? "" || arr1.title == UserDefaults.standard.string(forKey: "login") ?? ""{
                var showDate = true
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCommentUserCell", for: indexPath) as! ServiceCommentUserCell
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                print(arr1.date)
                if dateFormatter.date(from: date)! > commDate{
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }else{
                    showDate = false
                }
                if indexPath.row == 1{
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }
                cell.display((arr[indexPath.row] as! ServiceCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                return cell
            }else{
                var showDate = true
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCommentConstCell", for: indexPath) as! ServiceCommentConstCell
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                if dateFormatter.date(from: date)! > commDate{
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }else{
                    showDate = false
                }
                if indexPath.row == 1{
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }
                cell.display((arr[indexPath.row] as! ServiceCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                return cell
            }
        }
    }
    var commDate = Date()
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 {
            let cell = ServiceHeader.fromNib()
            cell?.display((arr[indexPath.row] as! ServiceHeaderData), delegate: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width, height: size.height)
            
        } else {
            let arr1 = arr[indexPath.row] as! ServiceCommentCellData
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            let calendar = Calendar.current
            var day = String(calendar.component(.day, from: dateFormatter.date(from: arr1.date)!))
            if day.count == 1{
                day = "0" + day
            }
            var month = String(calendar.component(.month, from: dateFormatter.date(from: arr1.date)!))
            if month.count == 1{
                month = "0" + month
            }
            let year = String(calendar.component(.year, from: dateFormatter.date(from: arr1.date)!))
            let date = day + "." + month + "." + year
            if arr1.title == UserDefaults.standard.string(forKey: "name") ?? "" || arr1.title == UserDefaults.standard.string(forKey: "login") ?? "" {
                var showDate = true
                let cell = ServiceCommentUserCell.fromNib()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                if dateFormatter.date(from: date)! > commDate{
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }else{
                    showDate = false
                }
                if indexPath.row == 1{
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }
                cell?.display((arr[indexPath.row] as! ServiceCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
                let ar = arr[indexPath.row] as! ServiceCommentCellData
                if ar.desc == "Прикреплено фото" || ar.desc == "Добавлен файл"{
                    return CGSize(width: view.frame.size.width, height: 0)
                }
                return CGSize(width: view.frame.size.width, height: size.height)
            }else{
                var showDate = true
                let cell = ServiceCommentConstCell.fromNib()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                if dateFormatter.date(from: date)! > commDate{
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }else{
                    showDate = false
                }
                if indexPath.row == 1{
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    commDate = dateFormatter.date(from: arr1.date) ?? Date()
                    showDate = true
                }
                cell?.display((arr[indexPath.row] as! ServiceCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
                let ar = arr[indexPath.row] as! ServiceCommentCellData
                if ar.desc == "Прикреплено фото" || ar.desc == "Добавлен файл"{
                    return CGSize(width: view.frame.size.width, height: 0)
                }
                return CGSize(width: view.frame.size.width, height: size.height)
            }
        }
    }
    
    private func sendComment(_ comment: String = "") {
        
        let comm = commentField.text!.stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_COMM + "reqID=" + reqId_ + "&text=" + comm)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                let alert = UIAlertController(title: "Ошбика сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                    self.endAnimator()
                }
                return
            }
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            DispatchQueue.main.async {
                let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                self.arr.append( ServiceCommentCellData(icon: UIImage(named: "account")!, title: accountName, desc: self.commentField.text!, date: dateFormatter.string(from: Date()), image: self.img, id: UUID().uuidString)  )
//                self.comments_.append(ServiceCommentCellData(icon: UIImage(named: "account")!, title: accountName, desc: self.commentField.text!, date: dateFormatter.string(from: Date()), image: self.img, id: UUID().uuidString))
                self.img = nil
                self.collection.reloadData()
                self.commentField.text = ""
                self.commentField.placeholder = "Сообщение"
                self.view.endEditing(true)
                self.delegate?.update()
                
                // Подождем пока закроется клавиатура
                DispatchQueue.global(qos: .userInteractive).async {
                    usleep(900000)
                    
                    DispatchQueue.main.async {
                        self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                        self.endAnimator()
                    }
                }
            }
            
        }.resume()
    }
    
    private func uploadPhoto(_ img: UIImage, isSplit: Bool = false) {
        
        let reqID = reqId_.stringByAddingPercentEncodingForRFC3986()
        let id = UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986()
        let comm = commentField.text ?? ""
        if isSplit {
//            commentField.text = ""
        }
        
        let uid = UUID().uuidString
        print(uid)
        Alamofire.upload(multipartFormData: { multipartFromdata in
            multipartFromdata.append(UIImageJPEGRepresentation(img, 0.5)!, withName: uid, fileName: "\(uid).jpg", mimeType: "image/jpeg")
        }, to: Server.SERVER + Server.ADD_FILE + "reqID=" + reqID! + "&accID=" + id!) { (result) in
         
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    if response.response == nil || response.result.value == nil {
                        let alert = UIAlertController(title: "Ошибка соединения", message: "Попробуйте позже", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                        DispatchQueue.main.async {
                            self.endAnimator()
                            self.present(alert, animated: true, completion: nil)
                        }
                        return
                    }
                    print(response.result.value!)
                    
                    let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    self.arr.append( ServiceCommentCellData(icon: UIImage(named: "account")!, title: accountName, desc: self.commentField.text!, date: dateFormatter.string(from: Date()), image: img, id: uid)  )
                    
                    if !isSplit {
                        
                        self.img = nil
                        self.collection.reloadData()
//                        self.commentField.text = ""
                        self.commentField.placeholder = "Сообщение"
                        self.view.endEditing(true)
                        self.delegate?.update()
                        
                        // Подождем пока закроется клавиатура
                        DispatchQueue.global(qos: .userInteractive).async {
                            usleep(900000)
                            
                            DispatchQueue.main.async {
                                self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                                self.endAnimator()
                            }
                        }
                        
                    } else {
                        DispatchQueue.main.async {
                            self.img = nil
                            self.sendComment(comm)
                        }
                    }
                    
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
        return
    }
    
    private func startAnimator() {
        loader.isHidden = false
        loader.startAnimating()
        sendBtn.isHidden = true
    }
    
    private func endAnimator() {
        loader.isHidden = true
        loader.stopAnimating()
        sendBtn.isHidden = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        img = info[UIImagePickerControllerOriginalImage] as? UIImage
        sendButtonPressed(nil)
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonPressed(nil)
        return true
    }
    
    func imagePressed(_ sender: UITapGestureRecognizer) {
        imageTapped(sender)
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        let view = UIView()
        view.frame = UIScreen.main.bounds
        view.backgroundColor = .black
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        let k = Double((imageView.image?.size.height)!) / Double((imageView.image?.size.width)!)
        let l = Double((imageView.image?.size.width)!) / Double((imageView.image?.size.height)!)
        if k > l{
            newImageView.frame.size.height = self.view.frame.size.width * CGFloat(k)
        }else{
            newImageView.frame.size.height = self.view.frame.size.width / CGFloat(l)
        }
        newImageView.frame.size.width = self.view.frame.size.width
        let y = (UIScreen.main.bounds.size.height - newImageView.frame.size.height) / 2
        newImageView.frame = CGRect(x: 0, y: y, width: newImageView.frame.size.width, height: newImageView.frame.size.height)
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleToFill
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage(_:)))
        view.addGestureRecognizer(tap)
        view.addSubview(newImageView)
        self.view.addSubview(view)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
    }
}

final class ServiceHeader: UICollectionViewCell {
    
    @IBOutlet private weak var imageLoader: UIActivityIndicatorView!
//    @IBOutlet private weak var scrollTop:   NSLayoutConstraint!
    @IBOutlet private weak var imageConst:  NSLayoutConstraint!
    @IBOutlet private weak var problem:     UILabel!
    @IBOutlet private weak var problemHeight: NSLayoutConstraint!
    @IBOutlet private weak var place:       UILabel!
    @IBOutlet private weak var placeLbl:    UILabel!
    @IBOutlet private weak var placeHeight: NSLayoutConstraint!
    @IBOutlet private weak var separator:   UILabel!
    @IBOutlet private weak var noDateHeight: NSLayoutConstraint!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var status:      UILabel!
    @IBOutlet private weak var noDateLbl:   UILabel!
    
    private var delegate: TechServiceCellsProtocol?
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        print(label.frame.height, width)
        return label.frame.height
    }
    
    fileprivate func display(_ item: ServiceHeaderData, delegate: TechServiceCellsProtocol) {
        if item.placeHome == ""{
            place.isHidden = true
            placeLbl.isHidden = true
            separator.isHidden = true
            placeHeight.constant = 0
        }else{
            place.text = item.placeHome
            place.isHidden = false
            placeLbl.isHidden = false
            separator.isHidden = false
            let k = heightForView(text: item.placeHome, font: place.font, width: place.frame.size.width)
            if k > 20{
                placeHeight.constant = k + 40
            }else{
                placeHeight.constant = 60
            }
        }
        self.delegate = delegate
        imageLoader.isHidden = true
        imageLoader.stopAnimating()
        noDateHeight.constant = 0
        noDateLbl.isHidden = true
        problem.text = item.problem
        let k = heightForView(text: item.problem, font: problem.font, width: problem.frame.size.width)
        if k > 20{
            problemHeight.constant = k
        }else{
            problemHeight.constant = 20
        }
        icon.image = item.icon
        status.text = item.status
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        print(item.date)
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM HH:mm").contains(find: "Послезавтра") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "") : dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM HH:mm")
        if item.soonPossible{
            date.text = "Как можно скорее"
            if item.status != "Принята к выполнению"{
                noDateHeight.constant = 64
                noDateLbl.isHidden = false
            }else{
                noDateHeight.constant = 0
                noDateLbl.isHidden = true
            }
        }
        scroll.isScrollEnabled = true
        if item.images.count == 0 {
            imageConst.constant = 0
//            scrollTop.constant  = 0
            scroll.isHidden = true
        
        } else {
            imageConst.constant = 150
//            scrollTop.constant  = 16
            scroll.isHidden = false
        }
        
        if item.imgsString.count == 0 && item.images.count != 0 {
            imageConst.constant = 150
            var x: CGFloat = 0.0
            item.images.forEach {
                let image = UIImageView(frame: CGRect(x: x, y: 0, width: CGFloat(150.0), height: scroll.frame.size.height))
                image.image = $0
                x += 165.0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imagePressed(_:)))
                image.isUserInteractionEnabled = true
                image.addGestureRecognizer(tap)
                scroll.addSubview(image)
            }
            scroll.contentSize = CGSize(width: x, height: scroll.frame.size.height)

        } else if item.imgsString.count != 0{
            imageConst.constant = 150
            //            scrollTop.constant  = 16
            scroll.isHidden = false
            imageLoader.isHidden = false
            imageLoader.startAnimating()

            var rowImgs: [UIImage] = []

            DispatchQueue.global(qos: .userInitiated).async {

                item.imgsString.forEach { img in

                    var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + img)!)
                    request.httpMethod = "GET"
                    print(request)
                    
                    let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)

                    if data != nil {
                        rowImgs.append(UIImage(data: data!)!)
                    }
                }

                DispatchQueue.main.async {
                    var x = 0.0
                    rowImgs.forEach {
                        let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: self.scroll.frame.size.height))
                        image.image = $0
                        x += 165.0
                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.imagePressed(_:)))
                        image.isUserInteractionEnabled = true
                        image.addGestureRecognizer(tap)
                        self.scroll.addSubview(image)
                    }
                    self.scroll.contentSize = CGSize(width: CGFloat(x), height: self.scroll.frame.size.height)
                    self.imageLoader.isHidden = true
                    self.imageLoader.stopAnimating()
                }
            }
        }else{
            imageConst.constant = 0
            scroll.isHidden = true
        }
    }
    
    @objc func imagePressed(_ sender: UITapGestureRecognizer) {
        delegate?.imagePressed(sender)
    }
    
    class func fromNib() -> ServiceHeader? {
        var cell: ServiceHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServiceHeader {
                cell = view
            }
        }
        cell?.problem.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 25
        return cell
    }
}

final class ServiceHeaderData: TechServiceProtocol {
    
    let icon:       UIImage
    let problem:    String
    let date:       String
    var status:     String
    let isPaid:     String
    let images:     [UIImage]
    let imgsString: [String]
    let placeHome:  String
    let soonPossible: Bool
    let isReaded:   String
//    let desc:       String
    
    init(icon: UIImage, problem: String, date: String, status: String, images: [UIImage] = [], imagesUrl: [String] = [], isPaid: String, placeHome: String, soonPossible: Bool, isReaded: String) {
        
        self.icon       = icon
        self.problem    = problem
        self.date       = date
        self.status     = status
        self.images     = images
        self.imgsString = imagesUrl
        self.isPaid     = isPaid
        self.placeHome  = placeHome
        self.soonPossible = soonPossible
        self.isReaded   = isReaded
//        self.desc       = desc
    }
}

final class ServiceCommentUserCell: UICollectionViewCell {
    
    @IBOutlet private weak var imgsLoader:  UIActivityIndicatorView!
    @IBOutlet private      var imgsConst:   NSLayoutConstraint!
    @IBOutlet private      var commConst:   NSLayoutConstraint!
    @IBOutlet private      var imgs2Const:   NSLayoutConstraint!
    @IBOutlet private      var comm2Const:   NSLayoutConstraint!
    @IBOutlet private      var imgHeight:   NSLayoutConstraint!
    @IBOutlet private      var imgWidth:    NSLayoutConstraint!
    @IBOutlet              var heightDate:  NSLayoutConstraint!
    @IBOutlet private      var commHeight:  NSLayoutConstraint!
    @IBOutlet private weak var comImg:      UIImageView!
    @IBOutlet private weak var desc:     UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var time:        UILabel!
    
    private var delegate: TechServiceCellsProtocol?
    
    fileprivate func display(_ item: ServiceCommentCellData, delegate: TechServiceCellsProtocol, showDate: Bool, delegate2: UIViewController) {
        
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.image != nil || item.imgUrl != nil {
            desc.isHidden   = true
            comImg.isHidden    = false
            comImg.image       = item.image
            imgsConst.isActive = false
            commConst.isActive = true
            imgs2Const?.isActive = false
            comm2Const?.isActive = true
            imgWidth.constant = 150
            imgHeight.constant = 150
            desc.text = ""
        } else {
            desc.isHidden = false
            comImg.isHidden  = true
            imgsConst.isActive = true
            commConst.isActive = false
            imgs2Const?.isActive = true
            comm2Const?.isActive = false
            imgWidth.constant = 50
            imgHeight.constant = 50
        }
        
        desc.text    = item.desc
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dat = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM")
        let tim = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "HH:mm")
        print(dat, tim)
        if dat.contains(find: "Сегодня") || dat.contains(find: "Вчера"){
            let dat1 = dat.components(separatedBy: ",")
            let tim1 = tim.components(separatedBy: ",")
            date.text = String(dat1[0])
            time.text = String(tim1[1])
        }else{
            date.text = dat
            time.text = tim
        }
        if showDate{
            heightDate.constant = 31
        }else{
            heightDate.constant = 0
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(imagePressed(_:)))
        comImg.isUserInteractionEnabled = true
        comImg.addGestureRecognizer(tap)
        
        if item.imgUrl != nil {
            
            if imgs.keys.contains(item.id) {
                self.comImg.image = imgs[item.id]
            }
            
            imgsLoader.isHidden = false
            imgsLoader.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + item.imgUrl!)!)
                request.httpMethod = "GET"
                
                let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
                
                if data != nil {
                    DispatchQueue.main.async {
                        let imgDt = UIImage(data: data!)
                        imgs[item.id] = imgDt
                        self.comImg.image = imgDt
                        self.imgsLoader.isHidden = true
                        self.imgsLoader.stopAnimating()
                    }
                }
            }
        }
        commHeight.constant = heightForTitle(text: item.desc, width: delegate2.view.frame.size.width - 100)
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    @objc private func imagePressed(_ sender: UITapGestureRecognizer) {
        delegate?.imagePressed(sender)
    }
    
    class func fromNib() -> ServiceCommentUserCell? {
        var cell: ServiceCommentUserCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServiceCommentUserCell {
                cell = view
            }
        }
        cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width ?? 0.0
        return cell
    }
}

final class ServiceCommentConstCell: UICollectionViewCell {
    
    @IBOutlet private weak var imgsLoader:  UIActivityIndicatorView!
    @IBOutlet private      var imgsConst:   NSLayoutConstraint!
    @IBOutlet private      var commConst:   NSLayoutConstraint!
    @IBOutlet private      var imgs2Const:   NSLayoutConstraint!
    @IBOutlet private      var comm2Const:   NSLayoutConstraint!
    @IBOutlet private      var imgHeight:   NSLayoutConstraint!
    @IBOutlet private      var imgWidth:    NSLayoutConstraint!
    @IBOutlet              var heightDate:  NSLayoutConstraint!
    @IBOutlet private      var commHeight:  NSLayoutConstraint!
    @IBOutlet private weak var comImg:      UIImageView!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var desc:        UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var time:        UILabel!
    
    private var delegate: TechServiceCellsProtocol?
    
    fileprivate func display(_ item: ServiceCommentCellData, delegate: TechServiceCellsProtocol, showDate: Bool, delegate2: UIViewController) {
        
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.image != nil || item.imgUrl != nil {
            desc.isHidden   = true
            comImg.isHidden    = false
            comImg.image       = item.image
            imgsConst.isActive = false
            commConst.isActive = true
            imgs2Const?.isActive = false
            comm2Const?.isActive = true
            imgWidth.constant = 150
            imgHeight.constant = 150
            desc.text = ""
        } else {
            desc.isHidden = false
            comImg.isHidden  = true
            imgsConst.isActive = true
            commConst.isActive = false
            imgs2Const?.isActive = true
            comm2Const?.isActive = false
            imgWidth.constant = 50
            imgHeight.constant = 50
        }
        
        title.text      = item.title
        desc.text    = item.desc
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dat = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM")
        let tim = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "HH:mm")
        print(dat, tim)
        if dat.contains(find: "Сегодня") || dat.contains(find: "Вчера"){
            let dat1 = dat.components(separatedBy: ",")
            let tim1 = tim.components(separatedBy: ",")
            date.text = String(dat1[0])
            time.text = String(tim1[1])
        }else{
            date.text = dat
            time.text = tim
        }
        if showDate{
            heightDate.constant = 31
        }else{
            heightDate.constant = 0
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(imagePressed(_:)))
        comImg.isUserInteractionEnabled = true
        comImg.addGestureRecognizer(tap)
        
        if item.imgUrl != nil {
            
            if imgs.keys.contains(item.id) {
                self.comImg.image = imgs[item.id]
            }
            
            imgsLoader.isHidden = false
            imgsLoader.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + item.imgUrl!)!)
                request.httpMethod = "GET"
                
                let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
                
                if data != nil {
                    DispatchQueue.main.async {
                        let imgDt = UIImage(data: data!)
                        imgs[item.id] = imgDt
                        self.comImg.image = imgDt
                        self.imgsLoader.isHidden = true
                        self.imgsLoader.stopAnimating()
                    }
                }
            }
        }
        commHeight.constant = heightForTitle(text: item.desc, width: delegate2.view.frame.size.width - 100)
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE){
            commHeight.constant = heightForTitle(text: item.desc, width: delegate2.view.frame.size.width - 90)
        }
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    @objc private func imagePressed(_ sender: UITapGestureRecognizer) {
        delegate?.imagePressed(sender)
    }
    
    class func fromNib() -> ServiceCommentConstCell? {
        var cell: ServiceCommentConstCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServiceCommentConstCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth  = cell?.title.bounds.size.width ?? 0.0
        return cell
    }
}

final class ServiceCommentCellData: TechServiceProtocol {
    
    let image:  UIImage?
    let icon:   UIImage
    let title:  String
    let desc:   String
    let date:   String
    let imgUrl: String?
    let id:     String
    
    init(icon: UIImage, title: String, desc: String, date: String, image: UIImage? = nil, imageUrl: String? = nil, id: String) {
        
        self.icon   = icon
        self.title  = title
        self.desc   = desc
        self.date   = date
        self.image  = image
        self.imgUrl = imageUrl
        self.id     = id
    }
}

private var imgs: [String:UIImage] = [:]






