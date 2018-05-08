//
//  CreateRequestVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/24/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire

final class CreateRequestVC: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var imageConst:      NSLayoutConstraint!
    @IBOutlet private weak var commentConst:    NSLayoutConstraint!
    @IBOutlet private weak var sendBtnConst:    NSLayoutConstraint!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var imgScroll:       UIScrollView!
    @IBOutlet private weak var picker:          UIDatePicker!
    @IBOutlet private weak var edFio:           UITextField!
    @IBOutlet private weak var edContact:       UITextField!
    @IBOutlet private weak var gosNumber:       UITextField!
    @IBOutlet private weak var edComment:       UITextField!
    @IBOutlet private weak var dateField:       UIButton!
    @IBOutlet private weak var sendButton:      UIButton!
    @IBOutlet private weak var transportSwitch: UISwitch!
    @IBOutlet private weak var gosLine:         UILabel!
    @IBOutlet private weak var pickerLine:      UILabel!
    
    @IBAction private func closeButtonPressed(_ sender: UIBarButtonItem) {
        
        let action = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in self.navigationController?.popViewController(animated: true) }))
        present(action, animated: true, completion: nil)
        
    }
    
    @IBAction private func datePickerButtonPressed(_ sender: UIButton?) {
        
        if sender != nil {
            viewTapped(nil)
        }
        if picker.isHidden {
            
            if imgScroll.isHidden {
                sendBtnConst.constant   = 180
                
            } else {
                sendBtnConst.constant   = 340
                imageConst.constant     = 180
            }
            picker.isHidden         = false
            pickerLine.isHidden     = false
            
        } else {
            
            if imgScroll.isHidden {
                sendBtnConst.constant   = 15
            
            } else {
                sendBtnConst.constant   = 170
                imageConst.constant     = 5
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM HH:mm"
            
            dateField.setTitle(dateFormatter.string(from: picker.date), for: .normal)
            picker.isHidden         = true
            pickerLine.isHidden     = true
        }
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        
        viewTapped(nil)
        if edFio.text == "" {
            edFio.placeholder = "Введите текст!"
        
        } else if edContact.text == "" {
            edContact.placeholder = "Введите текст!"
        
        } else {
            
            startAnimator()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy hh:mm:ss"
            data = AdmissionHeaderData(icon: UIImage(named: "account")!,
                                       gosti: edFio.text!,
                                       mobileNumber: edContact.text!,
                                       gosNumber: gosNumber.text ?? "",
                                       date: dateFormatter.string(from: picker.date),
                                       status: "В ОБРАБОТКЕ",
                                       images: images,
                                       imagesUrl: [])
            uploadRequest()
        }
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        viewTapped(nil)
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
    
    open var name_ = ""
    open var delegate: AppsUserDelegate?
    open var type_: RequestTypeStruct?
    private var reqId: String?
    private var data: AdmissionHeaderData?
    private var btnConstant: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnConstant = sendButton.frame.origin.y
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM HH:mm"
        dateField.setTitle(dateFormatter.string(from: Date()), for: .normal)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
        
        sendButton.alpha     = 0.5
        sendButton.isEnabled = false
        
        edContact.delegate  = self
        edFio.delegate      = self
        
        title = "Пропуск"
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        transportSwitch.addTarget(self, action: #selector(stateChanged(_:)), for: .valueChanged)
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
        
        if !picker.isHidden {
            datePickerButtonPressed(nil)
        }
        
        if isNeedToScroll() {
            if images.count != 0 {
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height + 200)
            } else {
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height + 50)
            }
            scroll.contentOffset = CGPoint(x: 0, y: 140)
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        
        if isNeedToScroll() {
            if images.count != 0 {
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height - 200)
            } else {
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height - 50)
            }
            scroll.contentOffset = CGPoint(x: 0, y: 0)
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
        if !picker.isHidden {
            datePickerButtonPressed(nil)
        }
    }
    
    @objc private func stateChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            commentConst.constant   = 65
            gosNumber.isHidden      = false
            gosLine.isHidden        = false
        
        } else {
            commentConst.constant   = 8
            gosNumber.isHidden      = true
            gosLine.isHidden        = true
        }
    }
    
    private func drawImages() {
        
        if images.count == 0 {
            imgScroll.isHidden = true
            
            if !picker.isHidden {
                imageConst.constant = 8
                sendBtnConst.constant = 350
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height - 350)
                
            } else {
                sendBtnConst.constant = 8
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height - 170)
            }

        } else {
            imgScroll.isHidden = false
            
            if !picker.isHidden {
                imageConst.constant = 180
                sendBtnConst.constant = 350
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height + 350)
            
            } else {
                sendBtnConst.constant = 170
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.frame.size.height + 170)
            }
            
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
                image.image = UIImage(named: "close_ic")
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
        let pass = getHash(pass: UserDefaults.standard.string(forKey: "pass")!, salt: getSalt())
        let comm = edComment.text ?? ""
        
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(type_?.id?.stringByAddingPercentEncodingForRFC3986() ?? "")&name=\("\(name_.stringByAddingPercentEncodingForRFC3986() ?? "") \(formatDate(Date(), format: "dd.MM.yyyy hh:mm:ss"))".stringByAddingPercentEncodingForRFC3986() ?? "")&text=\(comm.stringByAddingPercentEncodingForRFC3986() ?? "")&phonenum=\(String(describing: data!.mobileNumber).stringByAddingPercentEncodingForRFC3986() ?? "")&responsiblePerson=\(data!.gosti.stringByAddingPercentEncodingForRFC3986() ?? "")&email=&isPaidEmergencyRequest=0&isNotify=1&dateFrom=\(formatDate(Date(), format: "dd.MM.yyyy hh:mm:ss").stringByAddingPercentEncodingForRFC3986()!)&dateTo=\(formatDate(picker.date, format: "dd.MM.yyyy hh:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=&clearAfterWork="
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        
        print(request.url)
        
        URLSession.shared.dataTask(with: request) {
            responce, error, _ in
            
            guard responce != nil else {
                DispatchQueue.main.async {
                    self.endAnimator()
                }
                return
            }
            if (String(data: responce!, encoding: .utf8)?.contains(find: "error"))! {
                DispatchQueue.main.async {
                    
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
                
                DispatchQueue.main.async {
                    DB().setRequests(data: [RequestEntityData(title: "Пропуск" + self.formatDate(Date(), format: "dd.MM.yyyy hh:mm:ss"),
                                                              desc: self.edComment.text!,
                                                              icon: UIImage(named: "processing_label")!,
                                                              date: (self.data?.date)!,
                                                              status: "В ОБРАБОТКЕ",
                                                              isBack: false)])
                }
                DispatchQueue.global(qos: .userInteractive).async {
                    
                    self.images.forEach {
                        self.uploadPhoto($0)
                    }
                    DispatchQueue.main.sync {
                        
                        self.endAnimator()
                        self.delegate?.update()
                        self.performSegue(withIdentifier: Segues.fromCreateRequest.toAdmission, sender: self)
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
            multipartFromdata.append(UIImagePNGRepresentation(img)!, withName: uid, fileName: "\(uid).png", mimeType: "image/png")
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCreateRequest.toAdmission {
            let vc = segue.destination as! AdmissionVC
            vc.isCreated_ = true
            vc.data_ = data ?? AdmissionHeaderData(icon: UIImage(), gosti: "", mobileNumber: "", gosNumber: "", date: "", status: "", images: [], imagesUrl: [])
            vc.reqId_ = reqId ?? ""
            vc.delegate = delegate
            vc.name_ = name_
        }
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if edFio.text == "" || edContact.text == "" {
            sendButton.alpha     = 0.5
            sendButton.isEnabled = false
        
        } else {
            sendButton.alpha     = 1
            sendButton.isEnabled = true
        }
        
        return true
    }
}
