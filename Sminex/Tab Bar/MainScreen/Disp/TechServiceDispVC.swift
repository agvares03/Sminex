//
//  TechServiceVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/24/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyXMLParser
import MessageUI

private protocol TechServiceProtocol: class { }
private protocol TechServiceCellsProtocol: class {
    func imagePressed(_ sender: UITapGestureRecognizer)
}

private protocol ContactsCellDelegate: class {
    func phonePressed(_ phone: String)
    func messagePressed(_ phone: String)
}

private protocol WorkerCellDelegate: class {
    func deletePressed(_ name: Int)
}

final class TechServiceDispVC: UIViewController, UITextFieldDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TechServiceCellsProtocol, ContactsCellDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, WorkerCellDelegate{
    
    
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var collection:      UICollectionView!
    @IBOutlet private weak var commentField:    UITextField!
    @IBOutlet private weak var sendBtn:         UIButton!
    @IBOutlet private weak var cameraButton:    UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popToRootViewController(animated: true)
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
        
        if let popoverController = action.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    open var data_: ServiceDispHeaderData = ServiceDispHeaderData(title: "Нс опять топят соседи", date: "9 сентября 10:00", person: "Иванов Иван Иванович", phone: "+79659139567", adres: "Проспект Мира 7")
    
    
    private var arr:    [TechServiceProtocol]    = []
    private var img:    UIImage?
    
    private var rowComms: [String : [RequestComment]]  = [:]
    private var rowFiles:   [RequestFile] = []
    open var worker: [ServiceWorkerCellData] = []
    
    private var refreshControl: UIRefreshControl?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        let icon = UIImage(named: "account")!
        let worker1 = ServiceWorkerCellData(icon: icon, title: "Иванов", desc: "Слесарь", id: 1)
        worker.append(worker1)
        arr = worker
        arr.insert(data_, at: 0)
        
        commentField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: commentField.frame.height))
        commentField.rightViewMode = .always
        collection.delegate     = self
        collection.dataSource   = self
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.global(qos: .background).async {
                sleep(2)
                self.arr = self.worker
                self.arr.insert(self.data_, at: 0)
                DispatchQueue.main.async {
                    self.collection.reloadData()
                    self.view.endEditing(true)
                    
                    // Подождем пока закроется клавиатура
                    DispatchQueue.global(qos: .userInteractive).async {
                        usleep(900000)
                        
                        DispatchQueue.main.async {
                            self.collection.scrollToItem(at: IndexPath(item: self.collection.numberOfItems(inSection: 0) - 1, section: 0), at: .top, animated: true)
                            self.endAnimator()
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                if #available(iOS 10.0, *) {
                    self.collection.refreshControl?.endRefreshing()
                } else {
                    self.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if TemporaryHolder.instance.worker != nil{
            self.worker.append(TemporaryHolder.instance.worker!)
        }
        
        self.arr = self.worker
        self.arr.insert(self.data_, at: 0)
        self.collection.reloadData()
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        if !isPlusDevices() {
            view.frame.origin.y = -250
            collection.contentInset.top = 250
            
        } else {
            view.frame.origin.y = -265
            collection.contentInset.top = 265
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.frame.origin.y = 0
        collection.contentInset.top = 0
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(arr.count)
        return arr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
        
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceDispHeader", for: indexPath) as! ServiceDispHeader
            cell.display((arr[indexPath.row] as! ServiceDispHeaderData), delegate: self, delegate2: self)
            return cell

        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServiceWorkerCell", for: indexPath) as! ServiceWorkerCell
            cell.display((arr[indexPath.row] as! ServiceWorkerCellData), delegate: self, delegate2: self, id: indexPath.row)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if indexPath.row == 0 {
            let cell = ServiceDispHeader.fromNib()
            cell?.display((arr[indexPath.row] as! ServiceDispHeaderData), delegate: self, delegate2: self)
            return CGSize(width: view.frame.size.width, height: 400)
            
        } else {
            let cell = ServiceWorkerCell.fromNib()
            cell?.display((arr[indexPath.row] as! ServiceWorkerCellData), delegate: self, delegate2: self, id: indexPath.row)
            return CGSize(width: view.frame.size.width, height: 70)
        }
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
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func imagePressed(_ sender: UITapGestureRecognizer) {
        imageTapped(sender)
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
    
    func deletePressed(_ name: Int) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Снять сотрудника с этой заявки?", message: "", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Отмена", style: .cancel) { (_) -> Void in }
            let deleteAction = UIAlertAction(title: "Да", style: .destructive) { (_) -> Void in
                
                self.arr.remove(at: name)
                self.collection.reloadData()
            }
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func phonePressed(_ phone: String) {
        let newPhone = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        if let url = URL(string: "tel://" + newPhone) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func messagePressed(_ phone: String) {
        if MFMessageComposeViewController.canSendText() {
            let messageVC = MFMessageComposeViewController()
            messageVC.recipients = [phone]
            messageVC.messageComposeDelegate = self
            present(messageVC, animated: false, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }

}

final class ServiceDispHeader: UICollectionViewCell {
    
    
    @IBOutlet weak var sms: UIImageView!
    @IBOutlet weak var call: UIImageView!
    @IBOutlet private weak var problem:     UILabel!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var person:        UILabel!
    @IBOutlet private weak var phone:        UILabel!
    @IBOutlet private weak var adres:        UILabel! 
    
    
    
    private var delegate: TechServiceCellsProtocol?
    private var delegate2: ContactsCellDelegate?
    
    fileprivate func display(_ item: ServiceDispHeaderData, delegate: TechServiceCellsProtocol, delegate2: ContactsCellDelegate?) {
        
        self.delegate = delegate
        self.delegate2 = delegate2
        problem.text = item.title
        person.text  = item.person
        phone.text   = item.phone
        adres.text   = item.adres
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        date.text = dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") ? dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "") : dayDifference(from: dateFormatter.date(from: item.date) ?? Date(), style: "dd MMMM HH:mm")
        sms.isUserInteractionEnabled = true
        call.isUserInteractionEnabled   = true
        phone.isUserInteractionEnabled        = true
        
        call.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:))) )
        sms.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(messagePressed(_:))) )
        phone.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:))) )
    }
    
    class func fromNib() -> ServiceDispHeader? {
        var cell: ServiceDispHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServiceDispHeader {
                cell = view
            }
        }
        cell?.problem.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 25
        return cell
    }
    @objc private func phonePressed(_ sender: UITapGestureRecognizer) {
        delegate2?.phonePressed(phone.text ?? "")
    }
    @objc private func messagePressed(_ sender: UITapGestureRecognizer) {
        delegate2?.messagePressed(phone.text ?? "")
    }
}

