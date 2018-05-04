//
//  CreateTechServiceVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/24/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire

final class CreateTechServiceVC: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var btnBottom:   NSLayoutConstraint!
    @IBOutlet private weak var btnConst:    NSLayoutConstraint!
    @IBOutlet private weak var imageConst:  NSLayoutConstraint!
    @IBOutlet private weak var picker:      UIDatePicker!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var images:      UIScrollView!
    @IBOutlet private weak var edProblem:   UITextField!
    @IBOutlet private weak var dateBtn:     UIButton!
    @IBOutlet private weak var sendBtn:     UIButton!
    @IBOutlet private weak var pickerLine:  UILabel!
    
    @IBAction private func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
        viewTapped(nil)
        let action = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in self.navigationController?.popViewController(animated: true) }))
        present(action, animated: true, completion: nil)
    }
    
    @IBAction private func dateButtonPressed(_ sender: UIButton?) {
        
        if sender != nil {
            view.endEditing(true)
        }
        if picker.isHidden {
            picker.isHidden     = false
            pickerLine.isHidden = false
            imageConst.constant = 170
            
            if !images.isHidden && isNeedToScrollMore() {
                btnConst.constant = 220
            
            } else if images.isHidden && isNeedToScrollMore() {
                btnConst.constant = 50
            }
        
        } else {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM HH:mm"
            
            dateBtn.setTitle(dateFormatter.string(from: picker.date), for: .normal)
            picker.isHidden     = true
            pickerLine.isHidden = true
            imageConst.constant = 8
            
            if !images.isHidden && isNeedToScrollMore() {
                btnConst.constant = 100
            
            } else if images.isHidden && isNeedToScrollMore() {
                btnConst.constant = 50
            }
        }
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        if !picker.isHidden {
            dateButtonPressed(nil)
        
        } else {
            view.endEditing(true)
        }
        
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
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        
        viewTapped(nil)
        if edProblem.text == "" {
            edProblem.placeholder = "Введите текст"
        
        } else {
            
            startAnimator()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            data = ServiceHeaderData(icon: UIImage(named: "account")!,
                                     problem: edProblem.text!,
                                     date: dateFormatter.string(from: picker.date),
                                     status: "В ОБРАБОТКЕ",
                                     images: imagesArr)
            
            if uploadRequest() {
                
                DispatchQueue.global(qos: .userInteractive).async {
                    
                    self.imagesArr.forEach {
                        self.uploadPhoto($0)
                    }
                    DispatchQueue.main.sync {
                        
                        self.endAnimator()
                        self.delegate?.update()
                        self.performSegue(withIdentifier: Segues.fromCreateTechService.toService, sender: self)
                    }
                }
            }
        }
    }
    
    open var delegate: AppsUserDelegate?
    private var data:   ServiceHeaderData?
    private var reqId:  String?
    private var constant: CGFloat = 0.0
    private var btnConstant: CGFloat = 0.0
    private var imagesArr: [UIImage] = [] {
        didSet {
            drawImages()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        constant = btnConst.constant
        btnConstant = sendBtn.frame.origin.y
        if isNeedToScrollMore() {
            btnConst.constant = 50
        }
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM HH:mm"
        dateBtn.setTitle(dateFormatter.string(from: Date()), for: .normal)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
        
        sendBtn.isEnabled   = false
        sendBtn.alpha       = 0.5
        
        edProblem.delegate = self
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        if !isNeedToScroll() {
            btnConst.constant = getConstant()
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
        if !picker.isHidden {
            dateButtonPressed(nil)
        }
        
        scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height + 200.0)
        if isNeedToScroll() {
            if imagesArr.count != 0 {
                btnConst.constant  = 35
                btnBottom.constant = 215
            
            } else {
                btnConst.constant  = -15
                btnBottom.constant = 240
            }
        
        } else {
            if !isXDevice() {
                btnConst.constant = getConstant() - 220
            
            } else {
                btnConst.constant = getConstant() - 240
            }
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height - 200.0)
        
        if isNeedToScroll() {
            btnBottom.constant = 8
            if !isNeedToScrollMore() {
                btnConst.constant = constant
            } else {
                btnConst.constant = 50
            }
        } else {
            btnConst.constant = getConstant()
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    private func drawImages() {
        
        if imagesArr.count == 0 {
            images.isHidden = true
            imageConst.constant = 8
            
            if !picker.isHidden && isNeedToScrollMore() {
                btnConst.constant = 100
                
            } else if picker.isHidden && isNeedToScrollMore() {
                btnConst.constant = 50
            }
            
        } else {
            
            if !picker.isHidden && isNeedToScrollMore() {
                btnConst.constant = 220
                
            } else if picker.isHidden && isNeedToScrollMore() {
                btnConst.constant = 50
            }
            
            images.isHidden = false
            
            if picker.isHidden {
                imageConst.constant = 8
                
            } else {
                imageConst.constant = 170
            }
            
            images.subviews.forEach {
                $0.removeFromSuperview()
            }
            var x = 0.0
            var tag = 0
            
            imagesArr.forEach {
                let img = UIImageView(frame: CGRect(x: x, y: 0.0, width: 150.0, height: 150.0))
                img.image = $0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                tap.delegate = self
                img.isUserInteractionEnabled = true
                img.addGestureRecognizer(tap)
                images.addSubview(img)
                
                let deleteButton = UIButton(frame: CGRect(x: x + 130.0, y: 0.0, width: 20.0, height: 20.0))
                deleteButton.backgroundColor = .white
                deleteButton.cornerRadius = 0.5 * deleteButton.bounds.size.width
                deleteButton.clipsToBounds = true
                deleteButton.tag = tag
                deleteButton.alpha = 0.7
                deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
                images.addSubview(deleteButton)
                
                let image = UIImageView(frame: CGRect(x: x + 135.0, y: 5.0, width: 10.0, height: 10.0))
                image.image = UIImage(named: "close_ic")
                images.addSubview(image)
                
                x += 160
                tag += 1
            }
            images.contentSize = CGSize(width: CGFloat(x), height: images.frame.size.height)
        }
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        imagesArr.remove(at: sender.tag)
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
    
    private func uploadRequest() -> Bool {
        
        let login = UserDefaults.standard.string(forKey: "login")!
        let pass = getHash(pass: UserDefaults.standard.string(forKey: "pass")!, salt: getSalt(login: login))
        let comm = edProblem.text ?? ""
        
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\("Техническое обслуживание".stringByAddingPercentEncodingForRFC3986()!)&name=\("Техническое обслуживание \(formatDate(Date(), format: "dd.MM.yyyy hh:mm:ss"))".stringByAddingPercentEncodingForRFC3986()!)&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)&phonesum=&responsiblePerson=&email=&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(formatDate(Date(), format: "dd.MM.yyyy").stringByAddingPercentEncodingForRFC3986()!)&dateTo=\(String(describing: data!.date).stringByAddingPercentEncodingForRFC3986()!)&dateServiceDesired=\(formatDate(Date(), format: "dd.MM.yyyy").stringByAddingPercentEncodingForRFC3986()!)&clearAfterWork="
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        
        let (responce, _, _) = URLSession.shared.synchronousDataTask(with: request.url!)
        
        if (String(data: responce!, encoding: .utf8)?.contains(find: "error"))! {
            DispatchQueue.main.sync {
                
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            }
            return false
        } else {
            #if DEBUG
                print(String(data: responce!, encoding: .utf8)!)
            #endif
            
            self.reqId = String(data: responce!, encoding: .utf8)
            
            DispatchQueue.main.async {
                DB().setRequests(title: "Техническое обслуживание" + self.formatDate(Date(), format: "dd.MM.yyyy hh:mm:ss"),
                                 desc: self.edProblem.text!,
                                 icon: UIImage(named: "processing_label")!,
                                 date: String(describing: self.data!.date),
                                 status: "В ОБРАБОТКЕ",
                                 isBack: false)
            }
            
            return true
        }
    }
    
    private func uploadPhoto(_ img: UIImage) {
        
        let group = DispatchGroup()
        let reqID = reqId?.stringByAddingPercentEncodingForRFC3986()
        let id = UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986()
        
        group.enter()
        Alamofire.upload(multipartFormData: { multipartFromdata in
            multipartFromdata.append(UIImageJPEGRepresentation(img, 0.5)!, withName: "tech_file", fileName: "tech_file.jpg", mimeType: "image/jpg")
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
            
            #if DEBUG
                print("salt is = \(String(describing: String(data: data!, encoding: .utf8)))")
            #endif
            
            }.resume()
        
        queue.wait()
        return salt!
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: date)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imagesArr.append(image)
        dismiss(animated: true, completion: nil)
    }
    
    private func startAnimator() {
        sendBtn.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimator() {
        sendBtn.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCreateTechService.toService {
            let vc = segue.destination as! TechServiceVC
            vc.isCreate_ = true
            vc.data_ = data!
            vc.reqId_ = reqId!
            vc.delegate = delegate
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if edProblem.text == "" {
            sendBtn.isEnabled   = false
            sendBtn.alpha       = 0.5
        
        } else {
            sendBtn.isEnabled   = true
            sendBtn.alpha       = 1
        }
        return true
    }
    
    private func getConstant() -> CGFloat {
        
        if !isXDevice() {
            return (view.frame.size.height - btnConstant) + 50
        } else {
            return (view.frame.size.height - btnConstant)
        }
    }
}
