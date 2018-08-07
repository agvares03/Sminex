//
//  ContactsVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import MessageUI
import Gloss

private protocol ContactsCellDelegate: class {
    func phonePressed(_ phone: String)
    func messagePressed(_ phone: String)
    func emailPressed(_ mail: String)
}

final class ContactsVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ContactsCellDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate{
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Segues.fromContactsVc.toSupport, sender: self)
    }
    
    private var data_: [ContactsJson] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        data_ = TemporaryHolder.instance.contactsList
        collection.dataSource = self
        collection.delegate   = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        data_ = TemporaryHolder.instance.contactsList
        collection.reloadData()
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactsCell", for: indexPath) as! ContactsCell
        cell.display(data_[indexPath.row], delegate: self)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ContactsHeader", for: indexPath) as! ContactsHeader
        header.display("Контакты")
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = ContactsCell.fromNib()
        cell?.display(data_[indexPath.row], delegate: self)
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        let isSupport = data_[indexPath.row].name?.contains(find: "оддержка") ?? false
//        return CGSize(width: view.frame.size.width, height: isSupport ? size.height + 5 : size.height - 18)
        
        if (data_[indexPath.row].name?.contains(find: "Предложения"))! {
            if (UIDevice.current.modelName.contains(find: "iPhone 4")) ||
                (UIDevice.current.modelName.contains(find: "iPhone 4s")) ||
                (UIDevice.current.modelName.contains(find: "iPhone 5")) ||
                (UIDevice.current.modelName.contains(find: "iPhone 5c")) ||
                (UIDevice.current.modelName.contains(find: "iPhone 5s")) ||
                (UIDevice.current.modelName.contains(find: "iPhone SE")) {
//                          ||  (UIDevice.current.modelName.contains(find: "Simulator")) {
                return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 20)
            }
            return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 40)
        }
        
        return CGSize(width: view.frame.size.width, height: isSupport ? size.height - 10 : size.height - 20)
    }
    
    func phonePressed(_ phone: String) {
        let newPhone = phone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        if let url = URL(string: "tel://" + newPhone) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
                    
                    UIApplication.shared.open(url, options: [:]) { (_) in }
                }
            } ) )
            alert.addAction( UIAlertAction(title: "Отменить", style: .default, handler: { (_) in } ) )
            present(alert, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}


final class ContactsHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title: UILabel!
    
    func display(_ title: String) {
        self.title.text = title
    }
}

final class ContactsCell: UICollectionViewCell {
    
    @IBOutlet private weak var sendBtnHeight:   NSLayoutConstraint!
    @IBOutlet private weak var phoneHeight:     NSLayoutConstraint!
    @IBOutlet private weak var emailHeight:     NSLayoutConstraint!
    @IBOutlet private weak var messageImage:    UIImageView!
    @IBOutlet private weak var phoneImage:      UIImageView!
    @IBOutlet private weak var emailImage:      UIImageView!
    @IBOutlet private weak var title:           UILabel!
    @IBOutlet private weak var desc:            UILabel!
    @IBOutlet private weak var phone:           UILabel!
    @IBOutlet private weak var email:           UILabel!
    @IBOutlet private weak var phoneView:       UIView!
    @IBOutlet private weak var emailView:       UIView!
    @IBOutlet private weak var cellView:        UIView!
    
    private var delegate: ContactsCellDelegate?
    
    fileprivate func display(_ item: ContactsJson, delegate: ContactsCellDelegate?) {
        self.delegate = delegate
        
        title.text = item.name
        desc.text  = item.description
        
        if item.name?.contains(find: "оддержка") ?? false {
            sendBtnHeight.constant = 45
            item.email = ""
        
        } else {
            sendBtnHeight.constant = 0
        }
        
        if item.phone != nil && item.phone != "" {
            phoneHeight.constant = 70.5
            phoneView.isHidden   = false
            
            if item.email != nil && item.email != "" {
                emailView.isHidden   = false
                emailHeight.constant = 50 //75
                phone.text           = item.phone
                email.text           = item.email
            
            } else {
                phone.text           = item.phone
                emailHeight.constant = 0
                emailView.isHidden   = true
            }
        
        } else {
            phoneView.isHidden   = true
            phoneHeight.constant = 0
            email.text           = item.email
        }
        
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
    
    class func fromNib() -> ContactsCell? {
        var cell: ContactsCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ContactsCell {
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
        delegate?.messagePressed(phone.text ?? "")
    }
    @objc private func emailPressed(_ sender: UITapGestureRecognizer) {
        delegate?.emailPressed(email.text ?? "")
    }
}


final class ContactsDataJson: JSONDecodable {
    
    let data: [ContactsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

final class ContactsJson: JSONDecodable {
    
    let name: String?
    let description: String?
    let phone: String?
    var email: String?
    
    init?(json: JSON) {
        description = "Description" <~~ json
        phone       = "Phone"       <~~ json
        email       = "Email"       <~~ json
        name        = "Name"        <~~ json
    }
}












