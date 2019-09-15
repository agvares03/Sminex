//
//  DealsListVC.swift
//  Sminex
//
//  Created by IH0kN3m on 4/10/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import DeviceKit

final class DealsListVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    public var pressedData_: DealsJson?
    public var data_: [DealsJson] = []
    private var index = 0
    public var kol = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TemporaryHolder.instance.menuDeals = 0
        updateUserInterface()
        if pressedData_ != nil {
            performSegue(withIdentifier: Segues.fromDealsListVC.toDealsAnim, sender: self)
        }
        automaticallyAdjustsScrollViewInsets = false
        
        collection.delegate     = self
        collection.dataSource   = self
        
        if data_.count == 0 {
            startAnimator()
            getDeals()
        
        } else {
            stopAnimator()
        }
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключение к интернету", preferredStyle: .alert)
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
        kol = 0
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cell = DealsListCell.fromNib()
        cell?.display(data_[indexPath.row])
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
        return CGSize(width: view.frame.size.width, height: size.height + 35)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DealsListCell", for: indexPath) as! DealsListCell
        cell.display(data_[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromDealsListVC.toDealsDesc, sender: self)
    }
    
    private final func getDeals() {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PROPOSALS + "ident=\(UserDefaults.standard.string(forKey: "login") ?? "")" + "&isIOS=1")!)
        request.httpMethod = "GET"
        print(request)
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.collection.reloadData()
                    self.stopAnimator()
                }
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.data_ = (DealsDataJson(json: json!)?.data)!
            }
//            var kol = 0
            self.data_.forEach{
                if !$0.isReaded!{
                    self.sendRead(dealsID: $0.id!)
                }
            }
//            TemporaryHolder.instance.menuDeals = kol
            TemporaryHolder.instance.menuDeals = 0
            #if DEBUG
//                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
        
        }.resume()
    }
    
    private func sendRead(dealsID: Int) {
        let id = UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986() ?? ""
        let idDeals = String(dealsID).stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + "SetProposalsReadedState.ashx?" + "proposalID=" + idDeals + "&accID=" + id)!)
        request.httpMethod = "GET"
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? true) else {
                let alert = UIAlertController(title: "Ошбика сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            #if DEBUG
            print(String(data: data!, encoding: .utf8)!)
            
            #endif
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromDealsListVC.toDealsDesc {
            let vc = segue.destination as! DealsListDescVC
            vc.data_ = data_[index]
            vc.anotherDeals_ = data_
        
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
        } else if segue.identifier == Segues.fromDealsListVC.toDealsAnim {
            let vc = segue.destination as! DealsListDescVC
            vc.data_ = pressedData_!
            vc.anotherDeals_ = data_
        }
    }
    
    private func startAnimator() {
        collection.alpha = 0
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func stopAnimator() {
        collection.alpha = 1
        loader.isHidden = true
        loader.stopAnimating()
    }
}

final class DealsListCell: UICollectionViewCell {
    
    @IBOutlet         weak var imageHeight: NSLayoutConstraint!
    @IBOutlet         weak var imageWidth:  NSLayoutConstraint!
    @IBOutlet private weak var image:       UIImageView!
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var desc:        UILabel!
    
    fileprivate func display(_ item: DealsJson) {
        
        image.image         = item.img
        let width:Double = Double((item.img?.size.width)!)
        let height1:Double = Double((item.img?.size.height)!)
        let r: Double =  width / height1
        if r < 1.5{
            image.contentMode = .scaleToFill
        }
        title.text          = item.name
        desc.text           = item.desc
        
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        if (250.0...280.0).contains(points) {
            title.font = title.font.withSize(30)
            desc.font = desc.font.withSize(28)
            imageWidth.constant  = 834
            imageHeight.constant = 455
        }else if (300.0...320.0).contains(points) {
            imageWidth.constant  = 288
            imageHeight.constant = 144
            image.contentMode = .scaleToFill
        } else if (320.0...350.0).contains(points) {
            imageWidth.constant  = 343
            imageHeight.constant = 174
            image.contentMode = .scaleToFill
            if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) || Device() == .iPhone5s || Device() == .simulator(.iPhone5s) || Device() == .iPhone5c || Device() == .simulator(.iPhone5c) || Device() == .iPhone5 || Device() == .simulator(.iPhone5){
                imageWidth.constant  = 288
                imageHeight.constant = 144
            }
        } else if (350.0...400.0).contains(points) {
            imageWidth.constant  = 343
            imageHeight.constant = 170
            image.contentMode = .scaleToFill
        } else if (400.0...450.0).contains(points) {
            imageWidth.constant  = 382
            imageHeight.constant = 180
            image.contentMode = .scaleToFill
        } else {
            imageWidth.constant  = 302
            imageHeight.constant = 151
            image.contentMode = .scaleToFill
        }
    }
    
    class func fromNib() -> DealsListCell? {
        var cell: DealsListCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? DealsListCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width ?? 0.0
        
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        print(points)
        
        if (250.0...280.0).contains(points) {
            cell?.title.font = cell?.title.font.withSize(30)
            cell?.desc.font = cell?.desc.font.withSize(30)
            cell?.imageWidth.constant  = 834
            cell?.imageHeight.constant = 455
        }else if (300.0...320.0).contains(points) {
            cell?.imageWidth.constant  = 288
            cell?.imageHeight.constant = 144
            
        } else if (320.0...350.0).contains(points) {
            cell?.imageWidth.constant  = 302
            cell?.imageHeight.constant = 151
            
        } else if (350.0...400.0).contains(points) {
            cell?.imageWidth.constant  = 343
            cell?.imageHeight.constant = 170
            
        } else if (400.0...450.0).contains(points) {
            cell!.imageWidth.constant  = 382
            cell!.imageHeight.constant = 180
        } else {
            cell?.imageWidth.constant  = 302
            cell?.imageHeight.constant = 151
        }

        return cell
    }
}

struct DealsDataJson: JSONDecodable {
    
    let data: [DealsJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct DealsJson: JSONDecodable {
    
    let img:        UIImage?
    let picture:    String?
    let dateStop:   String?
    let dateStart:  String?
    let priority:   String?
    let name: 	    String?
    let desc: 	    String?
    let body:       String?
    let link:       String?
    let delay:      Int?
    let id:         Int?
    let isReaded:   Bool?
    
    init?(json: JSON) {
        
        picture     = "Picture"     <~~ json
        dateStop    = "DateStop"    <~~ json
        dateStart   = "DateStart"   <~~ json
        priority    = "Priority"    <~~ json
        name        = "Name"        <~~ json
        desc        = "Description" <~~ json
        body        = "Body"        <~~ json
        link        = "Link"        <~~ json
        delay       = "Delay"       <~~ json
        id          = "ID"          <~~ json
        isReaded    = "IsReaded"    <~~ json
        img         = UIImage(data: Data(base64Encoded: (picture?.replacingOccurrences(of: "data:image/png;base64,", with: ""))!)!)
    }
    
}











