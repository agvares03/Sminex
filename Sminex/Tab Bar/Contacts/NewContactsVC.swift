//
//  NewContactsVC.swift
//  Sminex
//
//  Created by Sergey Ivanov on 02/03/2020.
//

import UIKit
import MessageUI
import Gloss
import DeviceKit

private protocol ContactsCellDelegate: class {
    func phonePressed(_ phone: String)
    func messagePressed(_ phone: String)
    func emailPressed(_ mail: String)
    func btnPressed(_ type: Int, _ email: String)
}

class NewContactsVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ContactsCellDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate{
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    
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
        data_ = TemporaryHolder.instance.contactsList
        collection.reloadData()
        //        navigationController?.isNavigationBarHidden = true
        tabBarController?.tabBar.isHidden = false
    }
    private var data_: [ContactsJson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        updateUserInterface()
        automaticallyAdjustsScrollViewInsets = false
        data_ = TemporaryHolder.instance.contactsList
        collection.dataSource = self
        collection.delegate   = self
        
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
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
//        navigationController?.isNavigationBarHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewContactsCell", for: indexPath) as! NewContactsCell
        cell.display(data_[indexPath.row], delegate: self, viewSize: self.view.frame.size.width, rowNum: indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ContactsHeader", for: indexPath) as! ContactsHeader
        header.display("Контакты")
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = NewContactsCell.fromNib()
        cell?.display(data_[indexPath.row], delegate: self, viewSize: self.view.frame.size.width, rowNum: indexPath.row)
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        let isSupport = data_[indexPath.row].name?.contains(find: "оддержка") ?? false
//        return CGSize(width: view.frame.size.width, height: isSupport ? size.height + 5 : size.height - 18)
        if data_[indexPath.row].phone != nil && data_[indexPath.row].phone != ""{
        } else {
            if data_[indexPath.row].isVisibleEmail! == false{
                return CGSize(width: view.frame.size.width, height: 0)
            }
        }
        if (data_[indexPath.row].name?.contains(find: "Предложения"))! {
//            if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) || Device() == .iPhone4s || Device() == .simulator(.iPhone4s) || Device() == .iPhone5 || Device() == .simulator(.iPhone5) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c){
//                return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 30)
//            }else if Device() == .iPhoneX || Device() == .simulator(.iPhoneX) {
//                return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 40)
//            }else{
//                return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 40)
//            }
            return CGSize(width: view.frame.size.width, height: isSupport ? size.height : size.height - 10)
        }
        if (data_[indexPath.row].name?.contains(find: "Консьерж"))! {
            return CGSize(width: view.frame.size.width, height: isSupport ? size.height : size.height)
        }
//        return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 20)
        return CGSize(width: view.frame.size.width, height: isSupport ? size.height : size.height - 20)
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
    
    func emailPressed(_ mail: String) {
        if MFMailComposeViewController.canSendMail() {
            let email = MFMailComposeViewController()
            email.mailComposeDelegate = self
            email.setToRecipients([mail])
            present(email, animated: true)
        } else {
            
            let alert = UIAlertController(title: nil, message: "Пожалуйста, настройте почту на вашем телефоне", preferredStyle: .alert)
            alert.addAction( UIAlertAction(title: "Открыть настройки", style: .default, handler: { (_) in
                
                if let url = URL(string:UIApplicationOpenSettingsURLString), UIApplication.shared.canOpenURL(url) {
                    
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:]) { (_) in }
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            } ) )
            alert.addAction( UIAlertAction(title: "Отменить", style: .default, handler: { (_) in } ) )
            present(alert, animated: true, completion: nil)
        }
    }
    var typeRequest = 0
    var selEmail = ""
    func btnPressed(_ type: Int, _ email: String) {
        typeRequest = type
        selEmail = email
        performSegue(withIdentifier: "addAppeal", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addAppeal" {
            let vc = segue.destination as! AppealUser
            vc.isCreatingRequest_ = true
            vc.selEmail = selEmail
            if typeRequest == 0{
                vc.typeReq = "Консьержу/ в службу комфорта"
            }else if typeRequest == 1{
                vc.typeReq = "Директору службы комфорта"
            }else if typeRequest == 2{
                vc.typeReq = "В техподдержку приложения"
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

final class NewContactsCell: UICollectionViewCell {
    
    @IBOutlet private weak var sendBtnHeight:   NSLayoutConstraint!
    @IBOutlet private weak var phoneHeight:     NSLayoutConstraint!
    @IBOutlet private weak var emailHeight:     NSLayoutConstraint!
    @IBOutlet private weak var btnTopHeight:    NSLayoutConstraint!
    @IBOutlet private weak var titleHeight:     NSLayoutConstraint!
    @IBOutlet private weak var descHeight:      NSLayoutConstraint!
    @IBOutlet private weak var fonHeight:       NSLayoutConstraint!
    @IBOutlet private weak var fonWidth:        NSLayoutConstraint!
    @IBOutlet private weak var fonTop:          NSLayoutConstraint!
    @IBOutlet private weak var messageImage:    UIImageView!
    @IBOutlet private weak var phoneImage:      UIImageView!
    @IBOutlet private weak var fonImage:        UIImageView!
    @IBOutlet private weak var emailImage:      UIImageView!
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var desc:            UILabel!
    @IBOutlet private weak var phone:           UILabel!
    @IBOutlet private weak var email:           UILabel!
    @IBOutlet private weak var phoneView:       UIView!
    @IBOutlet private weak var emailView:       UIView!
    @IBOutlet private weak var cellView:        UIView!
    
    private var delegate: ContactsCellDelegate?
    
    fileprivate func display(_ item: ContactsJson, delegate: ContactsCellDelegate?, viewSize: CGFloat, rowNum: Int) {
        self.delegate = delegate
        title.text = item.name
        desc.text  = item.description
        sendBtnHeight.constant = 42
//        if item.name?.contains(find: "оддержка") ?? false {
//            item.email = ""
//        }
        if item.isVisibleCreate! == false{
            sendBtnHeight.constant = 0
        }else{
            sendBtnHeight.constant = 42
        }
        if item.phone != nil && item.phone != ""{
            phoneHeight.constant = 70.5
            phoneView.isHidden   = false
            
            if item.email != nil && item.email != "" && item.isVisibleEmail!{
                emailView.isHidden   = false
                emailHeight.constant = 50 //75
                phone.text           = item.phone
                email.text           = item.email
                btnTopHeight?.constant = 20
            } else {
                phone.text           = item.phone
                emailHeight.constant = 0
                emailView.isHidden   = true
                email.text = item.email
                btnTopHeight?.constant = 5
            }
        
        } else {
            phoneView.isHidden   = true
            phoneHeight.constant = 0
            email.text           = item.email
            emailHeight.constant = 75
            btnTopHeight?.constant = 5
            if item.isVisibleEmail! == false{
                emailHeight.constant = 0
                emailView.isHidden   = true
            }
        }
        if rowNum == 0{
            fonImage.image = UIImage(named: "contacts_fon")!
            fonWidth.constant = 217
            fonHeight.constant = 160
            fonImage.isHidden = false
            fonTop.constant = 50
        }else if (item.name?.containsIgnoringCase(find: "поддержка"))!{
            fonImage.image = UIImage(named: "support_fon")!
            fonWidth.constant = 170
            fonHeight.constant = 110
            fonImage.isHidden = false
            fonTop.constant = 50
        }else{
            fonImage.isHidden = true
            fonHeight.constant = 0
            fonTop.constant = 10
        }
        titleHeight.constant = heightForTitle(text: item.name!, width: title.frame.size.width)
        if (item.name?.containsIgnoringCase(find: "поддержка мобильного"))!{
            titleHeight.constant = 50
            title.text = "Поддержка мобильного\nприложения"
        }
        descHeight.constant = heightForTitle(text: item.description!, width: desc.frame.size.width)
        messageImage.isUserInteractionEnabled = true
        phoneImage.isUserInteractionEnabled   = true
        emailImage.isUserInteractionEnabled   = true
        email.isUserInteractionEnabled        = true
        phone.isUserInteractionEnabled        = true
        
        email.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(emailPressed(_:))) )
        phone.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:))) )
        messageImage.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(messagePressed(_:))) )
        phoneImage.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:))) )
        emailImage.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(emailPressed(_:))) )
        
        
        cornerRadius = 16
