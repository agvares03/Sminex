//
//  AdmissionVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyXMLParser

private protocol AdmissionProtocol: class {}
private var mainScreenXml:  XML.Accessor?
private protocol AdmissionCellsProtocol: class {
    func imageTapped(_ sender: UITapGestureRecognizer)
}

final class AdmissionVC: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AdmissionCellsProtocol{
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var commentField:    UITextField!
    @IBOutlet private weak var sendBtn:         UIButton!
    @IBOutlet private weak var cameraButton:    UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        imgs = [:]
        if isCreated_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 4], animated: true)
        
        } else if isFromNotifi_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
            
        } else if isFromMain_ {
            navigationController?.popToRootViewController(animated: true)
        
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction private func cameraPressed(_ sender: UIButton) {
        
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
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton?) {
        
        if img == nil {
            if commentField.text == ""
                || commentField.text == nil {
                commentField.placeholder = "Введите сообщение!"
                return
            }
        }
        startAnimating()
        if img != nil && commentField.text != "" {
            self.uploadPhoto(img!, isSplit: true)
            return
            
        } else if img == nil && commentField.text != "" {
            self.sendComment()
        } else if img != nil && commentField.text == "" {
            self.uploadPhoto(img!)
        }
    }
    
    public var name_: String?
    public var delegate:   AppsUserDelegate?
    public var reqId_      = ""
    public var isCreated_  = false
    public var isFromMain_ = false
    public var isFromNotifi_ = false
    public var data_: AdmissionHeaderData = AdmissionHeaderData(icon: UIImage(named: "account")!,
                                                                gosti: "А. Е. Филимонов, В. В. Иванова",
                                                                mobileNumber: "+7 965 913 95 67",
                                                                gosNumber: "А 033 ЕО 777", mark: "Toyota",
                                                                date: "9 Сентября 10:00",
                                                                status: "В ОБРАБОТКЕ",
                                                                images: [],
                                                                imagesUrl: [], desc: "", placeHome: "")
    public var comments_: [AdmissionCommentCellData] = []
    
    private var arr: [AdmissionProtocol] = []
    private var img: UIImage?
    
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        endAnimating()
        automaticallyAdjustsScrollViewInsets = false
        arr = comments_
        arr.insert(data_, at: 0)
        
        commentField.delegate                   = self
        collection.delegate                     = self
        collection.dataSource                   = self
        automaticallyAdjustsScrollViewInsets    = false
        
        commentField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: commentField.frame.height))
        commentField.rightViewMode = .always
        
        let reconizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        reconizer.delegate              = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(reconizer)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        commentField.inputAccessoryView = nil
        collection.reloadData()
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
                self.getMessages()
                sleep(2)
                DispatchQueue.main.sync {
//                    self.data[IndexPath] = [0 : CellsHeaderData(title: "Заявки")]
//                    res.forEach {
//                        self.data_[IndexPath]![count] = $0
//                        count += 1
//                    }
//                    self.data[IndexPath]![count] = RequestAddCellData(title: "Добавить заявку")
                    self.collection.reloadData()
                }
            }
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    self.collection.refreshControl?.endRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification) {
        if let keyboardSize = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            view.frame.origin.y = 0 - keyboardHeight
            collection.contentInset.top = keyboardHeight
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.frame.origin.y = 0
        collection.contentInset.top = 0
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 {

            let cell = AdmissionHeader.fromNib()
            cell?.display((arr[0] as! AdmissionHeaderData), delegate: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width, height: size.height)
            
        } else {
            let arr1 = arr[indexPath.row] as! AdmissionCommentCellData
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
                let cell = AdmissionCommentUserCell.fromNib()
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
                cell?.display((arr[indexPath.row] as! AdmissionCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
                let ar = arr[indexPath.row] as! AdmissionCommentCellData
                if ar.comment == "Прикреплено фото" || ar.comment == "Добавлен файл"{
                    return CGSize(width: view.frame.size.width, height: 0)
                }
                return CGSize(width: view.frame.size.width, height: size.height)
            }else{
                var showDate = true
                let cell = AdmissionCommentConstCell.fromNib()
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
                cell?.display((arr[indexPath.row] as! AdmissionCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
                let ar = arr[indexPath.row] as! AdmissionCommentCellData
                if ar.comment == "Прикреплено фото" || ar.comment == "Добавлен файл"{
                    return CGSize(width: view.frame.size.width, height: 0)
                }
                return CGSize(width: view.frame.size.width, height: size.height)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    var commDate = Date()
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdmissionHeader1", for: indexPath) as! AdmissionHeader
            cell.display((arr[0] as! AdmissionHeaderData), delegate: self)
            return cell
        
        } else {
            let arr1 = arr[indexPath.row] as! AdmissionCommentCellData
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
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdmissionCommentUserCell", for: indexPath) as! AdmissionCommentUserCell
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
                cell.display((arr[indexPath.row] as! AdmissionCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                return cell
            }else{
                var showDate = true
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdmissionCommentConstCell", for: indexPath) as! AdmissionCommentConstCell
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
                cell.display((arr[indexPath.row] as! AdmissionCommentCellData), delegate: self, showDate: showDate, delegate2: self)
                return cell
            }
        }
    }
    
    func getMessages(){
            
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass  = UserDefaults.standard.string(forKey: "pwd") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_COMM_ID + "login=" + login + "&pwd=" + pass + "&id=" + self.reqId_)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            let responseString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
            print("responseString = \(responseString)")
            #endif
            let xml = XML.parse(data!)
            var index = 1
            let requests = xml["Messages"]
            let row1 = requests["Request"]
            let row2 = requests["Comm"]
            var rows: [String : [Request]] = [:]
            var rowComms: [String : [RequestComment]]  = [:]
            row1.forEach { row1 in
                rows[row1.attributes["Status"]!]?.append(Request(row: row1))
                rowComms[row1.attributes["ID"]!] = []
                let status = row1.attributes["Status"]!
                self.data_.status = status
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
//                    self.arr.insert(self.data_, at: 0)
                    if index > self.arr.count{
                        self.arr.append( AdmissionCommentCellData(image: UIImage(named: "account")!, title: row.attributes["Name"]!, comment: row.attributes["text"]!, date: row.attributes["CreatedDate"]!, id: row.attributes["ID"]!))
                    }
//                    if index < self.arr.count{
//                        self.arr.removeLast()
//                    }
                }
            }
            
            DispatchQueue.main.async {
                self.collection.reloadData()
                self.commentField.text = ""
                self.commentField.placeholder = "Сообщение"
                self.view.endEditing(true)
                self.delegate?.update()
                self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                self.endAnimating()
            }
            
            }.resume()
    }
    
    private func sendComment(_ comment: String = "") {
        
        let comm = comment == "" ? commentField.text?.stringByAddingPercentEncodingForRFC3986() ?? "" : comment
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_COMM + "reqID=" + reqId_ + "&text=" + comm)!)
        request.httpMethod = "GET"
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                let alert = UIAlertController(title: "Ошбика сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                    self.endAnimating()
                }
                return
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8)!)
            #endif
            
            DispatchQueue.main.async {
                let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                self.arr.append( AdmissionCommentCellData(image: UIImage(named: "account")!, title: accountName, comment: self.commentField.text!, date: dateFormatter.string(from: Date()),commImg: self.img, id: UUID().uuidString)  )
                self.collection.reloadData()
                self.img = nil
                self.commentField.text = ""
                self.commentField.placeholder = "Сообщение"
                self.view.endEditing(true)
                self.delegate?.update()
                
                // Подождем пока закроется клваиатура
                DispatchQueue.global(qos: .userInteractive).async {
                    usleep(900000)
                    
                    DispatchQueue.main.async {
                        self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                        self.endAnimating()
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
                            self.endAnimating()
                            self.present(alert, animated: true, completion: nil)
                        }
                        return
                    }
                    print(response.result.value!)
                    
                    let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
                    self.arr.append( AdmissionCommentCellData(image: UIImage(named: "account")!, title: accountName, comment: self.commentField.text!, date: dateFormatter.string(from: Date()),commImg: img, id: uid)  )
                    
                    if !isSplit {
                        self.collection.reloadData()
                        self.img = nil
//                        self.commentField.text = ""
                        self.commentField.placeholder = "Сообщение"
                        self.view.endEditing(true)
                        self.delegate?.update()
                    
                        // Подождем пока закроется клваиатура
                        DispatchQueue.global(qos: .userInteractive).async {
                            usleep(900000)
                            
                            DispatchQueue.main.async {
                                self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                                self.endAnimating()
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
    
    private func startAnimating() {
        sendBtn.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimating() {
        DispatchQueue.main.async {
            self.sendBtn.isHidden = false
            self.loader.stopAnimating()
            self.loader.isHidden = true
        }
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


final class AdmissionHeader: UICollectionViewCell {
    
    @IBOutlet private weak var imageLoader: UIActivityIndicatorView!
    @IBOutlet private weak var imageConst:  NSLayoutConstraint!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var gosConstant:     NSLayoutConstraint!
    @IBOutlet private weak var markConstant:     NSLayoutConstraint!
    @IBOutlet private weak var gostiConstant:     NSLayoutConstraint!
    
    @IBOutlet private weak var image:           UIImageView!
    @IBOutlet private weak var gosti:           UILabel!
    @IBOutlet private weak var mobileNumber:    UILabel!
    @IBOutlet private weak var gosNumbers:      UILabel!
    @IBOutlet private weak var gosTitle:        UILabel!
    @IBOutlet private weak var gosLine:         UILabel!
    @IBOutlet private weak var markAuto:        UILabel!
    @IBOutlet private weak var markTitle:       UILabel!
    @IBOutlet private weak var markLine:        UILabel!
    @IBOutlet private weak var date:            UILabel!
    @IBOutlet private weak var status:          UILabel!
    @IBOutlet private weak var descText:        UILabel?
    @IBOutlet private weak var descTitle:       UILabel?
    @IBOutlet private weak var descLine:        UILabel?
    @IBOutlet private weak var descConstant:    NSLayoutConstraint?
    
    @IBOutlet private weak var place:       UILabel!
    @IBOutlet private weak var placeLbl:    UILabel!
    @IBOutlet private weak var separator:   UILabel!
    @IBOutlet private weak var placeHeight: NSLayoutConstraint?
    
    @IBOutlet weak var heigthFooter: NSLayoutConstraint?
    @IBOutlet weak var phone_service: UILabel!
    @IBOutlet weak var img_phone_service: UIImageView!
    @IBOutlet weak var heigth_phone_service: NSLayoutConstraint?
    
    private var delegate: AdmissionCellsProtocol?
    
    fileprivate func display(_ item: AdmissionHeaderData, delegate: AdmissionCellsProtocol) {
        if item.placeHome == ""{
            place.isHidden = true
            placeLbl.isHidden = true
            separator.isHidden = true
            placeHeight?.isActive = true
            placeHeight?.constant = 0
        }else{
            place.text = item.placeHome
            place.isHidden = false
            placeLbl.isHidden = false
            separator.isHidden = false
            let k = heightForTitle(text: item.placeHome, width: place.frame.size.width)
            if k > 24{
                placeHeight?.constant = k + 36
            }else{
                placeHeight?.constant = 58
            }
        }
        self.delegate = delegate
//        imgsLoader.isHidden = true
//        imgsLoader.stopAnimating()
        imageLoader.isHidden = true
        imageLoader.stopAnimating()
        if item.gosNumber == "" {
            gosConstant?.constant = 0
            gosNumbers.isHidden  = true
            gosLine.isHidden     = true
            gosTitle.isHidden    = true
            heigthFooter?.constant = 0
            heigth_phone_service?.constant = 0
        } else {
            if (UserDefaults.standard.bool(forKey: "denyImportExportPropertyRequest")) {
                heigthFooter?.constant = 100
                let data_: [ContactsJson] = TemporaryHolder.instance.contactsList
                var phone: String = ""
                for data in data_ {
                    if (data.name?.contains(find: "Консьерж"))! {
                        phone = data.phone ?? "";
                    }
                }
                if (phone != "") {
                    
                    heigthFooter?.constant = 100
                    heigth_phone_service?.constant = 110
                    phone_service.text = phone
                    
                } else {
                    
                    heigthFooter?.constant = 100
                    heigth_phone_service?.constant = 0
                    
                }
            } else {
                heigthFooter?.constant = 0
                heigth_phone_service?.constant = 0
            }
            let k = heightForTitle(text: item.gosNumber, width: gosNumbers.frame.size.width)
            if k > 24{
                gosConstant?.constant = k + 36
            }else{
                gosConstant?.constant = 58
            }
            gosNumbers.isHidden  = false
            gosLine.isHidden     = false
            gosTitle.isHidden    = false
        }
        
        if item.mark == "" {
            markConstant?.constant = 0
            markAuto.isHidden    = true
            markLine.isHidden    = true
            markTitle.isHidden   = true
        } else {
            let k = heightForTitle(text: item.mark, width: markAuto.frame.size.width)
            if k > 24{
                markConstant?.constant = k + 36
            }else{
                markConstant?.constant = 58
            }
            markAuto.isHidden    = false
            markLine.isHidden    = false
            markTitle.isHidden   = false
        }
        
        if item.desc == "" {
            descConstant?.constant = 0
            descText?.isHidden  = true
            descTitle?.isHidden = true
            descLine?.isHidden  = true
            descText?.text = ""
        } else {
            let k = heightForTitle(text: item.desc, width: descText!.frame.size.width)
            if k > 24{
                descConstant?.constant = k + 36
            }else{
                descConstant?.constant = 58
            }
            descText?.isHidden  = false
            descTitle?.isHidden = false
            descLine?.isHidden  = false
            descText?.text = item.desc
        }
        
        image.image         = item.icons
        gosti.text          = item.gosti
        mobileNumber.text   = item.mobileNumber
        gosNumbers.text     = item.gosNumber
        markAuto.text       = item.mark
        status.text         = item.status
        let k = heightForTitle(text: item.gosti, width: gosti.frame.size.width)
        gostiConstant?.constant = k
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Послезавтра") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "") : dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM HH:mm")
        
        if item.images.count == 0 {
            imageConst.constant = 0
            //            scrollTop.constant  = 0
            scroll.isHidden = true
            
        } else {
            imageConst.constant = 150
            //            scrollTop.constant  = 16
            scroll.isHidden = false
        }
        
        if item.imgsUrl.count == 0 {
            
            var x = 0.0
            item.images.forEach {
                let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: scroll.frame.size.height))
                image.image = $0
                x += 165.0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                image.isUserInteractionEnabled = true
                image.addGestureRecognizer(tap)
                scroll.addSubview(image)
            }
            scroll.contentSize = CGSize(width: CGFloat(x), height: scroll.frame.size.height)
            
        } else {
            imageConst.constant = 150
            //            scrollTop.constant  = 16
            scroll.isHidden = false
            imageLoader.isHidden = false
            imageLoader.startAnimating()
            
            var rowImgs: [UIImage] = []
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                item.imgsUrl.forEach { img in
                    
                    var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + img)!)
                    request.httpMethod = "GET"
                    
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
                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(_:)))
                        image.isUserInteractionEnabled = true
                        image.addGestureRecognizer(tap)
                        self.scroll.addSubview(image)
                    }
                    self.scroll.contentSize = CGSize(width: CGFloat(x), height: self.scroll.frame.size.height)
                    self.imageLoader.isHidden = true
                    self.imageLoader.stopAnimating()
                }
            }
        }
        
        let tap_phone = UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:)))
        img_phone_service.isUserInteractionEnabled   = true
        img_phone_service.addGestureRecognizer(tap_phone)
    }
    
    @objc private func phonePressed(_ sender: UITapGestureRecognizer) {
        let newPhone = phone_service.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        if let url = URL(string: "tel://" + newPhone!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
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
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.imageTapped(sender)
    }
 
    class func fromNib() -> AdmissionHeader? {
        var cell: AdmissionHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AdmissionHeader {
                cell = view
            }
        }
        return cell
    }
}

