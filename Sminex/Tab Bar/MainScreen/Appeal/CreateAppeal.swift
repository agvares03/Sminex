//
//  CreateAppeal.swift
//  Sminex
//
//  Created by Sergey Ivanov on 22/07/2019.
//

import UIKit
import Alamofire
import DeviceKit
import AKMaskField

class CreateAppeal: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var sendBtnHeight:   NSLayoutConstraint!
    @IBOutlet private weak var imgsHeight:      NSLayoutConstraint!
    @IBOutlet private weak var edConst:         NSLayoutConstraint!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var imgScroll:       UIScrollView!
    @IBOutlet private weak var edContact:       AKMaskField!
    @IBOutlet private weak var edEmail:         UITextField!
    @IBOutlet private weak var edIdent:         UITextField!
    @IBOutlet private weak var TypeRequest:     UILabel!
    @IBOutlet private weak var edComment:       UITextView!
    @IBOutlet private weak var sendButton:      UIButton!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    public var typeReq = ""
    public var selEmail = ""
    
    @IBAction private func closeButtonPressed(_ sender: UIBarButtonItem) {
        
        let action = UIAlertController(title: "Удалить сообщение?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in
            if self.fromAuth || self.fromMenu{
                self.navigationController?.popViewController(animated: true)
            }else{
                let AppsUserDelegate = self.delegate as! AppealUser
                
                if (AppsUserDelegate.isCreatingRequest_) {
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }))
        present(action, animated: true, completion: nil)
        
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        if (!Server().isValidEmail(testStr: edEmail.text!) && edEmail.text != "") || (!Server().isValidEmail(testStr: edEmail.text!) && edContact.text == ""){
            let alert = UIAlertController(title: "Ошибка!", message: "Введите корректный E-mail", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        viewTapped(nil)
        startAnimator()

        uploadRequest()
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        viewTapped(nil)
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
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    private var images: [UIImage] = [] {
        didSet {
            drawImages()
        }
    }
    
    public var fromAuth: Bool = false
    public var fromMenu: Bool = false
    public var name_ = ""
    public var delegate: AppealUserDelegate?
    public var type_: RequestTypeStruct?
    private var reqId: String?
    private var data: AdmissionHeaderData?
    private var btnConstant: CGFloat = 0.0
    private var sprtTopConst: CGFloat = 0.0
    private var show = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        btnConstant = sendButton.frame.origin.y
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
        edContact.maskExpression = "+7 ({ddd}) {ddd}-{dd}-{dd}"
        edContact.maskTemplate = " "
        sendButton.isHidden = true
        sendBtnHeight.constant = 0
        self.imgsHeight.constant = 0
        TypeRequest.text = typeReq
        edEmail.delegate = self
        edIdent.delegate = self
        edComment.delegate  = self
        
        let defaults            = UserDefaults.standard
        edEmail.text              = defaults.string(forKey: "mail")
        if (defaults.string(forKey: "mail") == "-") {
            edEmail.text          = ""
        }
        edIdent.text = UserDefaults.standard.string(forKey: "login") ?? ""
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if UserDefaults.standard.string(forKey: "contactNumber") == "-" || UserDefaults.standard.string(forKey: "contactNumber") == "" || UserDefaults.standard.string(forKey: "contactNumber") == " "{
            edContact.text = ""
        }else{
            var phone = UserDefaults.standard.string(forKey: "contactNumber") ?? ""
            if phone.first == "8"{
                phone.removeFirst()
            }
            edContact.text = phone
        }
//        edContact.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        edEmail.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        edIdent.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        edComment.text = "Описание"
        edComment.textColor = UIColor.lightGray
        edComment.selectedTextRange = edComment.textRange(from: edComment.beginningOfDocument, to: edComment.beginningOfDocument)
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.updateUserInterface()
                //                self.viewDidLoad()
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
        notifiPressed = false
        if TemporaryHolder.instance.menuNotifications > 0{
            notifiBtn.image = UIImage(named: "new_notifi1")!
        }else{
            notifiBtn.image = UIImage(named: "new_notifi0")!
        }
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
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
//        let info = sender?.userInfo!
//        let keyboardSize = (info![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
//        self.sendViewConst.constant = (keyboardSize?.height)!
    }

    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
//        self.sendViewConst.constant = 0
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    private func drawImages() {
        
        if images.count == 0 {
            imgScroll.isHidden = true
            scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height - 170)
        } else {
            imgScroll.isHidden = false
            scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height + 170)
            imgScroll.subviews.forEach {
                $0.removeFromSuperview()
            }
            var x = 0.0
            var tag = 0
            
            images.forEach {
                let img = UIImageView(frame: CGRect(x: x, y: 0.0, width: 150.0, height: 150.0))
                img.image = $0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                tap.delegate = self
                img.isUserInteractionEnabled = true
                img.addGestureRecognizer(tap)
                imgScroll.addSubview(img)
                
                let deleteButton = UIButton(frame: CGRect(x: x + 130.0, y: 0.0, width: 20.0, height: 20.0))
                deleteButton.backgroundColor = .white
                deleteButton.cornerRadius = 0.5 * deleteButton.bounds.size.width
                deleteButton.clipsToBounds = true
                deleteButton.tag = tag
                deleteButton.alpha = 0.7
                deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
                imgScroll.addSubview(deleteButton)
                
                let image = UIImageView(frame: CGRect(x: x + 135.0, y: 5.0, width: 10.0, height: 10.0))
                image.image = UIImage(named: "rossNavbar")
                imgScroll.addSubview(image)
                
                x += 160
                tag += 1
            }
            imgScroll.contentSize = CGSize(width: CGFloat(x), height: imgScroll.frame.size.height)
        }
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        images.remove(at: sender.tag)
        DispatchQueue.main.async {
            if self.images.count != 0{
                self.imgsHeight.constant = 150
            }else{
                self.imgsHeight.constant = 0
            }
        }
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
    
    private func uploadRequest() {
        
        let login = UserDefaults.standard.string(forKey: "login")!
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let comm:String = edComment.text
        var name = ""
        
        if self.typeReq == "Консьержу/ в службу комфорта"{
            name = "Обращение к консьержу \(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))"
        }else if self.typeReq == "Директору службы комфорта"{
            name = "Обращение к директору службы комфорта \(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))"
        }else if self.typeReq == "В техподдержку приложения"{
            name = "Обращение в техподдержку приложения \(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))"
        }
//        print(Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(type_?.id)&name=\(name)&text=\(comm)&phonenum=\(self.edContact.text)&emails=\(self.edEmail.text)&appealMail=\(selEmail)&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&dateTo=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&dateServiceDesired=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&ResponsiblePerson=\(self.typeReq)&isAppeal=1")
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)" + "&pwd=\(pass)" + "&type=\(type_?.id?.stringByAddingPercentEncodingForRFC3986() ?? "")" + "&name=\(name.stringByAddingPercentEncodingForRFC3986()!)" + "&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)" + "&phonenum=\(self.edContact.text?.stringByAddingPercentEncodingForRFC3986() ?? "")" + "&isAppeal=1" + "&dateServiceDesired=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")" + "&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")" + "&ResponsiblePerson=\(self.typeReq.stringByAddingPercentEncodingForRFC3986()!)" + "&emails=\(self.edEmail.text?.stringByAddingPercentEncodingForRFC3986() ?? "")" + "&isPaidEmergencyRequest=1" + "&isNotify=1" + "&dateFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")" + "&dateTo=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")" + "&appealMail=\(selEmail.stringByAddingPercentEncodingForRFC3986() ?? "")" + "&clearAfterWork="
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        var requestBody: [String:[Any]] = ["persons":[], "autos":[]]
        requestBody["persons"]?.append(["FIO":self.typeReq.stringByAddingPercentEncodingForRFC3986() ?? "", "PassportData":""])
        
        if let json = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted) {
            request.httpBody = Data(json)
        }
        print(url)
        
        URLSession.shared.dataTask(with: request) {
            responce, error, _ in
            
            guard responce != nil else {
                DispatchQueue.main.async {
                    self.endAnimator()
                }
                return
            }
            if (String(data: responce!, encoding: .utf8)?.contains(find: "error"))! {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    
                }
                return
            } else {
                #if DEBUG
                print(String(data: responce!, encoding: .utf8)!)
                #endif
                
                self.reqId = String(data: responce!, encoding: .utf8)
                DispatchQueue.global(qos: .userInteractive).async {
                    
                    self.images.forEach {
                        self.uploadPhoto($0)
                    }
                    DispatchQueue.main.sync {
                        
                        self.endAnimator()
                        if !self.fromAuth && !self.fromMenu{
                            self.delegate?.update()
                        }
                        var titleA = ""
                        if self.typeReq == "Консьержу/ в службу комфорта"{
                            titleA = "Сообщение отправлено в службу комфорта"
                        }else if self.typeReq.containsIgnoringCase(find: "директор"){
                            titleA = "Сообщение директору службы комфорта отправлено"
                        }else if self.typeReq == "В техподдержку приложения"{
                            titleA = "Сообщение отправлено в техподдержку приложения"
                        }
                        let alert = UIAlertController(title: "Спасибо!", message: titleA, preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                            self.navigationController?.popViewController(animated: true)
                        }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                        
                    }
                }
            }
            }.resume()
    }
    
    private func uploadPhoto(_ img: UIImage) {
        
        let group = DispatchGroup()
        let reqID = reqId?.stringByAddingPercentEncodingForRFC3986()
        let id = UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986()
        
        group.enter()
        let uid = UUID().uuidString
        Alamofire.upload(multipartFormData: { multipartFromdata in
            multipartFromdata.append(UIImageJPEGRepresentation(img, 0.5)!, withName: uid, fileName: "+skip\(uid).jpg", mimeType: "image/jpeg")
        }, to: Server.SERVER + Server.ADD_FILE + "reqID=" + reqID! + "&accID=" + id!) { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    print(response.result.value!)
                    group.leave()
                    
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
        group.wait()
        return
    }
    
    private func startAnimator() {
        sendButton.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimator() {
        sendButton.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: date)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        images.append(image)
        DispatchQueue.main.async {
            if self.images.count != 0{
                self.imgsHeight.constant = 150
            }else{
                self.imgsHeight.constant = 0
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if edIdent.text == ""{
            sendButton.isHidden = true
            sendBtnHeight.constant = 0
        }else if edComment.textColor == UIColor.lightGray{
            sendButton.isHidden = true
            sendBtnHeight.constant = 0
        }else if edContact.text == "" && edComment.text != "" && edIdent.text != "" && edEmail.text != ""{
            sendButton.isHidden = false
            sendBtnHeight.constant = 48
        }else if edContact.text != "" && edComment.text != "" && edIdent.text != "" && edEmail.text == ""{
            sendButton.isHidden = false
            sendBtnHeight.constant = 48
        }else if edContact.text != "" && edComment.text != "" && edIdent.text != "" && edEmail.text != ""{
            sendButton.isHidden = false
            sendBtnHeight.constant = 48
        }else if edContact.text == "" && edComment.text != "" && edIdent.text != "" && edEmail.text == ""{
            sendButton.isHidden = true
            sendBtnHeight.constant = 0
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if edComment.textColor == UIColor.lightGray {
            edComment.text = nil
            edComment.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if edComment.text.isEmpty {
            edComment.text = "Описание"
            edComment.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        var height = heightForView(text: edComment.text, font: edComment.font!, width: view.frame.size.width - 64)
        if text == "\n"{
            height = height + 20
        }
        if height > 40.0{
            DispatchQueue.main.async{
                self.edConst.constant = height
            }
        }else{
            DispatchQueue.main.async{
                self.edConst.constant = 40
            }
        }
        return true
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UITextView = UITextView(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if edIdent.text == ""{
            sendButton.isHidden = true
            sendBtnHeight.constant = 0
        }else if edComment.textColor == UIColor.lightGray{
            sendButton.isHidden = true
            sendBtnHeight.constant = 0
        }else if edContact.text == "" && edComment.text != "" && edIdent.text != "" && edEmail.text != ""{
            sendButton.isHidden = false
            sendBtnHeight.constant = 48
        }else if edContact.text != "" && edComment.text != "" && edIdent.text != "" && edEmail.text == ""{
            sendButton.isHidden = false
            sendBtnHeight.constant = 48
        }else if edContact.text != "" && edComment.text != "" && edIdent.text != "" && edEmail.text != ""{
            sendButton.isHidden = false
            sendBtnHeight.constant = 48
        }else if edContact.text == "" && edComment.text != "" && edIdent.text != "" && edEmail.text == ""{
            sendButton.isHidden = true
            sendBtnHeight.constant = 0
        }
    }
}
