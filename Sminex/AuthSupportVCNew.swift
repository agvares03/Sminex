//
//  AuthSupportVCNew.swift
//  Sminex
//
//  Created by Sergey Ivanov on 14/02/2020.
//

import UIKit
import DeviceKit
import Alamofire
import AKMaskField

final class AuthSupportVCNew: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
//    @IBOutlet private weak var loader:              UIActivityIndicatorView!
//    @IBOutlet private weak var sendButtonBottom:    NSLayoutConstraint!
    @IBOutlet private weak var imgsHeight:       NSLayoutConstraint!
    @IBOutlet private weak var sendButtonHeight:     NSLayoutConstraint!
    @IBOutlet private weak var problemHeight:       NSLayoutConstraint!
    @IBOutlet private weak var problemLbl:          UILabel!
//    @IBOutlet private weak var sendView:            UIView!
//    @IBOutlet private weak var scroll:              UIScrollView!
    @IBOutlet private weak var imgsScroll:          UIScrollView!
    @IBOutlet private weak var problemTextView:     UITextField!
    @IBOutlet private weak var emailTextView:       AKMaskField!
    @IBOutlet private weak var lsTextView:          UITextField!
    @IBOutlet private weak var sendButton:          UIButton!
    
    private var reqId: String?
    private var boundary: String?
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        view.endEditing(true)
        UserDefaults.standard.set(false, forKey: "fromMenu")
        let alert = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "Отмена", style: .default, handler: { (_) in } ) )
        alert.addAction( UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in
            self.navigationController?.popViewController(animated: true) } ) )
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        view.endEditing(true)
        startAnimation()
        sendInfoMessage()
    }
    
    @IBAction private func imgsButtonPressed(_ sender: UIButton) {
        
        view.endEditing(true)
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
    
    public var login_ = ""
    public var fromMenu = false
    private var imgs: [UIImage] = [] {
        didSet {
            if imgs.count == 0 {
                imgsHeight.constant = 1
//                sendButtonTop.constant = getPoint()
//
//                if isNeedToScrollMore() && tabBarController != nil {
//                    sendButtonTop.constant = getPoint() + 99
//                }

            } else {
                imgsHeight.constant = 150
//                sendButtonTop.constant = getPoint() - 150
//
//                if isNeedToScrollMore() && tabBarController != nil {
//                    sendButtonTop.constant = getPoint() - 100
//                }
            }
            drawImages()
        }
    }
    private var currPoint: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = navigationGrayColor
        if UserDefaults.standard.bool(forKey: "fromMenu"){
            login_ = UserDefaults.standard.string(forKey: "login") ?? ""
            lsTextView.isEnabled = false
            lsTextView.textColor = .lightGray
        }
        if login_ != "" {
            self.lsTextView.text = login_
        }
        emailTextView.maskExpression = "+7 ({ddd}) {ddd}-{dddd}"
        emailTextView.maskTemplate = "*"
        var contactPhone: String = UserDefaults.standard.string(forKey: "phone_user") ?? ""
        if contactPhone.first == "8"{
            contactPhone.removeFirst()
        }
        emailTextView.text = contactPhone
//        loader.isHidden = true
//        if Device().isOneOf([.iPhone5, .iPhone5s, .iPhone5c, .iPhoneSE, .simulator(.iPhoneSE)]){
//            currPoint = sendView.frame.origin.y - 200
//            sendButtonWidth.constant = sendButtonWidth.constant - 50
//        }
        problemLbl.isHidden = true
        problemHeight.constant = 0
        sendButton.isHidden = true
        sendButtonHeight.constant = 0
//        currPoint = sendView.frame.origin.y
//        sendButton.isEnabled = false
//        sendButton.alpha     = 0.5
        imgsHeight.constant  = 1
        
        automaticallyAdjustsScrollViewInsets = false
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        problemTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        emailTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lsTextView.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
//        sendButtonTop.constant = getPoint()
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.updateUserInterface()
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
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == problemTextView{
            if problemTextView.text == ""{
                problemLbl.isHidden = true
                problemHeight.constant = 0
            }else{
                problemLbl.isHidden = false
                problemHeight.constant = 24
            }
        }
        if problemTextView.text == "" || emailTextView.text == "" {
            sendButton.isHidden = true
            sendButtonHeight.constant = 0
        } else {
            sendButton.isHidden = false
            sendButtonHeight.constant = 48
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
//    @objc func keyboardWillShow(sender: NSNotification?) {
//        scroll.contentSize.height += 200
//
//        if !isNeedToScroll() {
//            if Device().isOneOf([.iPhone6, .iPhone6s, .iPhone7, .iPhone8, .simulator(.iPhone6), .simulator(.iPhone6s)]){
//                sendButtonTop.constant = getPoint() - 210
//                return
//
//            }else if isPlusDevices(){
//                sendButtonTop.constant = getPoint() - 220
//                return
//            }else {
//                sendButtonTop.constant = getPoint() - 250
//            }
//
//        } else {
//
//            if !isNeedToScrollMore() {
//
////                if imgs.count == 0 {
//                    if tabBarController == nil {
////                        sendButtonTop.constant    = -30
////                        sendButtonBottom.constant = 210
//                        sendButtonTop.constant = getPoint() - 205
//                    } else {
//                        sendButtonTop.constant = getPoint() - 205
//                    }
//
////                } else {
////                    if tabBarController == nil {
//////                        sendButtonBottom.constant += 80
//////                        sendButtonTop.constant    -= 80
////                        sendButtonTop.constant  = getPoint() - 210 - 150
////
////                    } else {
//////                        sendButtonBottom.constant = 300
////                        sendButtonTop.constant  = getPoint() - 210 - 150
////                    }
////                }
//
//            } else {
//
////                if imgs.count == 0 {
//                    if tabBarController == nil {
////                        sendButtonTop.constant    = getPoint() - 120
////                        sendButtonBottom.constant = getPoint() + 70
//                        sendButtonTop.constant    = getPoint() - 100
//                        sendButtonBottom.constant = getPoint() + 50
//                    } else {
//                        sendButtonTop.constant    = getPoint() - 100
//                        sendButtonBottom.constant = getPoint() + 50
//                    }
//
////                } else {
////                    if tabBarController == nil {
////                        sendButtonBottom.constant = getPoint() + 100
////
////                    } else {
////                        sendButtonBottom.constant = getPoint() + 100
////                    }
////                }
//            }
//        }
//    }
    
    // И вниз при исчезновении
//    @objc func keyboardWillHide(sender: NSNotification?) {
//
//        scroll.contentSize.height -= 200
//
//        if Device().isOneOf([.iPhone6, .iPhone6s, .iPhone7, .iPhone8, .simulator(.iPhone6), .simulator(.iPhone6s)]){
////            sendButtonBottom.constant = 16
////            sendButtonTop.constant    = getPoint() - 150
//            sendButtonTop.constant = getPoint()
//            return
//        }
//        if isPlusDevices(){
//            sendButtonTop.constant = getPoint()
//            return
//        }
//        if !isNeedToScroll() {
//            sendButtonTop.constant = getPoint()
//
//        } else {
//            if !isNeedToScrollMore() {
////                if imgs.count == 0 {
//                    sendButtonTop.constant = getPoint()
//
////                } else {
////                    sendButtonBottom.constant = 16
////
////                    if tabBarController == nil {
//////                        sendButtonTop.constant    = getPoint() - 210
////                        sendButtonTop.constant    = getPoint() - 150
////
////                    } else {
////                        sendButtonTop.constant    = getPoint() - 150
////                    }
////                }
//            } else {
//                sendButtonBottom.constant = 16
////                if imgs.count == 0 {
//                    sendButtonTop.constant = getPoint()
////                }
//            }
//        }
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.isHidden = true
        navigationController?.isNavigationBarHidden = false
        
        // Подхватываем показ клавиатуры
//        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = true
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    private func getPoint() -> CGFloat {
        if Device().isOneOf([.iPhone5, .iPhone5s, .iPhone5c, .iPhoneSE, .simulator(.iPhoneSE)]){
            return currPoint - 210 - 50 - 50
        }else if isPlusDevices(){
            return currPoint - 210 + 70
        } else if Device() != .iPhoneX && Device() != .simulator(.iPhoneX) {
            if tabBarController == nil {
                return currPoint - 210
            } else {
                print(view.frame.size.height, currPoint, currPoint - 210)
                return currPoint - 210
            }
        }else {
            if tabBarController == nil {
                return currPoint - 210 + 85
            } else {
                return currPoint - 210 + 85
            }
        }
    }
    
    private func drawImages() {

        imgsScroll.subviews.forEach {
            $0.removeFromSuperview()
        }
        var x = 0.0
        var tag = 0

        imgs.forEach {
            let img = UIImageView(frame: CGRect(x: x, y: 0.0, width: 150.0, height: 150.0))
            img.image = $0
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            img.isUserInteractionEnabled = true
            img.addGestureRecognizer(tap)
            imgsScroll.addSubview(img)

            let deleteButton = UIButton(frame: CGRect(x: x + 130.0, y: 0.0, width: 20.0, height: 20.0))
            deleteButton.backgroundColor = .white
            deleteButton.cornerRadius = 0.5 * deleteButton.bounds.size.width
            deleteButton.clipsToBounds = true
            deleteButton.tag = tag
            deleteButton.alpha = 0.7
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            imgsScroll.addSubview(deleteButton)

            let image = UIImageView(frame: CGRect(x: x + 135.0, y: 5.0, width: 10.0, height: 10.0))
            image.image = UIImage(named: "rossNavbar")
            imgsScroll.addSubview(image)

            x += 160
            tag += 1
        }
        imgsScroll.contentSize = CGSize(width: CGFloat(x), height: imgsScroll.frame.size.height)
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        imgs.remove(at: sender.tag)
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        
        view.endEditing(true)
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
    
    private func sendInfoMessage() {
        
        let login = lsTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let text  = problemTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        var email = ""
        var phone = ""
        if (emailTextView.text?.contains(find: "@"))!{
            email = emailTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        }else{
            phone = emailTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        }
        phone = phone.replacingOccurrences(of: "%2B", with: "+")
        
        let url = "login=\(login)&text=\(text)&phone=\(phone)&mail=\(email)"
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ADD_TECH_SUPPORT + url)!)
        request.httpMethod = "POST"
        print(request)

        let task = URLSession.shared.dataTask(with: request) {
            data, error, responce in
            let response = String(data: data!, encoding: .utf8) ?? ""
            print(response)
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                self.stopAnimation()
                return
            }
            self.reqId = response
            self.imgs.forEach{
                self.uploadPhoto($0)
            }
            self.sendMessage()
        }
        task.resume()
    }
    