final class AdmissionHeaderData: AdmissionProtocol {
    
    let images:         [UIImage]
    let imgsUrl:        [String]
    let icons:          UIImage
    let gosti:          String
    let mobileNumber:   String
    let gosNumber:      String
    let date:           String
    var status:         String
    var desc:           String
    var mark:           String
    let placeHome:      String
    
    init(icon: UIImage, gosti: String, mobileNumber: String, gosNumber: String, mark: String, date: String, status: String, images: [UIImage], imagesUrl: [String], desc: String, placeHome: String) {
        
        self.icons          = icon
        self.gosti          = gosti
        self.mobileNumber   = mobileNumber
        self.gosNumber      = gosNumber
        self.date           = date
        self.status         = status
        self.images         = images
        self.imgsUrl        = imagesUrl
        self.desc           = desc
        self.mark           = mark
        self.placeHome      = placeHome
    }
}


final class AdmissionCommentUserCell: UICollectionViewCell {
    
    @IBOutlet private weak var imgsLoader:  UIActivityIndicatorView!
    @IBOutlet private      var imgsConst:   NSLayoutConstraint!
    @IBOutlet private      var commConst:   NSLayoutConstraint!
    @IBOutlet private      var imgs2Const:  NSLayoutConstraint!
    @IBOutlet private      var comm2Const:  NSLayoutConstraint!
    @IBOutlet private      var commHeight:  NSLayoutConstraint!
    @IBOutlet              var heightDate:  NSLayoutConstraint!
    @IBOutlet private weak var comImg:      UIImageView!
    @IBOutlet private weak var comment: 	UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var time:        UILabel!
    
