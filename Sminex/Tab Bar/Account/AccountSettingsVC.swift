//
//  AccountSettingsVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/6/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class AccountSettingsVC: UIViewController, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private weak var loader:              UIActivityIndicatorView!
    @IBOutlet private weak var saveButtonTop:       NSLayoutConstraint!
    @IBOutlet private weak var scroll:              UIScrollView!
    @IBOutlet private weak var accountImageView:    UIImageView!
    @IBOutlet private weak var changePasswordImg:   UIImageView!
    @IBOutlet private weak var notificationsImg:    UIImageView!
    @IBOutlet private weak var familyNameField:     UITextField!
    @IBOutlet private weak var otchestvoField:  	UITextField!
    @IBOutlet private weak var contactNumber:       UITextField!
    @IBOutlet private weak var commentField:        UITextField!
    @IBOutlet private weak var privNumber:          UITextField!
    @IBOutlet private weak var nameField:       	UITextField!
    @IBOutlet private weak var lsLabel:             UITextField!
    @IBOutlet private weak var email:               UITextField!
    @IBOutlet private weak var saveButton:          UIButton!
    @IBOutlet private weak var exitButton:          UIButton!
    @IBOutlet private weak var changePassword:  	UILabel!
    @IBOutlet private weak var notifications:   	UILabel!
    @IBOutlet private weak var changePasswordTop:   UILabel!
    @IBOutlet private weak var changePasswordBtm:   UILabel!
    @IBOutlet private weak var notificationsBtm:    UILabel!
    
    @IBAction private func imageViewPressed(_ sender: UIButton) {
        
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
    
    @IBAction private func exitButtonPressed(_ sender: UIButton) {
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
    
    open var isReg_ = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isReg_ {
            title                       = "Регистрация"
            exitButton.isHidden         = true
            changePassword.isHidden     = true
            notifications.isHidden      = true
            changePasswordImg.isHidden  = true
            notificationsImg.isHidden   = true
            changePasswordTop.isHidden  = true
            changePasswordBtm.isHidden  = true
            notificationsBtm.isHidden   = true
            saveButtonTop.constant      = -130
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
        contactNumber.text      = defaults.string(forKey: "contactNumber")
        privNumber.text         = defaults.string(forKey: "contactNumber")
        lsLabel.text            = defaults.string(forKey: "login")
        
        let name                = defaults.string(forKey: "name")?.split(separator: " ")
        familyNameField.text    = String(describing: name?[0] ?? "")
        nameField.text          = String(describing: name?[1] ?? "")
        otchestvoField.text     = String(describing: name?[2] ?? "")
        
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent   = true
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.tintColor       = .white
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17, weight: .bold) ]
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
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        accountImageView.image = image
        DispatchQueue.global(qos: .background).async {
            UserDefaults.standard.setValue(UIImagePNGRepresentation(resizeImageWith(image: image, newSize: CGSize(width: 128, height: 128))), forKey: "accountIcon")
        }
        dismiss(animated: true, completion: nil)
    }
    
    private func editAccountInfo() {
        
        let phone   = privNumber.text?.stringByAddingPercentEncodingForRFC3986() ?? (UserDefaults.standard.string(forKey: "contactNumber")?.stringByAddingPercentEncodingForRFC3986() ?? "")
        let email   = self.email.text?.stringByAddingPercentEncodingForRFC3986() ?? (UserDefaults.standard.string(forKey: "mail")?.stringByAddingPercentEncodingForRFC3986() ?? "")
        let area    = UserDefaults.standard.string(forKey: "residentialArea")?.stringByAddingPercentEncodingForRFC3986()   ?? ""
        let rooms   = UserDefaults.standard.string(forKey: "roomsCount")?.stringByAddingPercentEncodingForRFC3986()        ?? ""
        let total   = UserDefaults.standard.string(forKey: "totalArea")?.stringByAddingPercentEncodingForRFC3986()         ?? ""
        let adress  = UserDefaults.standard.string(forKey: "adress")?.stringByAddingPercentEncodingForRFC3986()            ?? ""
        let login   = UserDefaults.standard.string(forKey: "login")?.stringByAddingPercentEncodingForRFC3986()             ?? ""
        let name    = "\(familyNameField.text ?? "") \(nameField.text ?? "") \(otchestvoField.text ?? "")".stringByAddingPercentEncodingForRFC3986() ?? (UserDefaults.standard.string(forKey: "name")?.stringByAddingPercentEncodingForRFC3986() ?? "")
        let pass    = getHash(pass: UserDefaults.standard.string(forKey: "pass")!, salt: getSalt(login: UserDefaults.standard.string(forKey: "login")!))
        
        let url = "\(Server.SERVER)\(Server.EDIT_ACCOUNT)login=\(login)&pwd=\(pass)&address=\(adress)&name=\(name)&phone=\(phone)&email=\(email)&additionalInfo=\(commentField.text ?? "")&totalArea=\(total)&resindentialArea=\(area)&roomsCount=\(rooms)"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.stopAnimator()
                }
            }
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if self.isReg_ {
                DispatchQueue.main.sync {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    self.present(storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq"), animated: true, completion: nil)
                }
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8)!)
            #endif
        
        }.resume()
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
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
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
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
}
