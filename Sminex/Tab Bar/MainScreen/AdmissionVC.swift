//
//  AdmissionVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

private protocol AdmissionProtocol: class {}
private protocol AdmissionCellsProtocol: class {
    func imageTapped(_ sender: UITapGestureRecognizer)
}

final class AdmissionVC: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AdmissionCellsProtocol {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var commentField:    UITextField!
    @IBOutlet private weak var sendBtn:         UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        if isCreated_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 4], animated: true)
        
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
    
    @IBAction private func sendButtonPressed(_ sender: UIButton?) {
        
        if img == nil {
            if commentField.text == ""
                || commentField.text == nil {
                commentField.placeholder = "Введите сообщение!"
                return
            }
        }
        
        startAnimating()
        if img == nil {
            sendComment()
            
        } else {
            uploadPhoto(img!)
        }
        
        let accountName = UserDefaults.standard.string(forKey: "name") ?? ""
        arr.append( AdmissionCommentCellData(image: UIImage(named: "account")!, title: accountName, comment: commentField.text!, date: "Сейчас",commImg: img)  )
        collection.reloadData()
        img = nil
        commentField.text = ""
        commentField.placeholder = "Сообщение"
        view.endEditing(true)
        delegate?.update()
        
        // Подождем пока закроется клваиатура
        DispatchQueue.global(qos: .userInteractive).async {
            usleep(900000)
            
            DispatchQueue.main.async {
                self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                self.endAnimating()
            }
        }
    }
    
    open var delegate: AppsUserDelegate?
    open var reqId_     = ""
    open var isCreated_ = false
    open var data_: AdmissionHeaderData = AdmissionHeaderData(icon: UIImage(named: "account")!,
                                                                gosti: "А. Е. Филимонов, В. В. Иванова",
                                                                mobileNumber: "+7 965 913 95 67",
                                                                gosNumber: "А 033 ЕО 777",
                                                                date: "9 Сентября 10:00",
                                                                status: "В ОБРАБОТКЕ",
                                                                images: [],
                                                                imagesUrl: [])
    open var comments_: [AdmissionCommentCellData] = []
    
    private var arr: [AdmissionProtocol] = []
    private var img: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endAnimating()
        automaticallyAdjustsScrollViewInsets = false
        
        arr = comments_
        arr.insert(data_, at: 0)
        
        commentField.delegate                   = self
        collection.delegate                     = self
        collection.dataSource                   = self
        automaticallyAdjustsScrollViewInsets    = false
        
        let reconizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        reconizer.delegate              = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(reconizer)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden    = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden    = false
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 {
            
            if (arr[0] as! AdmissionHeaderData).gosNumber != "" {
                if (arr[0] as! AdmissionHeaderData).images.count == 0 || (arr[0] as! AdmissionHeaderData).imgsUrl.count == 0 {
                    return CGSize(width: view.frame.size.width, height: 290.0)
                
                } else {
                    return CGSize(width: view.frame.size.width, height: 420.0)
                }
                
            } else {
                
                if (arr[0] as! AdmissionHeaderData).images.count == 0 && (arr[0] as! AdmissionHeaderData).imgsUrl.count == 0 {
                    return CGSize(width: view.frame.size.width, height: 230.0)
                    
                } else {
                    return CGSize(width: view.frame.size.width, height: 360.0)
                }
            }
        
        } else {
            return CGSize(width: view.frame.size.width, height: 100.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdmissionHeader", for: indexPath) as! AdmissionHeader
            cell.display((arr[0] as! AdmissionHeaderData), delegate: self)
            return cell
        
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AdmissionCommentCell", for: indexPath) as! AdmissionCommentCell
            cell.display((arr[indexPath.row] as! AdmissionCommentCellData), delegate: self)
            return cell
        }
    }
    
    private func sendComment() {
        
        let group = DispatchGroup()
        let comm = commentField.text!.stringByAddingPercentEncodingForRFC3986()
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_COMM + "reqID=" + reqId_ + "&text=" + comm!)!)
        request.httpMethod = "GET"
        
        group.enter()
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                group.leave()
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8)!)
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
                print(String(data: data!, encoding: .utf8)!)
            #endif
            }.resume()
        group.wait()
        return
    }
    
    private func startAnimating() {
        sendBtn.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimating() {
        sendBtn.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
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
        
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage(_:)))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
    }
}


final class AdmissionHeader: UICollectionViewCell {
    
    @IBOutlet private weak var imgsLoader:      UIActivityIndicatorView!
    @IBOutlet private weak var imgsConst:       NSLayoutConstraint!
    @IBOutlet private weak var gosConst:        NSLayoutConstraint!
    @IBOutlet private weak var imgs:            UIScrollView!
    @IBOutlet private weak var image:           UIImageView!
    @IBOutlet private weak var gosti:           UILabel!
    @IBOutlet private weak var mobileNumber:    UILabel!
    @IBOutlet private weak var gosNumbers:      UILabel!
    @IBOutlet private weak var gosTitle:        UILabel!
    @IBOutlet private weak var gosLine:         UILabel!
    @IBOutlet private weak var date:            UILabel!
    @IBOutlet private weak var status:          UILabel!
    
