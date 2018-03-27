//
//  TechServiceVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/24/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

private protocol TechServiceProtocol: class { }

final class TechServiceVC: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var commentField:    UITextField!
    @IBOutlet private weak var sendBtn:         UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        if isCreate_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 4], animated: true)
        
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
        
        if img == nil {
            sendComment()
            
        } else {
            uploadPhoto(img!)
        }
        let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
        arr.append( ServiceCommentCellData(icon: UIImage(named: "account")!, title: accountName, desc: commentField.text!, date: "Сейчас", image: img)  )
        img = nil
        collection.reloadData()
        commentField.text = ""
        commentField.placeholder = "Сообщение"
        view.endEditing(true)
        
        // Подождем пока закроется клавиатура
        DispatchQueue.global(qos: .userInteractive).async {
            usleep(900000)
            
            DispatchQueue.main.async {
                self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                self.endAnimator()
            }
        }
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = true
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
    
    open var reqId_    = ""
    open var isCreate_ = false
    open var data_: ServiceHeaderData = ServiceHeaderData(icon: UIImage(named: "account")!,
                                                          problem: "Нас топят соседи! Не можем с ними связаться. Срочно вызвайте сантехника",
                                                          date: "9 сентября 10:00",
                                                          status: "В ОБРАБОТКЕ",
                                                          images: [UIImage(named: "account")!, UIImage(named: "account")!, UIImage(named: "account")!])
    
    open var comments_: [ServiceCommentCellData] = []
    private var arr:    [TechServiceProtocol]    = []
    private var img:    UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        arr = comments_
        arr.insert(data_, at: 0)
        
        collection.delegate     = self
        collection.dataSource   = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
        view.frame.origin.y = -250
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.frame.origin.y = 0
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
            cell.display(arr[indexPath.row] as! ServiceHeaderData)
            return cell
        
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceCommentCell", for: indexPath) as! ServiceCommentCell
            cell.display(arr[indexPath.row] as! ServiceCommentCellData)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 {
            if (arr[indexPath.row] as! ServiceHeaderData).images.count == 0 && (arr[indexPath.row] as! ServiceHeaderData).imgsString.count == 0 {
                return CGSize(width: view.frame.size.width, height: 200.0)
                
            } else {
                return CGSize(width: view.frame.size.width, height: 350.0)
            }
        
        } else {
            return CGSize(width: view.frame.size.width, height: 120.0)
        }
    }
    
    private func sendComment() {
        
        var group = DispatchGroup()
        let comm = commentField.text!.stringByAddingPercentEncodingForRFC3986()
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_COMM + "reqID=" + reqId_ + "text=" + comm!)!)
        request.httpMethod = "GET"
        
        group.enter()
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                group.leave()
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8))
            #endif
            
        }.resume()
        group.wait()
    }
    
    private func uploadPhoto(_ img: UIImage) {
        
        let group = DispatchGroup()
        group.enter()
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ADD_FILE + "reqID=" + reqId_ + "&accID" + UserDefaults.standard.string(forKey: "id_account")!)!)
        request.httpMethod = "POST"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        request.setValue("multipart/form-data;boundary=----WebKitFormBoundary9xFB2hiUhzqbBQ4M", forHTTPHeaderField: "Content-Type")
        
        let header = "------WebKitFormBoundary9xFB2hiUhzqbBQ4M\r\nContent-Disposition: form-data; name=\"" +
            "file_name" + "\"; filename=\"" + "file_name" + "\\r\nContent-Type: image/png\r\n"
        let imgData = UIImagePNGRepresentation(img)
        let headerEnd = "\r\n------WebKitFormBoundary9xFB2hiUhzqbBQ4M--\r\n"
        
        request.httpBody = header.data(using: .utf8)! + imgData! + headerEnd.data(using: .utf8)!
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                group.leave()
            }
            
            #if DEBUG
//                print(String(data: data!, encoding: .utf8)!)
            #endif
            }.resume()
        group.wait()
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
}

final class ServiceHeader: UICollectionViewCell {
    
    @IBOutlet private weak var imageLoader: UIActivityIndicatorView!
    @IBOutlet private weak var imageConst:  NSLayoutConstraint!
    @IBOutlet private weak var problem:     UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var status:      UILabel!
    
    fileprivate func display(_ item: ServiceHeaderData) {
        
        imageLoader.isHidden = true
        imageLoader.stopAnimating()
        
        problem.text = item.problem
        date.text = item.date
        icon.image = item.icon
        status.text = item.status
        
        if item.images.count == 0 {
            imageConst.constant = 30
            scroll.isHidden = true
        
        } else {
            imageConst.constant = 186
            scroll.isHidden = false
        }
        
        if item.imgsString.count == 0 {
            
            var x = 0.0
            item.images.forEach {
                let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: scroll.frame.size.height))
                image.image = $0
                x += 165.0
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
                    
                    rowImgs.append(UIImage(data: data!)!)
                }
                
                DispatchQueue.main.async {
                    var x = 0.0
                    rowImgs.forEach {
                        let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: self.scroll.frame.size.height))
                        image.image = $0
                        x += 165.0
                        self.scroll.addSubview(image)
                    }
                    self.scroll.contentSize = CGSize(width: CGFloat(x), height: self.scroll.frame.size.height)
                    self.imageLoader.isHidden = true
                    self.imageLoader.stopAnimating()
                }
            }
        }
    }
}

final class ServiceHeaderData: TechServiceProtocol {
    
    let icon:       UIImage
    let problem:    String
    let date:       String
    let status:     String
    let images:     [UIImage]
    let imgsString: [String]
    
    init(icon: UIImage, problem: String, date: String, status: String, images: [UIImage] = [], imagesUrl: [String] = []) {
        
        self.icon       = icon
        self.problem    = problem
        self.date       = date
        self.status     = status
        self.images     = images
        self.imgsString = imagesUrl
    }
}

final class ServiceCommentCell: UICollectionViewCell {
    
    @IBOutlet private weak var imageLoader: UIActivityIndicatorView!
    @IBOutlet private weak var image:       UIImageView!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var title:   	UILabel!
    @IBOutlet private weak var desc:        UILabel!
    @IBOutlet private weak var date:    	UILabel!
    
    fileprivate func display(_ item: ServiceCommentCellData) {
        
        imageLoader.isHidden = true
        imageLoader.stopAnimating()
        
        if item.image != nil || item.imgUrl != nil {
            image.image     = item.image
            image.isHidden  = false
            desc.isHidden   = true
        
        } else {
            image.isHidden  = true
            desc.isHidden   = false
        }
        
        icon.image  = item.icon
        title.text  = item.title
        desc.text   = item.desc
        date.text   = item.date
        
        if item.imgUrl != nil {
            
            imageLoader.isHidden = false
            imageLoader.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async {
                
                var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + item.imgUrl!)!)
                request.httpMethod = "GET"
                
                let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
                
                DispatchQueue.main.async {
                    self.image.image = UIImage(data: data!)
                    self.imageLoader.stopAnimating()
                    self.imageLoader.isHidden = true
                }
            }
        }
    }
}

final class ServiceCommentCellData: TechServiceProtocol {
    
    let image:  UIImage?
    let icon:   UIImage
    let title:  String
    let desc:   String
    let date:   String
    let imgUrl: String?
    
    init(icon: UIImage, title: String, desc: String, date: String, image: UIImage? = nil, imageUrl: String? = nil) {
        
        self.icon   = icon
        self.title  = title
        self.desc   = desc
        self.date   = date
        self.image  = image
        self.imgUrl = imageUrl
    }
}






