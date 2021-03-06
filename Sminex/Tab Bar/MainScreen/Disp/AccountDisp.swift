//
//  AccountVC.swift
//  Sminex
//
//  Created by IH0kN3m on 5/8/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class AccountDisp: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func exitButtonPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: "Вы действительно хотите выйти?", preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in } ) )
        alert.addAction( UIAlertAction(title: "Выйти", style: .default, handler: { (_) in self.exit() } ) )
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction private func editButtonPressed(_ sender: UIButton) {
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
        
        //        collection.contentInset = UIEdgeInsets(top: -20, left: 0, bottom: 20, right: 0)
        
        collection.dataSource = self
        collection.delegate   = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        collection.reloadData()
        tabBarController?.tabBar.isHidden = false
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AccountDispCell", for: indexPath) as! AccountDispCell
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DispExitCell", for: indexPath) as! DispExitCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "AccountDispHeader", for: indexPath) as! AccountDispHeader
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
        
        let header = AccountDispHeader.fromNib()
        header?.display()
        let size = header?.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: view.frame.size.width, height: 533.0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            performSegue(withIdentifier: Segues.fromAccountVC.toSettings, sender: self)
        }
    }
    
    private func exit() {
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

final class AccountDispHeader: UICollectionReusableView {
    
    @IBOutlet private weak var accImageView:        UIImageView!
    @IBOutlet private weak var accName:             UILabel!
    @IBOutlet private weak var bcName:              UILabel!
    @IBOutlet private weak var jkLabel:             UILabel!
    @IBOutlet private weak var descLabel:           UILabel!
    @IBOutlet private weak var streetLabel:         UILabel!
    @IBOutlet private weak var holderLabel:         UILabel!
    @IBOutlet private weak var holderPhoneLabel:    UILabel!
    @IBOutlet private weak var comfortLabel:        UILabel!
    @IBOutlet private weak var comfortPhoneLabel:   UILabel!
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
        _ = UserDefaults.standard
        accName.text = "Жанна Николаевна"
        bcName.text = "Диспетчер"
        jkLabel.text = "Премиум квартал РЕНОМЭ"
        streetLabel.text = "Сущевский Вал, 49"
//        if (defaults.string(forKey: "adress") == "-") {
//            streetLabel.text = " "
//        }
        holderPhoneLabel.text = "+7 999 997 67 45"
//        if (defaults.string(forKey: "contactNumber") == "-") {
//            holderPhoneLabel.text = " "
//        }
//        holderLabel.text = defaults.string(forKey: "name")
        descLabel.text   = "Работаю с 10:00 до 19:00"
//        if (defaults.string(forKey: "accDesc") == "-") {
//            descLabel.text = " "
//        }
        
        holderPhoneLabel.isUserInteractionEnabled  = true
        comfortPhoneLabel.isUserInteractionEnabled = true
        holderPhoneLabel.addGestureRecognizer(  UITapGestureRecognizer(target: self, action: #selector(holderPhonePressed(_:))) )
        comfortPhoneLabel.addGestureRecognizer( UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:))))
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
        let phone = "+74957266791"
        if let url = URL(string: "tel://" + phone) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    class func fromNib() -> AccountDispHeader? {
        var cell: AccountDispHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? AccountDispHeader {
                cell = view
            }
        }
        cell?.descLabel.preferredMaxLayoutWidth = cell?.descLabel.bounds.width ?? 0.0
        cell?.streetLabel.preferredMaxLayoutWidth = cell?.streetLabel.bounds.width ?? 0.0
        return cell
    }
}

final class AccountDispCell: UICollectionViewCell {}
final class DispExitCell: UICollectionViewCell {}