final class ServiceDispHeaderData: TechServiceProtocol {
    
    let title:      String
    let date:       String
    var person:     String
    let phone:      String
    let adres:      String
    
    init(title: String, date: String, person: String, phone: String, adres: String) {
        
        self.title  = title
        self.date   = date
        self.person = person
        self.phone  = phone
        self.adres  = adres
    }
}

final class ServiceWorkerCell: UICollectionViewCell {
    
    @IBOutlet         weak var delete: UIImageView!
    @IBOutlet private weak var icon:        UIImageView!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var desc:        UILabel!
    
    private var delegate: TechServiceCellsProtocol?
    private var delegate2: WorkerCellDelegate?
    private var id: Int = 0
    
    fileprivate func display(_ item: ServiceWorkerCellData, delegate: TechServiceCellsProtocol, delegate2: WorkerCellDelegate, id: Int) {
        
        self.delegate = delegate
        self.delegate2 = delegate2
        self.id = id
        icon.image = item.icon
        title.text = item.title
        desc.text  = item.desc
        delete.isUserInteractionEnabled        = true
        
        delete.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(deletePressed(_:))) )
    }
    
    @objc private func imagePressed(_ sender: UITapGestureRecognizer) {
        delegate?.imagePressed(sender)
    }
    
    @objc private func deletePressed(_ sender: UITapGestureRecognizer) {
        delegate2?.deletePressed(self.id)
    }
    
    class func fromNib() -> ServiceWorkerCell? {
        var cell: ServiceWorkerCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServiceWorkerCell {
                cell = view
            }
        }
        return cell
    }
}

final class ServiceWorkerCellData: TechServiceProtocol {
    
    let icon:   UIImage
    let title:  String
    let desc:   String
    let id: Int
    
    init(icon: UIImage, title: String, desc: String, id: Int) {
        
        self.icon   = icon
        self.title  = title
        self.desc   = desc
        self.id     = id
    }
}

private var imgs: [String:UIImage] = [:]






