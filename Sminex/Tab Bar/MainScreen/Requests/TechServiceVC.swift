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
    
    open var delegate:   AppsUserDelegate?
    open var reqId_      = ""
    open var isCreate_   = false
    open var isFromMain_ = false
    open var data_: ServiceHeaderData = ServiceHeaderData(icon: UIImage(named: "account")!,
                                                          problem: "Нас топят соседи! Не можем с ними связаться. Срочно вызвайте сантехника",
                                                          date: "9 сентября 10:00",
                                                          status: "В ОБРАБОТКЕ",
                                                          images: [UIImage(named: "account")!, UIImage(named: "account")!, UIImage(named: "account")!], isPaid: "0")
    
    open var comments_: [ServiceCommentCellData] = []
    private var arr:    [TechServiceProtocol]    = []
    private var img:    UIImage?
    
    private var rowComms: [String : [RequestComment]]  = [:]
    private var rowFiles:   [RequestFile] = []
    
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if data_.isPaid == "1"{
            self.navigationItem.title = "Заявка на услугу"
        }
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        arr = comments_
        arr.insert(data_, at: 0)
        
        commentField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: commentField.frame.height))
        commentField.rightViewMode = .always
        
        collection.delegate     = self
        collection.dataSource   = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
        
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
        
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.global(qos: .background).async {
                sleep(2)
                
                // Получим комментарии по одной заявке
                let defaults = UserDefaults.standard
                let login = defaults.string(forKey: "login")
                let pass = defaults.string(forKey: "pass")
                
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
                        let xml = XML.parse(data!)
                        self.parse(xml: xml)
                        
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
            
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    self.collection.refreshControl?.endRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
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
            
            let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            
            let uid = UUID().uuidString
            print(uid)
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
                    self.arr = self.comments_
                    self.arr.insert(self.data_, at: 0)
                    self.arr.append( ServiceCommentCellData(icon: UIImage(named: "account")!, title: row.attributes["Name"]!, desc: row.attributes["text"]!, date: row.attributes["CreatedDate"]!, id: row.attributes["ID"]!))
//                    self.arr.append( ServiceCommentCellData(image: UIImage(named: "account")!, title: row.attributes["Name"]!, comment: row.attributes["text"]!, date: row.attributes["CreatedDate"]!, id: row.attributes["ID"]!))
                    if index < self.arr.count{
                        self.arr.removeLast()
                    }
                }
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        if !isPlusDevices() {
            view.frame.origin.y = -250
            collection.contentInset.top = 250
        
        } else {
            view.frame.origin.y = -265
            collection.contentInset.top = 265
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceHeader", for: indexPath) as! ServiceHeader
            cell.display((arr[indexPath.row] as! ServiceHeaderData), delegate: self)
            return cell
        
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCommentCell", for: indexPath) as! ServiceCommentCell
            cell.display((arr[indexPath.row] as! ServiceCommentCellData), delegate: self)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 {
            let cell = ServiceHeader.fromNib()
            cell?.display((arr[indexPath.row] as! ServiceHeaderData), delegate: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width, height: size.height)
            
        } else {
            let cell = ServiceCommentCell.fromNib()
            cell?.display((arr[indexPath.row] as! ServiceCommentCellData), delegate: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width, height: size.height)
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
            newImageView.frame.size.height = UIScreen.main.bounds.size.width * CGFloat(k)
        }else{
            newImageView.frame.size.height = UIScreen.main.bounds.size.width / CGFloat(l)
        }
        newImageView.frame.size.width = UIScreen.main.bounds.size.width
        let y = (UIScreen.main.bounds.size.height - newImageView.frame.size.height) / 2
        newImageView.frame = CGRect(x: 0, y: y, width: newImageView.frame.size.height, height: newImageView.frame.size.height)
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
    @IBOutlet private weak var scrollTop:   NSLayoutConstraint!
    @IBOutlet private weak var imageConst:  NSLayoutConstraint!
    @IBOutlet private weak var problem:     UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var status:      UILabel!
    
    private var delegate: TechServiceCellsProtocol?
    
    fileprivate func display(_ item: ServiceHeaderData, delegate: TechServiceCellsProtocol) {
        
        self.delegate = delegate
        imageLoader.isHidden = true
        imageLoader.stopAnimating()
        
        problem.text = item.problem
        icon.image = item.icon
        status.text = item.status
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        print(item.date)
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM HH:mm").contains(find: "Послезавтра") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "") : dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM HH:mm")
        if item.images.count == 0 {
            imageConst.constant = 0
            scrollTop.constant  = 0
//            scroll.isHidden = true
        
        } else {
            imageConst.constant = 150
            scrollTop.constant  = 16
//            scroll.isHidden = false
        }
        
        if item.imgsString.count == 0 {
            
            var x = 0.0
            item.images.forEach {
                let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: scroll.frame.size.height))
                image.image = $0
                x += 165.0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imagePressed(_:)))
                image.isUserInteractionEnabled = true
                image.addGestureRecognizer(tap)
                scroll.addSubview(image)
            }
            scroll.contentSize = CGSize(width: CGFloat(x), height: scroll.frame.size.height)
        
        } else {
            
            imageLoader.isHidden = false
            imageLoader.startAnimating()
            
            var rowImgs: [UIImage] = []
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                item.imgsString.forEach { img in
                    
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
    
    init(icon: UIImage, problem: String, date: String, status: String, images: [UIImage] = [], imagesUrl: [String] = [], isPaid: String) {
        
        self.icon       = icon
        self.problem    = problem
        self.date       = date
        self.status     = status
        self.images     = images
        self.imgsString = imagesUrl
        self.isPaid     = isPaid
    }
}

final class ServiceCommentCell: UICollectionViewCell {
    
    @IBOutlet private weak var imageLoader: UIActivityIndicatorView!
    @IBOutlet private      var imgsConst:   NSLayoutConstraint!
    @IBOutlet private      var commConst:   NSLayoutConstraint!
    @IBOutlet private weak var image:       UIImageView!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var title:   	UILabel!
    @IBOutlet private weak var desc:        UILabel!
    @IBOutlet private weak var date:    	UILabel!
    
    private var delegate: TechServiceCellsProtocol?
    
    fileprivate func display(_ item: ServiceCommentCellData, delegate: TechServiceCellsProtocol) {
        
        self.delegate = delegate
        imageLoader.isHidden = true
        imageLoader.stopAnimating()
        
        if item.image != nil || item.imgUrl != nil {
            image.image        = item.image
            image.isHidden     = false
            desc.isHidden      = true
            imgsConst.isActive = false
            commConst.isActive = true
        
        } else {
            image.isHidden  = true
            desc.isHidden   = false
            imgsConst.isActive = true
            commConst.isActive = false
        }
        
        if item.title == UserDefaults.standard.string(forKey: "name") ?? "" {
            DispatchQueue.global(qos: .background).async {
                if let imageData = UserDefaults.standard.object(forKey: "accountIcon"),
                    let image = UIImage.init(data: imageData as! Data) {
                    DispatchQueue.main.async {
                        self.icon.image = image
                        self.icon.cornerRadius = self.icon.frame.height / 2
                    }
                
                } else {
                    DispatchQueue.main.async {
                        self.icon.image = item.icon
                    }
                }
            }
        
        } else {
            icon.image = item.icon
        }
        
        title.text  = item.title
        desc.text   = item.desc
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "HH:mm") : dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM")
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imagePressed(_:)))
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(tap)
        
        if item.imgUrl != nil {
            
            if imgs.keys.contains(item.id) {
                self.image.image = imgs[item.id]
                
            } else {
                
                imageLoader.isHidden = false
                imageLoader.startAnimating()
                DispatchQueue.global(qos: .userInitiated).async {
                    
                    var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + item.imgUrl!)!)
                    request.httpMethod = "GET"
                    
                    let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
                    
                    if data != nil {
                        DispatchQueue.main.async {
                            let imgDt = UIImage(data: data!)
                            imgs[item.id] = imgDt
                            self.image.image = imgDt
                            self.imageLoader.stopAnimating()
                            self.imageLoader.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    @objc private func imagePressed(_ sender: UITapGestureRecognizer) {
        delegate?.imagePressed(sender)
    }
    
    class func fromNib() -> ServiceCommentCell? {
        var cell: ServiceCommentCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServiceCommentCell {
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