    private var delegate: AdmissionCellsProtocol?
    
    fileprivate func display(_ item: AdmissionHeaderData, delegate: AdmissionCellsProtocol) {
        
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.gosNumber == "" {
            gosConst.constant   = 8
            gosNumbers.isHidden = true
            gosLine.isHidden    = true
            gosTitle.isHidden   = true
        
        } else {
            gosConst.constant   = 65
            gosNumbers.isHidden = false
            gosLine.isHidden    = false
            gosTitle.isHidden   = false
        }
        
        image.image         = item.icons
        gosti.text          = item.gosti
        mobileNumber.text   = item.mobileNumber
        gosNumbers.text     = item.gosNumber
        date.text           = item.date
        status.text         = item.status
        
        if item.images.count == 0 && item.imgsUrl.count == 0 {
            imgs.isHidden       = true
            imgsConst.constant  = 8
        
        } else if item.images.count != 0 {
            imgs.isHidden       = false
            imgsConst.constant  = 170
            
            var x = 0.0
            item.images.forEach {
                let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: imgs.frame.size.height))
                image.image = $0
                x += 165.0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                image.isUserInteractionEnabled = true
                image.addGestureRecognizer(tap)
                imgs.addSubview(image)
            }
            imgs.contentSize = CGSize(width: CGFloat(x), height: imgs.frame.size.height)
        
        } else if item.imgsUrl.count != 0 {
            
            imgsLoader.isHidden = false
            imgsLoader.startAnimating()
            
            var rowImgs: [UIImage] = []
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                item.imgsUrl.forEach { img in
                    
                    var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + img)!)
                    request.httpMethod = "GET"
                    
                    let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
                    
                    rowImgs.append(UIImage(data: data!)!)
                }
                
                DispatchQueue.main.async {
                    var x = 0.0
                    rowImgs.forEach {
                        let image = UIImageView(frame: CGRect(x: CGFloat(x), y: 0, width: CGFloat(150.0), height: self.imgs.frame.size.height))
                        image.image = $0
                        x += 165.0
                        let tap = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(_:)))
                        image.isUserInteractionEnabled = true
                        image.addGestureRecognizer(tap)
                        self.imgs.addSubview(image)
                    }
                    self.imgs.contentSize = CGSize(width: CGFloat(x), height: self.imgs.frame.size.height)
                    self.imgsLoader.stopAnimating()
                    self.imgsLoader.isHidden = true
                }
            }
        }
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.imageTapped(sender)
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
    let status:         String
    
    init(icon: UIImage, gosti: String, mobileNumber: String, gosNumber: String, date: String, status: String, images: [UIImage], imagesUrl: [String]) {
        
        self.icons          = icon
        self.gosti          = gosti
        self.mobileNumber   = mobileNumber
        self.gosNumber      = gosNumber
        self.date           = date
        self.status         = status
        self.images         = images
        self.imgsUrl        = imagesUrl
    }
}


final class AdmissionCommentCell: UICollectionViewCell {
    
    @IBOutlet private weak var imgsLoader:  UIActivityIndicatorView!
    @IBOutlet private weak var comImg:      UIImageView!
    @IBOutlet private weak var image:       UIImageView!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var comment: 	UILabel!
    @IBOutlet private weak var date:        UILabel!
    
    private var delegate: AdmissionCellsProtocol?
    
    fileprivate func display(_ item: AdmissionCommentCellData, delegate: AdmissionCellsProtocol) {
        
        self.delegate = delegate
        imgsLoader.isHidden = true
        imgsLoader.stopAnimating()
        
        if item.img != nil || item.imgUrl != nil {
            comment.isHidden = true
            comImg.isHidden  = false
            comImg.image     = item.img
        
        } else {
            comment.isHidden = false
            comImg.isHidden  = true
        }
        
        image.image     = item.image
        title.text      = item.title
        comment.text    = item.comment
        date.text       = item.date
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        image.isUserInteractionEnabled = true
        image.addGestureRecognizer(tap)
        
        if item.imgUrl != nil {
            imgsLoader.isHidden = false
            imgsLoader.startAnimating()
            
            DispatchQueue.global(qos: .userInitiated).async {
                
                var request = URLRequest(url: URL(string: Server.SERVER + Server.DOWNLOAD_PIC + "id=" + item.imgUrl!)!)
                request.httpMethod = "GET"
                
                let (data, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
                
                DispatchQueue.main.async {
                    self.image.image = UIImage(data: data!)
                    self.imgsLoader.isHidden = true
                    self.imgsLoader.stopAnimating()
                }
            }
        }
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        delegate?.imageTapped(sender)
    }
    
}

final class AdmissionCommentCellData: AdmissionProtocol {
    
    let img:        UIImage?
    let image:      UIImage
    let title:      String
    let comment:    String
    let date:       String
    let imgUrl:     String?
    
    init(image: UIImage, title: String, comment: String, date: String, commImg: UIImage? = nil, commImgUrl: String? = nil) {
        
        self.img        = commImg
        self.image      = image
        self.title      = title
        self.comment    = comment
        self.date       = date
        self.imgUrl     = commImgUrl
    }
}







