//
//  NewRequestTypeVC.swift
//  Sminex
//
//  Created by Sergey Ivanov on 26/07/2019.
//

import UIKit
import Gloss
import FSPagerView
import DeviceKit

private protocol CellsDelegate:     class {
    func pressed(at indexPath: IndexPath)
}

class NewRequestTypeVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CellsDelegate, UICollectionViewDelegateFlowLayout {
    
    // MARK: Outlets
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    // MARK: Properties
    
    open var delegate: AppsUserDelegate?
    struct Objects {
        var sectionName : String!
        var filteredData : [NewRequestTypeCellData]!
    }
    private var data = [Objects]()
    private var typeName = ""
    private var parkingsPlace = [String]()
    private var dataService: [ServicesUKJson] = []
//    private var data = [RequestTypeStruct]()
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        updateUserInterface()
        getRequestTypes()
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
    
    func getRequestTypes() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.REQUEST_TYPE + "accountid=" + id)!)
        request.httpMethod = "GET"
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, responce, error in
            
            if error != nil {
                DispatchQueue.main.sync {
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            let responceString = String(data: data!, encoding: .utf8) ?? ""
            
            #if DEBUG
            print(responceString)
            #endif
            
            DispatchQueue.main.sync {
                var denyImportExportPropertyRequest = false
                if responceString.contains(find: "error") {
                    let alert = UIAlertController(title: "Ошибка сервера", message: responceString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
                    self.present(alert, animated: true, completion: nil)
                    return
                } else {
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                        TemporaryHolder.instance.choise(json!)
                        denyImportExportPropertyRequest = (Business_Center_Data(json: json!)?.DenyImportExportProperty)!
                        UserDefaults.standard.set(denyImportExportPropertyRequest, forKey: "denyImportExportPropertyRequest")
                        if responceString.contains(find: "premises"){
                            self.parkingsPlace = (Business_Center_Data(json: json!)?.ParkingPlace)!
                        }
                    }
                }
//                let type: RequestTypeStruct
//                type = .init(id: "3", name: "Услуги службы комфорта")
//                print(TemporaryHolder.instance.requestTypes?.types)
                if var types = TemporaryHolder.instance.requestTypes?.types {
                    for i in 0...types.count - 1{
                        if types[i].name == "Обращение"{
                            types.remove(at: i)
                        }
                    }
//                    self.data = types
                    var b : [NewRequestTypeCellData]! = []
                    types.forEach{
                        if (($0.name?.contains(find: "ропуск"))!){
                            b.append(NewRequestTypeCellData(id: $0.id!, title: $0.name!, picture: UIImage(named: "admissionIcon")!))
                        }else if ($0.name?.contains(find: "бслуживан"))!{
                            b.append(NewRequestTypeCellData(id: $0.id!, title: $0.name!, picture: UIImage(named: "teshServIcon")!))
                        }else if ($0.name?.contains(find: "варийная"))!{
                            b.append(NewRequestTypeCellData(id: $0.id!, title: $0.name!, picture: UIImage(named: "alertAppIcon")!))
                        }
                    }
                    self.data.append(Objects(sectionName: "Базовые услуги", filteredData: b))
                    
                }
                self.getServices()
            }
            }.resume()
    }
    
    private func getServices() {
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_SERVICES + "ident=\(login)")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else {
                let alert = UIAlertController(title: "Ошибка серевера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.dataService = ServicesUKDataJson(json: json!)?.data ?? []
                let services = ServicesUKDataJson(json: json!)?.data ?? []
                var b : [NewRequestTypeCellData]! = []
                services.forEach{
                    var image = UIImage()
                    if let imageV = UIImage(data: Data(base64Encoded: ($0.picture!.replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
                        image = imageV
                    }
                    b.append(NewRequestTypeCellData(id: $0.id!, title: $0.name!, picture: image))
                }
                b.append(NewRequestTypeCellData(id: "-1", title: "Перейти в каталог услуг", picture: UIImage(named: "admissionIcon")!))
                self.data.append(Objects(sectionName: "Дополнительные (платные) услуги", filteredData: b))
            }
            
            #if DEBUG
            //            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            }.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: Actions
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        let AppsUserDelegate = self.delegate as! TestAppsUser
        
        if (AppsUserDelegate.isCreatingRequest_) {
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].filteredData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if data[1].filteredData.count - 1 == indexPath.row && indexPath.section == 1{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GoTypeCell", for: indexPath) as! GoTypeCell
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewRequestTypeCell", for: indexPath) as! NewRequestTypeCell
            cell.display(data[indexPath.section].filteredData![indexPath.row], delegate: self, indexPath: indexPath, displayWidth: self.view.frame.size.width - 32)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "RequestTypeHeader", for: indexPath) as! RequestTypeHeader
        header.display(data[indexPath.section].sectionName)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0{
            return CGSize(width: (view.frame.size.width - 32) / 4, height: 110)
        }else if indexPath.row == data[1].filteredData.count - 1{
            return CGSize(width: view.frame.size.width - 32, height: 50)
        }else{
            return CGSize(width: (view.frame.size.width - 32) / 4, height: 140)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let name = data[indexPath.section].filteredData[indexPath.row].title
        
        if (name.containsIgnoringCase(find: "пропуск")) {
            typeName = name 
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateAdmission, sender: indexPath.row)
            
        } else if (name.containsIgnoringCase(find: "обслуживание")) && indexPath.section == 0{
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateServive, sender: indexPath.row)
            //        } else if name == "Услуги службы комфорта" {
        }else{
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toServiceUK, sender: indexPath.row)
        }
    }
    
    func pressed(at indexPath: IndexPath) {
        print("")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Segues.fromRequestTypeVC.toCreateAdmission:
            if let vc = segue.destination as? CreateRequestVC, let index = sender as? Int {
                vc.delegate = delegate
                vc.name_ = typeName
                vc.type_ = RequestTypeStruct(id: data[0].filteredData[index].id, name: data[0].filteredData[index].title)
                vc.parkingsPlace = self.parkingsPlace
            }
        case Segues.fromRequestTypeVC.toCreateServive:
            if let vc = segue.destination as? CreateTechServiceVC, let index = sender as? Int {
                vc.delegate = delegate
                vc.type_ = RequestTypeStruct(id: data[0].filteredData[index].id, name: data[0].filteredData[index].title)
                vc.parkingsPlace = self.parkingsPlace
            }
        case Segues.fromRequestTypeVC.toServiceUK:
            if let vc = segue.destination as? CreateServiceUK, let index = sender as? Int {
                vc.delegate = delegate
                vc.type_ = RequestTypeStruct(id: data[1].filteredData[index].id, name: data[1].filteredData[index].title)
                vc.parkingsPlace = self.parkingsPlace
                dataService.forEach{
                    if $0.name == data[1].filteredData[index].title{
                        vc.data_ = $0
                    }
                }
            }
        default: break
        }
    }
}