//    private func sendMessage() {
//
//        let login = lsTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
//        let text  = problemTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
//        var email = emailTextView.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
//        email = email.replacingOccurrences(of: "%2B", with: "+")
//
//        let url = "login=\(login)&text=\(text)&phone=\(email)"
//        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_MESSAGE + url)!)
//        request.httpMethod = "POST"
//        let encodedData = NSKeyedArchiver.archivedData(withRootObject: imgs.map { UIImageJPEGRepresentation($0, 0.5) } )
//
//        Alamofire.upload(encodedData, to: URL(string: Server.SERVER + Server.SEND_MESSAGE + url)!, method: .post, headers: nil).response { response in
//            if response.response?.statusCode == 200 {
//                let alert = UIAlertController(title: "Спасибо!", message: "Сообщение отправлено в техподдержку приложения", preferredStyle: .alert)
//                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in self.navigationController?.popViewController(animated: true) } ) )
//                self.present(alert, animated: true, completion: nil)
//
//                debugPrint(response)
//            } else {
//
//                self.showAlert(message: response.response?.description ?? "", title: "Ошибка сервера")
//            }
//        }
//    }
    
    private func uploadPhoto(_ img: UIImage) {
        let group = DispatchGroup()
        let reqID = reqId?.stringByAddingPercentEncodingForRFC3986()
        
        group.enter()
        let uid = UUID().uuidString
//        print(uid)
//        print(Server.SERVER + Server.ADD_SUPPORT_FILE + "mailId=" + reqID!)
        
        Alamofire.upload(multipartFormData: { multipartFromdata in
            multipartFromdata.append(UIImageJPEGRepresentation(img, 0.5)!, withName: uid, fileName: "\(uid).jpg", mimeType: "image/jpeg")
        }, to: Server.SERVER + Server.ADD_SUPPORT_FILE + "mailId=" + reqID!) { (result) in
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
//                    print("Upload Progress: \(progress.fractionCompleted)")
                })
