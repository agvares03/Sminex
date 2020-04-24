//
//  ServicesUKTableVC.swift
//  Sminex
//
//  Created by IH0kN3m on 5/11/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class ServicesUKTableVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    private var data: [ServicesUKJson] = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        collection.dataSource = self
        collection.delegate   = self
        getServices()
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ServicesUKTableCell", for: indexPath) as! ServicesUKTableCell
        let data = self.data[safe: indexPath.row]
        cell.display(data?.name ?? "", desc: data?.howToOrder ?? "", amount: data?.cost ?? "", picture: data?.picture ?? "")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
        let cell = ServicesUKTableCell.fromNib()
        let data = self.data[safe: indexPath.row]
        cell?.display(data?.name ?? "", desc: data?.howToOrder ?? "", amount: data?.cost ?? "", picture: data?.picture ?? "")
        var size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
//        if size.height > 290 {
//            size.height = size.height - 50
//            return CGSize(width: view.frame.size.width, height: size.height)
//        }
        if (data?.cost?.contains(find: "Стоимость услуги"))!{
            return CGSize(width: view.frame.size.width, height: 100)
        }
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromServicesUKTableVC.toDesc, sender: self)
    }
    
    private func getServices() {
        
        startAnimation()
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_SERVICES + "ident=\(login)")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.stopAnimation()
                    self.collection.reloadData()
                }
            }
            
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else {
                let alert = UIAlertController(title: "Ошибка серевера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.data = ServicesUKDataJson(json: json!)?.data ?? []
            }
            
            #if DEBUG
//            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
        }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromServicesUKTableVC.toDesc {
            let vc = segue.destination as! ServicesUKDescVC
            vc.data_ = data[index]
            vc.allData = data
            vc.index = index
        }
    }
    
    private func startAnimation() {
        collection.alpha = 0
        loader.isHidden  = false
        loader.startAnimating()
    }
    
    private func stopAnimation() {
        collection.alpha = 1
        loader.stopAnimating()
        loader.isHidden = true
    }
}


final class ServicesUKTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var descHeight:    NSLayoutConstraint!
    @IBOutlet private weak var amount:  UILabel!
    @IBOutlet private weak var image:   CircleView3!
    
    func display(_ title: String, desc: String, amount: String, picture: String) {
        self.title.text     = title
        if desc != "" && desc != " "{
            self.desc.text = desc
            self.descHeight.constant = heightForLabel(text: desc, font: self.desc.font, width: self.desc.bounds.size.width)
        }else{
            self.descHeight.constant = 0
            self.desc.text = ""
        }
        self.amount.text    = amount.replacingOccurrences(of: "руб.", with: "₽")
        if amount.contains(find: "Стоимость услуги"){
            self.amount.text = amount.replacingOccurrences(of: " ", with: "\n")
        }
        if let imageV = UIImage(data: Data(base64Encoded: (picture.replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
            image.image = imageV
            image.layer.borderColor = UIColor.black.cgColor
            image.layer.borderWidth = 1.0
            // Углы
            image.layer.cornerRadius = 25
            // Поправим отображения слоя за его границами
            image.layer.masksToBounds = true
        }else{
            image.isHidden = true
        }
    }
    
    func heightForLabel(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    class func fromNib() -> ServicesUKTableCell? {
        var cell: ServicesUKTableCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? ServicesUKTableCell {
                cell = view
            }
        }
        
        cell?.title.preferredMaxLayoutWidth  = cell?.title.bounds.size.width  ?? 0.0
        cell?.desc.preferredMaxLayoutWidth   = cell?.desc.bounds.size.width   ?? 0.0
        cell?.amount.preferredMaxLayoutWidth = cell?.amount.bounds.size.width ?? 0.0
        
//        if isPlusDevices() {
//            cell?.desc.preferredMaxLayoutWidth += 40
//
//        } else if isNeedToScroll() {
//            cell?.title.preferredMaxLayoutWidth -= 25
//            cell?.desc.preferredMaxLayoutWidth -= 50
//        }
        
        return cell
    }
}

struct ServicesUKDataJson: JSONDecodable {
    
    let data: [ServicesUKJson]?
    
    init?(json: JSON) {
        data = "data" <~~ json
    }
}

struct ServicesUKJson: JSONDecodable {
    
    let howToOrder: String?
    let picture:    String?
    let name:       String?
    let desc:       String?
    let cost:       String?
    let id:         String?
    let shortDesc:  String?
    let selectPlace:Bool?
    let selectTime: Bool?
    let selectCost: Bool?
    let fullDesc:   String?
    
    init?(json: JSON) {
        howToOrder = "HowToOrder"       <~~ json
        picture    = "Picture"          <~~ json
        name       = "Name"             <~~ json
        desc       = "Description"      <~~ json
        cost       = "Cost"             <~~ json
        id         = "ID"               <~~ json
        shortDesc  = "ShortDescription" <~~ json
        selectPlace = "IsSelectPlace"    <~~ json
        selectTime = "IsSelectTime"     <~~ json
        selectCost = "IsSelectCost"     <~~ json
        fullDesc   = "FullDescription"  <~~ json
    }
}

@IBDesignable class CircleView3: UIView {
    
    let imageView = UIImageView()
    
    @IBInspectable var image: UIImage? {
        didSet {
            addImage()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setup()
    }
    
    func setup () {
        imageView.frame = CGRect(x: 5, y: 5, width: 40, height: 40)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    
    func addImage() {
        imageView.image = image
    }
}


