    private var delegate: AdmissionCellsProtocol?
    
    fileprivate func display(_ item: AdmissionCommentCellData, delegate: AdmissionCellsProtocol, showDate: Bool, delegate2: UIViewController) {
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.img != nil || item.imgUrl != nil {
            comment.isHidden   = true
            comImg.isHidden    = false
            comImg.image       = item.img
            imgsConst.isActive = false
            commConst.isActive = true
            imgs2Const?.isActive = false
            comm2Const?.isActive = true
            comment.text = ""
        } else {
            comment.isHidden = false
            comImg.isHidden  = true
            imgsConst.isActive = true
            commConst.isActive = false
            imgs2Const?.isActive = true
            comm2Const?.isActive = false
        }
        comment.text    = item.comment
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dat = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM")
        let tim = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "HH:mm")
        if dat.contains(find: "Сегодня") || dat.contains(find: "Вчера"){
            let dat1 = dat.components(separatedBy: ",")
            let tim1 = tim.components(separatedBy: ",")
            date.text = String(dat1[0])
            time.text = String(tim1[1])
        }else{
            date.text = dat
            time.text = tim
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        comImg.isUserInteractionEnabled = true
        comImg.addGestureRecognizer(tap)
        if showDate{
            heightDate.constant = 31
        }else{
            heightDate.constant = 0
        }
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
        commHeight.constant = heightForTitle(text: item.comment, width: delegate2.view.frame.size.width - 140)
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.imageTapped(sender)
    }
    