//                print("====")
                upload.responseJSON { response in
//                    print(response.result.value!)

                    group.leave()
                    
                }
                
            case .failure(let encodingError):
                print("UPLOAD ERROR: ", encodingError)
            }
        }
        group.wait()
        return
    }
    
    private func sendMessage() {
        let reqID = reqId?.stringByAddingPercentEncodingForRFC3986()
        
        let url = "mailId=" + "\(reqID!)"
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SEND_MAIL + url)!)
        request.httpMethod = "POST"
        print(request)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, error, responce in
            let response = String(data: data!, encoding: .utf8) ?? ""
            print(response)
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                DispatchQueue.main.async{
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                    DispatchQueue.main.async {
                        self.present(alert, animated: true, completion: nil)
                    }
                    self.stopAnimation()
                }
                return
            }
            DispatchQueue.main.async{
                self.stopAnimation()
                let alert = UIAlertController(title: "Спасибо!", message: "Сообщение отправлено в техподдержку приложения", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in self.navigationController?.popViewController(animated: true) } ) )
                self.present(alert, animated: true, completion: nil)
            }
        }
        task.resume()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imgs.append(image)
        dismiss(animated: true, completion: nil)
    }
    
    private func startAnimation() {
        sendButton.alpha = 0
//        loader.isHidden  = false
//        loader.startAnimating()
    }

    private func stopAnimation() {
//        loader.stopAnimating()
//        loader.isHidden  = true
        sendButton.alpha = 1
    }
}
