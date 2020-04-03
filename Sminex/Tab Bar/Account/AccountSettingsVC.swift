//
//  AccountSettingsVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/6/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import CropViewController
import AKMaskField

final class AccountSettingsVC: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate, UITextViewDelegate {
    
    @IBOutlet private weak var loader:              UIActivityIndicatorView!
    @IBOutlet private weak var saveButtonTop:       NSLayoutConstraint!
    @IBOutlet private weak var backButton:          UIBarButtonItem!
    @IBOutlet private weak var scroll:              UIScrollView!
    @IBOutlet private weak var accountImageView:    UIImageView!
    @IBOutlet private weak var changePasswordImg:   UIImageView!
    @IBOutlet private weak var notificationsImg:    UIImageView!
    @IBOutlet private weak var familyNameField:     UITextField!
    @IBOutlet private weak var otchestvoField:  	UITextField!
    @IBOutlet private weak var contactNumber:       AKMaskField!
    @IBOutlet private weak var commentField:        UITextView!
    @IBOutlet private weak var privNumber:          AKMaskField!
    @IBOutlet private weak var nameField:       	UITextField!
    @IBOutlet private weak var lsLabel:             UITextField!
    @IBOutlet private weak var email:               UITextField!
    @IBOutlet private weak var adress:              UITextField!
    @IBOutlet private weak var saveButton:          UIButton!
    @IBOutlet private weak var changePassword:  	UILabel!
    @IBOutlet private weak var notifications:   	UILabel!
    @IBOutlet private weak var changePasswordTop:   UILabel!
    @IBOutlet private weak var changePasswordBtm:   UILabel!
    @IBOutlet private weak var lisevoyLabel:        UILabel!
    @IBOutlet private weak var phoneLabel:          UILabel!
    @IBOutlet private weak var contactLabel:        UILabel!
    @IBOutlet private weak var emailLabel:          UILabel!
    
    var cameraOn = false
    