    class func fromNib() -> AdmissionCommentUserCell? {
        var cell: AdmissionCommentUserCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AdmissionCommentUserCell {
                cell = view
            }
        }
        cell?.comment.preferredMaxLayoutWidth = cell?.comment.bounds.size.width ?? 0.0
        return cell
    }
}

final class AdmissionCommentConstCell: UICollectionViewCell{
    
    @IBOutlet private weak var imgsLoader:  UIActivityIndicatorView!
    @IBOutlet private      var imgsConst:   NSLayoutConstraint!
    @IBOutlet private      var commConst:   NSLayoutConstraint!
    @IBOutlet private      var imgs2Const:   NSLayoutConstraint!
    @IBOutlet private      var comm2Const:   NSLayoutConstraint!
    @IBOutlet private      var commHeight:  NSLayoutConstraint!
    @IBOutlet              var heightDate:  NSLayoutConstraint!
    @IBOutlet private weak var comImg:      UIImageView!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var comment:     UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var time:        UILabel!
    
    private var delegate: AdmissionCellsProtocol?
    
    fileprivate func display(_ item: AdmissionCommentCellData, delegate: AdmissionCellsProtocol, showDate: Bool, delegate2: UIViewController) {
        
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.img != nil || item.imgUrl != nil {
            comment.isHidden   = true
            comImg.isHidden    = false
            comImg.image       = item.img
            imgsConst.isActive = false
            commConst.isActive = true
            imgs2Const?.isActive = false
            comm2Const?.isActive = true
            comment.text = ""
        } else {
            comment.isHidden = false
            comImg.isHidden  = true
            imgsConst.isActive = true
            commConst.isActive = false
            imgs2Const?.isActive = true
            comm2Const?.isActive = false
        }
        
        title.text      = item.title
        comment.text    = item.comment
        commHeight.constant = heightForTitle(text: item.comment, width: delegate2.view.frame.size.width - 140)
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
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
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.imageTapped(sender)
    }
    
    class func fromNib() -> AdmissionCommentConstCell? {
        var cell: AdmissionCommentConstCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AdmissionCommentConstCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth   = cell?.title.bounds.size.width   ?? 0.0
        cell?.comment.preferredMaxLayoutWidth = cell?.comment.bounds.size.width ?? 0.0
        return cell
    }
}

final class AdmissionCommentCellData: AdmissionProtocol {
    
    let img:        UIImage?
    let image:      UIImage
    let title:      String
    let comment:    String
    let date:       String
    let imgUrl:     String?
    let id:         String
    
    init(image: UIImage, title: String, comment: String, date: String, commImg: UIImage? = nil, commImgUrl: String? = nil, id: String) {
        
        self.img        = commImg
        self.image      = image
        self.title      = title
        self.comment    = comment
        self.date       = date
        self.imgUrl     = commImgUrl
        self.id         = id
    }
}

private var imgs: [String:UIImage] = [:]





