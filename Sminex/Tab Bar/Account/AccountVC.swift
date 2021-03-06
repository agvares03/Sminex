//
//  AccountVC.swift
//  Sminex
//
//  Created by IH0kN3m on 5/8/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class AccountVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func lsButtonPressed(_ sender: UIButton) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CustomAlertViewController") as! CustomAlertViewController
        vc.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        self.addChildViewController(vc)
        self.view.addSubview(vc.view)
    }
    
    @IBAction private func exitButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: "Вы действительно хотите выйти?", preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in } ) )
        alert.addAction( UIAlertAction(title: "Выйти", style: .default, handler: { (_) in self.exit() } ) )
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func sminexButtonPressed(_ sender: UIButton) {
        if let url = URL(string: "http://www.sminex.com") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url,
                                          options: [:],
                                          completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.barTintColor = navigationGrayColor
        navigationItem.leftBarButtonItem = nil
        navigationItem.hidesBackButton   = true
        updateUserInterface()
//        collection.contentInset = UIEdgeInsets(top: -20, left: 0, bottom: 20, right: 0)
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
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
        collection.reloadData()
        tabBarController?.tabBar.isHidden = false
//        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
//        navigationController?.isNavigationBarHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AccountCell", for: indexPath) as! AccountCell
            return cell
        
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AccountExitCell", for: indexPath) as! AccountExitCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AccountHeader", for: indexPath) as! AccountHeader
        header.display()
        
//        if #available(iOS 11.0, *) {
//            header.headerView.clipsToBounds = false
//            header.headerView.layer.cornerRadius = 8
//            header.headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//        } else {
//            let rectShape = CAShapeLayer()
//            rectShape.bounds = header.headerView.frame
//            rectShape.position = header.headerView.center
//            rectShape.path = UIBezierPath(roundedRect: header.headerView.bounds, byRoundingCorners: [.topRight , .topLeft], cornerRadii: CGSize(width: 8, height: 8)).cgPath
//            header.headerView.layer.mask = rectShape
//        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 60.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        let header = AccountHeader.fromNib()
        header?.display()
        let size = header?.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: view.frame.size.width, height: 780.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            performSegue(withIdentifier: Segues.fromAccountVC.toSettings, sender: self)
        }
    }
    
    private func exit() {
        UserDefaults.standard.removeObject(forKey: "dealsJSON")
        UserDefaults.standard.removeObject(forKey: "deals")
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pwd = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let deviceId = UserDefaults.standard.string(forKey: "googleToken") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.DELETE_CLIENT + "login=\(login)&pwd=\(pwd)&deviceid=\(deviceId)")!)
        request.httpMethod = "GET"
        print(request)
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
        }.resume()
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "pass"), forKey: "exitPass")
        UserDefaults.standard.setValue(UserDefaults.standard.string(forKey: "login"), forKey: "exitLogin")
        UserDefaults.standard.setValue("", forKey: "pass")
        UserDefaults.standard.setValue("", forKey: "pwd")
        UserDefaults.standard.removeObject(forKey: "accountIcon")
        UserDefaults.standard.removeObject(forKey: "googleToken")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "DealsImg")
        UserDefaults.standard.removeObject(forKey: "newsList")
        UserDefaults.standard.removeObject(forKey: "newsLastId")
        UserDefaults.standard.synchronize()
        present(UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!, animated: true, completion: nil)
    }
}

final class AccountHeader: UICollectionReusableView {
    
    @IBOutlet private weak var bcImageView:         UIImageView!
    @IBOutlet private weak var accImageView:        UIImageView!
    @IBOutlet private weak var accName:             UILabel!
    @IBOutlet private weak var bcName:              UILabel!
    @IBOutlet private weak var lsLabel:             UILabel!
    @IBOutlet private weak var descLabel:           UILabel!
    @IBOutlet private weak var streetLabel:         UILabel!
    @IBOutlet private weak var roomLabel:           UILabel!
    @IBOutlet private weak var generalLabel:        UILabel!
    @IBOutlet private weak var habitableLabel:      UILabel!
    @IBOutlet private weak var holderLabel:         UILabel!
    @IBOutlet private weak var holderPhoneLabel:    UILabel!
    @IBOutlet         weak var headerView:          UIView!
    