//        dropShadow(superview: self)
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    class func fromNib() -> NewContactsCell? {
        var cell: NewContactsCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? NewContactsCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width ?? 0.0
        return cell
    }
    
    @objc private func phonePressed(_ sender: UITapGestureRecognizer) {
        delegate?.phonePressed(phone.text ?? "")
    }
    @objc private func messagePressed(_ sender: UITapGestureRecognizer) {
//        delegate?.messagePressed(phone.text ?? "")
        var type = 0
        if (title.text?.containsIgnoringCase(find: "консьерж"))!{
            type = 0
        }else if (title.text?.containsIgnoringCase(find: "предложения"))!{
            type = 1
        }else if (title.text?.containsIgnoringCase(find: "поддержка"))!{
            type = 2
        }
        delegate?.btnPressed(type, email.text ?? "")
    }
    @objc private func emailPressed(_ sender: UITapGestureRecognizer) {
        delegate?.emailPressed(email.text ?? "")
    }
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        var type = 0
        if (title.text?.containsIgnoringCase(find: "консьерж"))!{
            type = 0
        }else if (title.text?.containsIgnoringCase(find: "предложения"))!{
            type = 1
        }else if (title.text?.containsIgnoringCase(find: "поддержка"))!{
            type = 2
        }
        delegate?.btnPressed(type, email.text ?? "")
    }
}

