//
//  CreateAppeal.swift
//  Sminex
//
//  Created by Sergey Ivanov on 22/07/2019.
//

import UIKit
import Alamofire
import DeviceKit

class CreateAppeal: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var sendViewConst: NSLayoutConstraint!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var imgScroll:       UIScrollView!
    @IBOutlet private weak var edContact:       UITextField!
    @IBOutlet private weak var edEmail:         UITextField!
    @IBOutlet private weak var edIdent:         UITextField!
    @IBOutlet private weak var TypeRequest:     UILabel!
    @IBOutlet private weak var edComment:       UITextView!
    @IBOutlet private weak var sendButton:      UIButton!
    
    public var typeReq = ""
    
    @IBAction private func closeButtonPressed(_ sender: UIBarButtonItem) {
        
        let action = UIAlertController(title: "Удалить сообщение?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in
            let AppsUserDelegate = self.delegate as! AppealUser
            
            if (AppsUserDelegate.isCreatingRequest_) {
                self.navigationController?.popToRootViewController(animated: true)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }))
        present(action, animated: true, completion: nil)
        
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        if !Server().isValidEmail(testStr: edEmail.text!){
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
        
        sendButton.alpha     = 0.5
        sendButton.isEnabled = false
        TypeRequest.text = typeReq
        edContact.delegate  = self
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
            edContact.text = UserDefaults.standard.string(forKey: "contactNumber") ?? ""
        }
        edContact.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
        let info = sender?.userInfo!
        let keyboardSize = (info![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        self.sendViewConst.constant = (keyboardSize?.height)!
    }

    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        self.sendViewConst.constant = 0
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
        }else if self.typeReq == "Директору службы комфорта \(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))"{
            name = "Обращение к директору службы комфорта"
        }else if self.typeReq == "в Техподдержку приложения"{
            name = "Обращение в техподдержку приложения \(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))"
        }
        print(Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(type_?.id ?? "")&name=\(name)&text=\(comm)&phonenum=\(UserDefaults.standard.string(forKey: "contactNumber") ?? "")&email=\(UserDefaults.standard.string(forKey: "mail") ?? "")&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&dateTo=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&dateServiceDesired=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))")
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(type_?.id?.stringByAddingPercentEncodingForRFC3986() ?? "")&name=\(name.stringByAddingPercentEncodingForRFC3986()!)&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)&phonenum=\(UserDefaults.standard.string(forKey: "contactNumber") ?? "")&email=\(UserDefaults.standard.string(forKey: "mail") ?? "")&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&dateTo=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        
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
                        self.delegate?.update()
                        var titleA = ""
                        if self.typeReq == "Консьержу/ в службу комфорта"{
                            titleA = "Сообщение отправлено в службу комфорта"
                        }else if self.typeReq == "Директору службы комфорта"{
                            titleA = "Сообщение Директору службы комфорта отправлено"
                        }else if self.typeReq == "в Техподдержку приложения"{
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
            multipartFromdata.append(UIImageJPEGRepresentation(img, 0.5)!, withName: uid, fileName: "\(uid).jpg", mimeType: "image/jpeg")
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
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if edIdent.text == ""{
            sendButton.alpha     = 0.5
            sendButton.isEnabled = false
        }else if edComment.textColor == UIColor.lightGray{
            sendButton.alpha     = 0.5
            sendButton.isEnabled = false
        }else if edContact.text == "" && edComment.text != "" && edIdent.text != "" && edEmail.text != ""{
            sendButton.alpha     = 1
            sendButton.isEnabled = true
        }else if edContact.text != "" && edComment.text != "" && edIdent.text != "" && edEmail.text == ""{
            sendButton.alpha     = 1
            sendButton.isEnabled = true
        }else if edContact.text != "" && edComment.text != "" && edIdent.text != "" && edEmail.text != ""{
            sendButton.alpha     = 1
            sendButton.isEnabled = true
        }else if edContact.text == "" && edComment.text != "" && edIdent.text != "" && edEmail.text == ""{
            sendButton.alpha     = 0.5
            sendButton.isEnabled = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
            if updatedText.isEmpty {
                textView.text = "Описание"
                sendButton.alpha     = 0.5
                sendButton.isEnabled = false
                textView.textColor = UIColor.lightGray
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
                
            } else if textView.textColor == UIColor.lightGray && !text.isEmpty {
                textView.textColor = UIColor.black
                textView.text = text
                sendButton.alpha     = 1
                sendButton.isEnabled = true
            } else {
                return true
            }
        return false
    }
    var previousValue = CGRect.zero
    var lines = 1
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
}
