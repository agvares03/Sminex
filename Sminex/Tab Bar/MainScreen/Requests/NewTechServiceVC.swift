//
//  NewTechServiceVC.swift
//  Sminex
//
//  Created by Anton Barbyshev on 23.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit
import AFDateHelper
import Alamofire
import SimpleImageViewer

private enum ContentType {
    case detailsText
    case time
    case chooseTime
    case photos
}

class NewTechServiceVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var loader: UIActivityIndicatorView!
    @IBOutlet private weak var sendBtn: UIButton!
    @IBOutlet private weak var btnViewConstraint: NSLayoutConstraint!
    
    // MARK: Properties
    
    var type_: RequestTypeStruct?
    var delegate: AppsUserDelegate?
    
    private var reqId:  String?
    private var contents: [ContentType] = [.detailsText, .time]
    private var detailText = "" {
        didSet {
            if detailText.count == 0 {
                sendBtn.isEnabled = false
                sendBtn.alpha = 0.5
            } else {
                sendBtn.isEnabled  = true
                sendBtn.alpha = 1
            }
        }
    }
    private var date = Date()
    private var data: ServiceHeaderData?
    private var images = [UIImage]() {
        didSet {
            if images.count != 0 && oldValue.count == 0 {
                contents.append(.photos)
                tableView.reloadData()
            } else if images.count == 0 {
                contents.removeLast()
                tableView.reloadData()
            } else {
                let rows = tableView.numberOfRows(inSection: 0)
                tableView.reloadRows(at: [IndexPath(row: rows - 1, section: 0)], with: .fade)
            }
        }
    }
    
    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        endAnimator()
        
        sendBtn.isEnabled = false
        sendBtn.alpha = 0.5
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        edFio.becomeFirstResponder()
    }
    // MARK: Functions
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardSize = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        if !isXDevice() {
            btnViewConstraint.constant = (keyboardSize?.height)! - 10
        }else{
            btnViewConstraint.constant = ((keyboardSize?.height)! - 45)
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide() {
        btnViewConstraint.constant = 0
    }
    
    // MARK: Private functions
    
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
    
    private func uploadRequest() {
        
        let login = UserDefaults.standard.string(forKey: "login")!
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let comm = detailText
        
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(type_?.id?.stringByAddingPercentEncodingForRFC3986() ?? "")&name=\("Техническое обслуживание \(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))".stringByAddingPercentEncodingForRFC3986()!)&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)&phonenum=\(UserDefaults.standard.string(forKey: "contactNumber") ?? "")&email=\(UserDefaults.standard.string(forKey: "mail") ?? "")&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(date.toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&dateTo=\(date.toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=\(date.toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&clearAfterWork=&PeriodFrom=\(date.toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
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
                        self.delegate?.update()
                        self.performSegue(withIdentifier: Segues.fromCreateTechService.toService, sender: self)
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

    // MARK: Actions
    
    @IBAction private func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
        view.endEditing(true)
        let action = UIAlertController(title: "Удалить заявку? ", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in self.navigationController?.popViewController(animated: true) }))
        present(action, animated: true, completion: nil)
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
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
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        
        view.endEditing(true)
        startAnimator()
        data = ServiceHeaderData(icon: UIImage(named: "account")!,
                                 problem: detailText,
                                 date: date.toString(format: .custom("dd.MM.yyyy HH:mm:ss")),
                                 status: "В ОБРАБОТКЕ",
                                 images: images, isPaid: "0")
        uploadRequest()
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCreateTechService.toService {
            let vc = segue.destination as! TechServiceVC
            vc.isCreate_ = true
            vc.data_ = data ?? ServiceHeaderData(icon: UIImage(), problem: "", date: "", status: "", isPaid: "0")
            vc.reqId_ = reqId ?? ""
            vc.delegate = delegate
        }
    }

}

extension NewTechServiceVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        images.append(image)
        dismiss(animated: true, completion: nil)
    }
    
}

extension NewTechServiceVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let content = contents[indexPath.row]
        
        switch content {
        case .detailsText:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell", for: indexPath) as! TextViewCell
            cell.delegate = self
            cell.textView.text = detailText
            return cell
        case .time:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimeCell", for: indexPath)
            cell.detailTextLabel?.text = date.toString(format: .custom("dd MMMM HH:mm"))
            return cell
        case .chooseTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DatePickerCell", for: indexPath) as! DatePickerCell
            cell.delegate = self
            cell.configure(date: date)
            return cell
        case .photos:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhotosCell", for: indexPath) as! PhotosCell
            cell.delegate = self
            cell.configure(images: images)
            cell.separatorInset = UIEdgeInsetsMake(0.0, cell.bounds.size.width, 0.0, 0.0)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            if contents.contains(.chooseTime) {
                contents.remove(at: 2)
            } else {
                contents.insert(.chooseTime, at: 2)
            }
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = UITableViewAutomaticDimension
        let content = contents[indexPath.row]
        
        switch content {
        case .detailsText:
            break
        case .time:
            height = 60
        case .chooseTime:
            height = 150
        case .photos:
            height = 176
        }
        return height
    }
    
}

extension NewTechServiceVC: TextViewCellDelegate {
    
    func textViewCell(cell: TextViewCell, didChangeText text: String) {
        detailText = text
        let size = cell.textView.frame.size
        let newSize = cell.textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        if size.height != newSize.height {
            cell.textView.frame.size = newSize
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension NewTechServiceVC: DatePickerCellDelegate {
    
    func dateDidChange(date: Date) {
        self.date = date
    }
    
}

extension NewTechServiceVC: PhotosCellDelegate {
    
    func photoDidDelete(index: Int) {
        images.remove(at: index)
    }
    
    func photoDidOpen(sender: PhotoCell) {
        let configuration = ImageViewerConfiguration { config in
            config.imageView = sender.imageView
        }
        
        let imageViewerController = ImageViewerController(configuration: configuration)
        
        present(imageViewerController, animated: true)
    }
    
}