final class RequestTypeHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title:   UILabel!
    
    fileprivate func display(_ titleName: String) {
        
        title.text = titleName
    }
    
}

class GoTypeCell: UICollectionViewCell {
    
    @IBOutlet private weak var goType:   UIButton!
    fileprivate func display(_ item: NewRequestTypeCellData) {
    }
}

class NewRequestTypeCell: UICollectionViewCell {
    
    @IBOutlet weak var title:               UILabel!
    @IBOutlet private weak var divider:     UILabel!
    @IBOutlet private weak var imageView:   UIImageView!
    @IBOutlet private weak var circleView:  CircleView!
    @IBOutlet private weak var viewConst:   NSLayoutConstraint!
    @IBOutlet private weak var viewConst2:  NSLayoutConstraint!
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        delegate?.pressed(at: indexPath!)
    }
    private var delegate: CellsDelegate?
    private var indexPath: IndexPath?
    
    fileprivate func display(_ item: NewRequestTypeCellData, delegate: CellsDelegate, indexPath: IndexPath, displayWidth: CGFloat) {
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) {
            viewConst.constant = 10
            viewConst2.constant = 10
        }
        self.delegate    = delegate
        self.indexPath   = indexPath
        title.text       = item.title
        if item.title == "Гостевой пропуск"{
            title.text = "Пропуск"
        }
        if displayWidth < 375{
            title.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        }else if displayWidth == 375{
            title.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        }
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) {
            title.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        }
        let image: UIImage? = item.picture
        if image != nil{
            circleView.image = item.picture
            // Граница вокруг картинки
            circleView.layer.borderColor = UIColor.black.cgColor
            circleView.layer.borderWidth = 1.0
            // Углы
            circleView.layer.cornerRadius = ((displayWidth / 4) - 40) / 2
            // Поправим отображения слоя за его границами
            if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) {
                circleView.layer.cornerRadius = ((displayWidth / 4) - 20) / 2
            }
            circleView.layer.masksToBounds = true
        }else{
            circleView.isHidden = true
        }
    }
    class func fromNib() -> NewRequestTypeCell? {
        var cell: NewRequestTypeCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? NewRequestTypeCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) + 20
        return cell
    }
    
}

struct NewRequestTypeCellData {
    
    let title:     String
    let picture:   UIImage
    let id:        String
    
    init(id: String, title: String, picture: UIImage) {
        self.title      = title
        self.picture    = picture
        self.id         = id
    }
}

@IBDesignable class CircleView: UIView {
    
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
        
        let screenSize: CGRect = UIScreen.main.bounds
        let size = (screenSize.width - 32) / 4
        imageView.frame = CGRect(x: 10, y: 10, width: size - 60, height: size - 60)
        if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE) {
            imageView.frame = CGRect(x: 10, y: 10, width: size - 40, height: size - 40)
        }
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    
    func addImage() {
        imageView.image = image
    }
}

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(UIImageRenderingMode.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}