    @IBAction private func imageViewPressed(_ sender: UIButton) {
        
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary
                imagePicker.allowsEditing = false
                self.cameraOn = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Сделать фото", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                self.cameraOn = true
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    @IBAction private func exitButtonPressed(_ sender: UIButton) {
        self.exit()
    }
    
    func exit(){
        UserDefaults.standard.removeObject(forKey: "dealsJSON")
        UserDefaults.standard.removeObject(forKey: "deals")
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "pass"), forKey: "exitPass")
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "login"), forKey: "exitLogin")
        UserDefaults.standard.setValue("", forKey: "pass")
        UserDefaults.standard.removeObject(forKey: "accountIcon")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "DealsImg")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "newsLastId")
        UserDefaults.standard.synchronize()
        present(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!, animated: true, completion: nil)
    }
    
    @IBAction private func saveButtonPressed(_ sender: UIButton) {
        startAnimator()
        editAccountInfo()
    }
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    public var isReg_ = false
    public var isNew  = false
    public var responceString_ = ""
    public var login_ = ""
    public var pass_  = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        if isReg_ {
            title                            = "Регистрация"
            navigationItem.leftBarButtonItem = nil
            navigationItem.hidesBackButton   = true
            changePassword.isHidden          = true
            notifications.isHidden           = true
            changePasswordImg.isHidden       = true
            notificationsImg.isHidden        = true
            changePasswordTop.isHidden       = true
            changePasswordBtm.isHidden       = true
            saveButtonTop.constant           = -90
        }
        automaticallyAdjustsScrollViewInsets = false
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = UserDefaults.standard.object(forKey: "accountIcon"),
                let image = UIImage(data: imageData as! Data) {
                DispatchQueue.main.async {
                    self.accountImageView.image = image
                }
            }
        }
        commentField.delegate = self
        accountImageView.cornerRadius = accountImageView.frame.height / 2
        self.stopAnimator()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        
        let changePasswordTap = UITapGestureRecognizer(target: self, action: #selector(changePasswordTapped(_:)))
        changePassword.isUserInteractionEnabled = true
        changePassword.addGestureRecognizer(changePasswordTap)
        
        let changeNotificationsTap = UITapGestureRecognizer(target: self, action: #selector(changeNotificationTapped(_:)))
        notifications.isUserInteractionEnabled = true
        notifications.addGestureRecognizer(changeNotificationsTap)
        
        let defaults            = UserDefaults.standard
        email.text              = defaults.string(forKey: "mail")
        if (defaults.string(forKey: "mail") == "-") {
            email.text          = ""
            emailLabel.isHidden = true
        }
        contactNumber.maskExpression = "+7 ({ddd}) {ddd}-{dddd}"
        contactNumber.maskTemplate = "*"
        var contactPhone: String = defaults.string(forKey: "contactNumber") ?? ""
        if contactPhone.first == "8"{
            contactPhone.removeFirst()
        }
        contactNumber.text = contactPhone
//        if (defaults.string(forKey: "contactNumber") == "-") {
//            contactNumber.text  = ""
//            contactLabel.isHidden = true
//        }
        privNumber.maskExpression = "+7 ({ddd}) {ddd}-{dddd}"
        privNumber.maskTemplate = "*"
        var privPhone: String = defaults.string(forKey: "phone_user") ?? ""
        if privPhone.first == "8"{
            privPhone.removeFirst()
        }
        privNumber.text = privPhone
        if (defaults.string(forKey: "phone_user") == "-") {
            privNumber.text     = ""
        }
        lsLabel.text            = defaults.string(forKey: "login")
        if (defaults.string(forKey: "login") == "-") {
            lsLabel.text        = ""
        }
        adress.text             = defaults.string(forKey: "adress")
        commentField.text       = defaults.string(forKey: "accDesc")
        if (defaults.string(forKey: "accDesc") == "-") || ((defaults.string(forKey: "accDesc")?.containsIgnoringCase(find: "добавить комментарий"))!){
            commentField.text   = "Добавить комментарий (например, «не звонить с 10 до 12»)"
            commentField.textColor = UIColor.lightGray
            commentField.selectedTextRange = commentField.textRange(from: commentField.beginningOfDocument, to: commentField.beginningOfDocument)
        }
        
        let name                = defaults.string(forKey: "name")?.split(separator: " ")
        if name?.count == 4{
            familyNameField.text    = String(describing: name?[safe: 0] ?? "") + " " + String(describing: name?[safe: 1] ?? "")
            nameField.text          = String(describing: name?[safe: 2] ?? "")
            otchestvoField.text     = String(describing: name?[safe: 3] ?? "")
        }else{
            familyNameField.text    = String(describing: name?[safe: 0] ?? "")
            nameField.text          = String(describing: name?[safe: 1] ?? "")
            otchestvoField.text     = String(describing: name?[safe: 2] ?? "")
        }
        if familyNameField.text == "-"{
            familyNameField.text = ""
        }
        if nameField.text == "-"{
            nameField.text = ""
        }
        if otchestvoField.text == "-"{
            otchestvoField.text = ""
        }
        contactNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        privNumber.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        email.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        lsLabel.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
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
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = false
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(sender: NSNotification?) {
        scroll.contentInset.bottom = 220
    }
    @objc func keyboardWillHide(sender: NSNotification?) {
        scroll.contentInset.bottom = 0
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
       view.endEditing(true)
    }
    
    @objc private func changePasswordTapped(_ sender: UITapGestureRecognizer?) {
        performSegue(withIdentifier: Segues.fromAccountSettingsVC.toChangePassword, sender: self)
    }
    
    @objc private func changeNotificationTapped(_ sender: UITapGestureRecognizer?) {
        performSegue(withIdentifier: Segues.fromAccountSettingsVC.toChangeNotific, sender: self)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var image : UIImage!
        if let img = info[UIImagePickerControllerEditedImage] as? UIImage{
            image = img
        }
        else if let img = info[UIImagePickerControllerOriginalImage] as? UIImage{
            image = img
        }
//        if picker.cameraDevice == .front{
//            image = UIImage(cgImage: image.cgImage!, scale: image.scale, orientation: .leftMirrored)
//        }
//        accountImageView.image = image
        dismiss(animated: true, completion: nil)
        
        self.presentCropViewController(Image: image)
    }
    
    func presentCropViewController(Image: UIImage) {
        
        let cropViewController = CropViewController.init(croppingStyle: .circular, image: Image)
        cropViewController.delegate = self
        if #available(iOS 13.0, *) {
            cropViewController.modalPresentationStyle = .fullScreen
        }
        self.present(cropViewController, animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        accountImageView.image = image
        DispatchQueue.global(qos: .background).async {
            var imageList   : [String:Data] = [:]
            
            let login = UserDefaults.standard.string(forKey: "login")!
            if UserDefaults.standard.dictionary(forKey: "allIcon") != nil{
                imageList = UserDefaults.standard.dictionary(forKey: "allIcon") as! [String : Data]
                
                if let k = imageList.keys.firstIndex(of: login){
                    imageList.remove(at: k)
                }
            }
            
            imageList[login] = UIImageJPEGRepresentation(resizeImageWith(image: image, newSize: CGSize(width: 128, height: 128)), 128)
            UserDefaults.standard.setValue(imageList, forKey: "allIcon")
            UserDefaults.standard.setValue(UIImageJPEGRepresentation(resizeImageWith(image: image, newSize: CGSize(width: 128, height: 128)), 128), forKey: "accountIcon")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    private func editAccountInfo() {
        print("SaveINFO: ", contactNumber.text ?? "", privNumber.text ?? "")
        var answers = isReg_ ? responceString_.split(separator: ";") : [""]
        
        let defPhone = isReg_ ? String(answers[safe: 14] ?? "") : (UserDefaults.standard.string(forKey: "contactNumber")?.stringByAddingPercentEncodingForRFC3986() ?? "")
        let defMail  = isReg_ ? String(answers[safe: 3]  ?? "") : (UserDefaults.standard.string(forKey: "mail")?.stringByAddingPercentEncodingForRFC3986() ?? "")
        let phone    = privNumber.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let phone_contact = contactNumber.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        let email   = self.email.text?.stringByAddingPercentEncodingForRFC3986() ?? defMail
        let area    = isReg_ ? String(answers[safe: 12] ?? "") : (UserDefaults.standard.string(forKey: "residentialArea")?.stringByAddingPercentEncodingForRFC3986()   ?? "")
        let rooms   = isReg_ ? String(answers[safe: 11] ?? "") : (UserDefaults.standard.string(forKey: "roomsCount")?.stringByAddingPercentEncodingForRFC3986()        ?? "")
        let total   = isReg_ ? String(answers[safe: 13] ?? "") : (UserDefaults.standard.string(forKey: "totalArea")?.stringByAddingPercentEncodingForRFC3986()         ?? "")
//        let adress  = isReg_ ? String(answers[safe: 10] ?? "") : (UserDefaults.standard.string(forKey: "adress")?.stringByAddingPercentEncodingForRFC3986()            ?? "")
        let login   = isReg_ ? login_ : (UserDefaults.standard.string(forKey: "login")?.stringByAddingPercentEncodingForRFC3986()             ?? "")
//        let defName = isReg_ ? String(answers[safe: 6] ?? "") : (UserDefaults.standard.string(forKey: "name") ?? "")
        var name    = ""
        if familyNameField.text == "" || familyNameField.text == " "{
            name = "-"
        }else{
            name = familyNameField.text ?? ""
        }
        if nameField.text == "" || nameField.text == " "{
            name = name + " -"
        }else{
            name = name + " " + nameField.text!
        }
        if otchestvoField.text == "" || otchestvoField.text == " "{
            name = name + " -"
        }else{
            name = name + " " + otchestvoField.text!
        }
        name = name.stringByAddingPercentEncodingForRFC3986() ?? ""
//        let pass    = getHash(pass: isReg_ ? pass_ : UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: isReg_ ? login_ : UserDefaults.standard.string(forKey: "login") ?? ""))
        let pass: String = UserDefaults.standard.string(forKey: "pwd") ?? ""
        var comment_txt:String = commentField.text
        if comment_txt == "Добавить комментарий (например, «не звонить с 10 до 12»)"{
            comment_txt = ""
        }
        let adress = self.adress.text?.stringByAddingPercentEncodingForRFC3986() ?? ""
        comment_txt = comment_txt.stringByAddingPercentEncodingForRFC3986() ?? ""
        let url = "\(Server.SERVER)\(Server.EDIT_ACCOUNT)login=\(login)&pwd=\(pass)&address=\(adress)&name=\(name)&phone=\(phone)&businessPhone=\(phone_contact)&email=\(email)&additionalInfo=\(comment_txt)&totalArea=\(total)&resindentialArea=\(area)&roomsCount=\(rooms)"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        print("SaveINFO: ", request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.stopAnimator()
                }
            }
            guard data != nil else { return }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8)!)
            
            #endif
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if self.isReg_ {
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    self.present(storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq"), animated: true, completion: nil)
                }
            
            } else {
                DispatchQueue.main.async {
                    let vc = ViewController()
                    vc.isFromSettings_ = true
                    vc.enter(login: UserDefaults.standard.string(forKey: "login") ?? "", pass: UserDefaults.standard.string(forKey: "pass") ?? "", pwdE: UserDefaults.standard.string(forKey: "pwd") ?? "")
                    let alert = UIAlertController(title: nil, message: "Изменения успешно сохранены!", preferredStyle: .alert)
                    alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        self.navigationController?.popViewController(animated: true)
                    } ) )
                    self.present(alert, animated: true, completion: nil)
                }
            }
        
        }.resume()
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        //var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login.suffix(4))!)
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
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                        self.exit()
                    }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            }.resume()
        
        queue.wait()
        return salt!
    }
    
    private func startAnimator() {
        loader.isHidden = false
        loader.startAnimating()
        saveButton.isHidden = true
    }
    
    private func stopAnimator() {
        loader.stopAnimating()
        loader.isHidden = true
        saveButton.isHidden = false
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        
//        if contactNumber.text == "" {
//            contactLabel.isHidden = true
//
//        } else {
//            contactLabel.isHidden = false
//        }
        
        if privNumber.text == "" {
            phoneLabel.isHidden = true
            
        } else {
            phoneLabel.isHidden = false
        }
        if lsLabel.text == "" {
            lisevoyLabel.isHidden = true
            
        } else {
            lisevoyLabel.isHidden = false
        }
        if email.text == "" {
            emailLabel.isHidden = true
            
        } else {
            emailLabel.isHidden = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
//        if textView.text == "Добавить комментарий (например, «не звонить с 10 до 12»)"{
//            textView.text = ""
//        }
        if updatedText.isEmpty {
            textView.text = "Добавить комментарий (например, «не звонить с 10 до 12»)"
            textView.textColor = UIColor.lightGray
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            
        } else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text
            
        } else {
            return true
        }
        return false
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
}