    func display() {
        
        accImageView.cornerRadius = accImageView.frame.height / 2
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageData = UserDefaults.standard.object(forKey: "accountIcon"),
                let image = UIImage(data: imageData as! Data) {
                DispatchQueue.main.async {
                    self.accImageView.image = image
                }
            }else{
                DispatchQueue.main.async {
                    self.accImageView.image = UIImage(named: "default_userpic")
                }
            }
        }
        let defaults = UserDefaults.standard
        accName.text = defaults.string(forKey: "name")?.replacingOccurrences(of: "- ", with: "")
        bcName.text = defaults.string(forKey: "buisness")
        lsLabel.text = defaults.string(forKey: "login")
        streetLabel.text = defaults.string(forKey: "adress")
        if (defaults.string(forKey: "adress") == "-") {
            streetLabel.text = " "
        }
        roomLabel.text = defaults.string(forKey: "roomsCount")
        if (defaults.string(forKey: "roomsCount") == "-") {
            roomLabel.text = " "
        }
        generalLabel.text = (defaults.string(forKey: "totalArea") ?? "") + " м²"
        habitableLabel.text = (defaults.string(forKey: "residentialArea") ?? "") + " м²"
        holderPhoneLabel.text = defaults.string(forKey: "contactNumber")
        if (defaults.string(forKey: "contactNumber") == "-") {
            holderPhoneLabel.text = " "
        }
        holderLabel.text = defaults.string(forKey: "name")!.replacingOccurrences(of: "- ", with: "")
        descLabel.text   = defaults.string(forKey: "accDesc")
        if (defaults.string(forKey: "accDesc") == "-") {
            descLabel.text = " "
        }
        
        holderPhoneLabel.isUserInteractionEnabled  = true
//        comfortPhoneLabel.isUserInteractionEnabled = true
        holderPhoneLabel.addGestureRecognizer(  UITapGestureRecognizer(target: self, action: #selector(holderPhonePressed(_:))) )
//        comfortPhoneLabel.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:))))
//        let contacts:[ContactsJson] = TemporaryHolder.instance.contactsList
//        contacts.forEach{
//            if ($0.name?.contains(find: "сьерж"))!{
//                comfortPhoneLabel.text = $0.phone
//            }
//        }
//        if TemporaryHolder.instance.bcImage != nil {
//            bcImageView.image = TemporaryHolder.instance.bcImage
//
//        } else {
//            if let img = defaults.data(forKey: "BCImage") {
//                bcImageView.image = UIImage(data: img)
//            }
//            DispatchQueue.global(qos: .background).async {
//                TemporaryHolder.instance.bcQueue.wait()
//                if TemporaryHolder.instance.bcImage != nil {
//                    DispatchQueue.main.async {
//                        self.bcImageView.image = TemporaryHolder.instance.bcImage
//                    }
//
//                } else {
//                    DispatchQueue.main.async {
//                        self.bcImageView.image = UIImage(named: "bcImg")
//                    }
//                }
//            }
//        }
    }
    
    @objc private func holderPhonePressed(_ sender: UITapGestureRecognizer) {
        let newPhone = holderPhoneLabel.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "") ?? ""
        if let url = URL(string: "tel://+" + newPhone) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @objc private func phonePressed(_ sender: UITapGestureRecognizer) {
//        let phone = comfortPhoneLabel.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "") ?? ""
//        if let url = URL(string: "tel://" + phone) {
//            if #available(iOS 10.0, *) {
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//            } else {
//                UIApplication.shared.openURL(url)
//            }
//        }
    }
    
    class func fromNib() -> AccountHeader? {
        var cell: AccountHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AccountHeader {
                cell = view
            }
        }
        cell?.descLabel.preferredMaxLayoutWidth = cell?.descLabel.bounds.width ?? 0.0
        cell?.streetLabel.preferredMaxLayoutWidth = cell?.streetLabel.bounds.width ?? 0.0
        return cell
    }
}

final class AccountCell: UICollectionViewCell {}
final class AccountExitCell: UICollectionViewCell {}









