//
//  AppealVC.swift
//  Sminex
//
//  Created by Sergey Ivanov on 22/07/2019.
//

import UIKit
import Alamofire
import SwiftyXMLParser

private protocol AppealProtocol: class {}
private var mainScreenXml:  XML.Accessor?
private protocol AppealCellsProtocol: class {
    func imageTapped(_ sender: UITapGestureRecognizer)
}

class AppealVC: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AppealCellsProtocol {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var commentField:    UITextField!
    @IBOutlet private weak var sendBtn:         UIButton!
    @IBOutlet private weak var cameraButton:    UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        imgs = [:]
        if isFromMain_ {
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
            uploadPhoto(img!, isSplit: true)
            return
            
        } else if img == nil && commentField.text != "" {
            sendComment()
        } else if img != nil && commentField.text == "" {
            uploadPhoto(img!)
        }
    }
    
    public var name_: String?
    public var delegate:   AppealUserDelegate?
    public var reqId_      = ""
    public var isFromMain_ = false
    public var data_: AppealHeaderData = AppealHeaderData(title: "Консьержу", mobileNumber: "89246785645", ident: "1478", email: "test@test.ru", desc: "Описание")
    public var comments_: [AppealCommentCellData] = []
    
    private var arr: [AppealProtocol] = []
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
            
            let cell = AppealHeader.fromNib()
            cell?.display((arr[0] as! AppealHeaderData), delegate: self, delegate1: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width, height: size.height)
            
        } else {
            let cell = AppealCommentCell.fromNib()
            cell?.display((arr[indexPath.row] as! AppealCommentCellData), delegate: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            let ar = arr[indexPath.row] as! AppealCommentCellData
            if ar.comment == "Прикреплено фото" || ar.comment == "Добавлен файл"{
                return CGSize(width: view.frame.size.width, height: 0)
            }
            return CGSize(width: view.frame.size.width, height: size.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppealHeader", for: indexPath) as! AppealHeader
            cell.display((arr[0] as! AppealHeaderData), delegate: self, delegate1: self)
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AppealCommentCell", for: indexPath) as! AppealCommentCell
            cell.display((arr[indexPath.row] as! AppealCommentCellData), delegate: self)
            return cell
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
                        self.arr.append( AppealCommentCellData(image: UIImage(named: "account")!, title: row.attributes["Name"]!, comment: row.attributes["text"]!, date: row.attributes["CreatedDate"]!, id: row.attributes["ID"]!))
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
                self.arr.append( AppealCommentCellData(image: UIImage(named: "account")!, title: accountName, comment: self.commentField.text!, date: dateFormatter.string(from: Date()),commImg: self.img, id: UUID().uuidString)  )
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
                    self.arr.append( AppealCommentCellData(image: UIImage(named: "account")!, title: accountName, comment: self.commentField.text!, date: dateFormatter.string(from: Date()),commImg: img, id: uid)  )
                    
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

final class AppealHeader: UICollectionViewCell {
    
    //@IBOutlet private weak var descHeight:      NSLayoutConstraint!
    @IBOutlet private weak var mobileNumber:    UILabel!
    @IBOutlet private weak var descText:        UILabel?
    @IBOutlet private weak var descTitle:       UILabel?
    @IBOutlet private weak var email:           UILabel?
    @IBOutlet private weak var ident:           UILabel?
    
    private var delegate: AppealCellsProtocol?
    private var delegate1: AppealVC?
    
    fileprivate func display(_ item: AppealHeaderData, delegate: AppealCellsProtocol, delegate1: AppealVC) {
        print(item)
        
        self.delegate = delegate
        self.delegate1 = delegate1
        descText?.text = item.desc
        descTitle?.text = item.title
        if item.email.contains(find: "@"){
            email?.text = item.email
        }else{
            email?.text = "-"
        }
        if item.mobileNumber != "" || item.mobileNumber != "-" || item.mobileNumber != " "{
            mobileNumber?.text = item.mobileNumber
        }else{
            mobileNumber?.text = "-"
        }
        ident?.text = item.ident
        //descHeight?.constant = heightForTitle(text: item.desc, width: self.delegate1!.view.frame.size.width)
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
    
    class func fromNib() -> AppealHeader? {
        var cell: AppealHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AppealHeader {
                cell = view
            }
        }
        return cell
    }
}

final class AppealHeaderData: AppealProtocol {
    
    let title:          String
    let mobileNumber:   String
    let desc:           String
    let email:          String
    let ident:          String
    
    init(title: String, mobileNumber: String, ident: String, email: String, desc: String) {
        
        self.title          = title
        self.mobileNumber   = mobileNumber
        self.ident          = ident
        self.email          = email
        self.desc           = desc
    }
}


final class AppealCommentCell: UICollectionViewCell {
    
    @IBOutlet private weak var imgsLoader:  UIActivityIndicatorView!
    @IBOutlet private      var imgsConst:   NSLayoutConstraint!
    @IBOutlet private      var commConst:   NSLayoutConstraint!
    @IBOutlet private weak var comImg:      UIImageView!
    @IBOutlet private weak var image:       UIImageView!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var comment:     UILabel!
    @IBOutlet private weak var date:        UILabel!
    
    private var delegate: AppealCellsProtocol?
    
    fileprivate func display(_ item: AppealCommentCellData, delegate: AppealCellsProtocol) {
        
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.img != nil || item.imgUrl != nil {
            comment.isHidden   = true
            comImg.isHidden    = false
            comImg.image       = item.img
            imgsConst.isActive = false
            commConst.isActive = true
            
        } else {
            comment.isHidden = false
            comImg.isHidden  = true
            imgsConst.isActive = true
            commConst.isActive = false
        }
        
        if item.title == UserDefaults.standard.string(forKey: "name") ?? "" {
            DispatchQueue.global(qos: .background).async {
                if let imageData = UserDefaults.standard.object(forKey: "accountIcon"),
                    let image = UIImage.init(data: imageData as! Data) {
                    DispatchQueue.main.async {
                        self.image.image = image
                        self.image.cornerRadius = self.image.frame.height / 2
                    }
                    
                } else {
                    DispatchQueue.main.async {
                        self.image.image = item.image
                    }
                }
            }
            
        } else {
            image.image = item.image
        }
        
        title.text      = item.title
        comment.text    = item.comment
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "HH:mm"): dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM")
        
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
        DispatchQueue.main.async {
            if item.title == "Примечание"{
                self.image.isHidden = true
            }else{
                self.image.isHidden = false
            }
        }
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.imageTapped(sender)
    }
    
    class func fromNib() -> AppealCommentCell? {
        var cell: AppealCommentCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AppealCommentCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth   = cell?.title.bounds.size.width   ?? 0.0
        cell?.comment.preferredMaxLayoutWidth = cell?.comment.bounds.size.width ?? 0.0
        return cell
    }
}

final class AppealCommentCellData: AppealProtocol {
    
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
