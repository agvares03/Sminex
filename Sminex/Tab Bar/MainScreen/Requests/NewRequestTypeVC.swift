////
////  NewRequestTypeVC.swift
////  Sminex
////
////  Created by Sergey Ivanov on 26/07/2019.
////
//
//import UIKit
//import Gloss
//import FSPagerView
//import DeviceKit
//
//private protocol MainDataProtocol:  class {}
//private protocol CellsDelegate:     class {
//    func tapped(name: String)
//    func pressed(at indexPath: IndexPath)
//    func stockCellPressed(currImg: Int)
//}
//
//class NewRequestTypeVC: UIViewController {
//    
//    // MARK: Outlets
//    
//    @IBOutlet private weak var collectionView: UICollectionView!
//    
//    // MARK: Properties
//    
//    open var delegate: AppsUserDelegate?
//    struct Objects {
//        var sectionName : String!
//        var filteredData : [RequestTypeStruct]!
//    }
//    private var data = [Objects]()
//    private var typeName = ""
////    private var data = [RequestTypeStruct]()
//    
//    // MARK: View lifecycle
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        updateUserInterface()
//        getRequestTypes()
//    }
//    
//    func updateUserInterface() {
//        switch Network.reachability.status {
//        case .unreachable:
//            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
//            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
//                self.viewDidLoad()
//            }
//            alert.addAction(cancelAction)
//            self.present(alert, animated: true, completion: nil)
//        case .wifi: break
//            
//        case .wwan: break
//            
//        }
//    }
//    @objc func statusManager(_ notification: Notification) {
//        updateUserInterface()
//    }
//    
//    func getRequestTypes() {
//        
//        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
//        
//        var request = URLRequest(url: URL(string: Server.SERVER + Server.REQUEST_TYPE + "accountid=" + id)!)
//        request.httpMethod = "GET"
//        print(request)
//        
//        URLSession.shared.dataTask(with: request) {
//            data, responce, error in
//            
//            if error != nil {
//                DispatchQueue.main.sync {
//                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
//                    self.present(alert, animated: true, completion: nil)
//                }
//                return
//            }
//            
//            let responceString = String(data: data!, encoding: .utf8) ?? ""
//            
//            #if DEBUG
//            print(responceString)
//            #endif
//            
//            DispatchQueue.main.sync {
//                var denyImportExportPropertyRequest = false
//                if responceString.contains(find: "error") {
//                    let alert = UIAlertController(title: "Ошибка сервера", message: responceString.replacingOccurrences(of: "error:", with: ""), preferredStyle: .alert)
//                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in }))
//                    self.present(alert, animated: true, completion: nil)
//                    return
//                } else {
//                    if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
//                        TemporaryHolder.instance.choise(json!)
//                        denyImportExportPropertyRequest = (Business_Center_Data(json: json!)?.DenyImportExportProperty)!
//                        UserDefaults.standard.set(denyImportExportPropertyRequest, forKey: "denyImportExportPropertyRequest")
//                    }
//                }
//                let type: RequestTypeStruct
//                type = .init(id: "3", name: "Услуги службы комфорта")
//                if var types = TemporaryHolder.instance.requestTypes?.types {
//                    for i in 0...types.count - 1{
//                        if types[i].name == "Обращение"{
//                            types.remove(at: i)
//                        }
//                    }
////                    self.data = types
//                    var b : [RequestTypeStruct]
//                    b.removeAll()
//                    var d : [RequestTypeStruct]
//                    d.removeAll()
//                    types.forEach{
//                        if ($0.name?.contains(find: "ропуск"))! || ($0.name?.contains(find: "бслуживан"))! || ($0.name?.contains(find: "варийная"))!{
//                            b.append($0)
//                        }else{
//                            d.append($0)
//                        }
//                    }
//                    self.data.append(Objects(sectionName: "Базовые услуги", filteredData: b))
//                    self.data.append(Objects(sectionName: "Дополнительные платные услуги", filteredData: d))
//                }
////                self.data.append(type)
//                DispatchQueue.main.async {
//                    self.collectionView.reloadData()
//                }
//            }
//            }.resume()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        NotificationCenter.default
//            .addObserver(self,
//                         selector: #selector(statusManager),
//                         name: .flagsChanged,
//                         object: Network.reachability)
//        updateUserInterface()
//        tabBarController?.tabBar.isHidden = false
//    }
//    
//    // MARK: Actions
//    
//    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
//        
//        let AppsUserDelegate = self.delegate as! AppsUser
//        
//        if (AppsUserDelegate.isCreatingRequest_) {
//            navigationController?.popToRootViewController(animated: true)
//        } else {
//            navigationController?.popViewController(animated: true)
//        }
//    }
//    
//    // MARK: Navigation
//    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        switch segue.identifier {
//        case Segues.fromRequestTypeVC.toCreateAdmission:
//            if let vc = segue.destination as? CreateRequestVC, let index = sender as? Int {
//                vc.delegate = delegate
//                vc.name_ = typeName
//                vc.type_ = data[0].filteredData[index]
//            }
//        case Segues.fromRequestTypeVC.toCreateServive:
//            if let vc = segue.destination as? NewTechServiceVC, let index = sender as? Int {
//                vc.delegate = delegate
//                vc.type_ = data[0].filteredData[index]
//            }
//        default: break
//        }
//    }
//}
//
//extension NewRequestTypeVC: UICollectionViewDelegate, UICollectionViewDataSource, CellsDelegate, UICollectionViewDelegateFlowLayout, MainScreenDelegate {
//    func tapped(name: String) {
//        <#code#>
//    }
//    
//    func pressed(at indexPath: IndexPath) {
//        <#code#>
//    }
//    
//    func stockCellPressed(currImg: Int) {
//        <#code#>
//    }
//    
//    func update(method: String) {
//        <#code#>
//    }
//    
//    
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if section == 0 {
//            return data[section].filteredData.count + 1
//        } else {
//            return 0
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        
//        //        if kind == UICollectionElementKindSectionHeader {
//        
//        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "RequestTypeHeader", for: indexPath) as! RequestTypeHeader
//        //        if  indexPath.section != 4 && self.debtSize == nil{
//        header.display(data[indexPath.section].sectionName as! RequestTypeHeaderData, delegate: self)
//        //        } else {
//        //            header.frame.size.height = 0
//        //        }
//        header.frame.size.width = view.frame.size.width - 32
//        header.frame.origin.x = 16
//        header.backgroundColor = .white
//        
//        if #available(iOS 11.0, *) {
//            header.clipsToBounds = false
//            header.layer.cornerRadius = 4
//            header.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//        } else {
//            let rectShape = CAShapeLayer()
//            rectShape.bounds = header.frame
//            rectShape.position = header.center
//            rectShape.path = UIBezierPath(roundedRect: header.bounds, byRoundingCorners: [.topRight , .topLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
//            header.layer.mask = rectShape
//        }
//        return header
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let cell = NewRequestTypeCell.fromNib()
//        cell?.display(data[indexPath.section]![indexPath.row + 1] as! NewRequestTypeCellData, indexPath: indexPath, delegate: self)
//        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
//        return CGSize(width: view.frame.size.width - 32, height: size.height)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewRequestTypeCell", for: indexPath) as! NewRequestTypeCell
//        cell.display(data[indexPath.section]![indexPath.row + 1] as! NewRequestTypeCellData, indexPath: indexPath, delegate: self, isLast: data[indexPath.section]!.count == indexPath.row + 2)
//        if indexPath.row + 2 == data[indexPath.section]?.filteredData.count {
//            if #available(iOS 11.0, *) {
//                cell.clipsToBounds = false
//                cell.layer.cornerRadius = 4
//                cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
//            } else {
//                let rectShape = CAShapeLayer()
//                rectShape.bounds = cell.frame
//                rectShape.position = cell.center
//                rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
//                cell.layer.mask = rectShape
//            }
//        }
//        return cell
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
////        pressed(at: indexPath)
//    }
//    
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        return data.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        return CGSize(width: view.frame.size.width, height: 50.0)
//    }
//    
////    func pressed(at indexPath: IndexPath) {
////        if let cell = collection.cellForItem(at: indexPath) as? NewRequestTypeCell {
////            surveyName = cell.title.text ?? ""
////            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestionAnim, sender: self)
////
////        } else if let _ = collection.cellForItem(at: indexPath) as? StockCell {
////            performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
////
////        } else if (collection.cellForItem(at: indexPath) as? NewsCell) != nil {
////            tappedNews = self.filteredNews[safe: indexPath.row]
////            self.performSegue(withIdentifier: Segues.fromMainScreenVC.toNewsWAnim, sender: self)
////
////        }
////    }
//    
//}
//
//final class RequestTypeHeader: UICollectionReusableView {
//    
//    @IBOutlet private(set) weak var title:   UILabel!
//    @IBOutlet private weak var detail:  UIButton!
//    
//    @IBAction private func titlePressed(_ sender: UIButton) {
//        delegate?.tapped(name: title.text ?? "")
//    }
//    
//    private var delegate: CellsDelegate?
//    
//    fileprivate func display(_ item: RequestTypeHeaderData, delegate: CellsDelegate? = nil) {
//        
//        title.text = item.title
//        if (UIDevice.current.modelName.contains(find: "iPhone 4")) ||
//            (UIDevice.current.modelName.contains(find: "iPhone 4s")) ||
//            (UIDevice.current.modelName.contains(find: "iPhone 5")) ||
//            (UIDevice.current.modelName.contains(find: "iPhone 5c")) ||
//            (UIDevice.current.modelName.contains(find: "iPhone 5s")) ||
//            (UIDevice.current.modelName.contains(find: "iPhone SE")) ||
//            (UIDevice.current.modelName.contains(find: "Simulator iPhone SE")) {
//            title.font = title.font.withSize(20)
//        }
//        //
//        //        if !item.isNeedDetail {
//        //            detail.isHidden = true
//        //
//        //        } else {
//        //            detail.isHidden = false
//        //        }
//        
//        self.delegate = delegate
//        // programm version
//        if item.title == "К оплате" || item.title ==  "Счетчики" {
//            self.detail.setTitle("Подробнее", for: .normal)
//            self.detail.setTitleColor(self.tintColor, for: .normal)
//        } else if item.title == "Версия" {
//            self.detail.setTitleColor(UIColor.black, for: .normal)
//            self.detail.setTitle("ver. 1.94", for: .normal)
//        } else {
//            self.detail.setTitle("Все", for: .normal)
//            self.detail.setTitleColor(self.tintColor, for: .normal)
//        }
//    }
//    
//}
//
//private final class RequestTypeHeaderData: MainDataProtocol {
//    
//    let title:          String
//    let isNeedDetail:   Bool
//    
//    init(title: String, isNeedDetail: Bool = true) {
//        self.title          = title
//        self.isNeedDetail   = isNeedDetail
//    }
//}
//
//class NewRequestTypeCell: UICollectionViewCell {
//    
//    @IBOutlet weak var title:               UILabel!
//    @IBOutlet private weak var questions:   UILabel!
//    @IBOutlet private weak var divider:     UILabel!
//    
//    @IBAction private func goButtonPressed(_ sender: UIButton) {
//        delegate?.pressed(at: indexPath!)
//    }
//    private var delegate: CellsDelegate?
//    private var indexPath: IndexPath?
//    
//    fileprivate func display(_ item: NewRequestTypeCellData, delegate: CellsDelegate, indexPath: IndexPath) {
//        self.delegate    = delegate
//        self.indexPath   = indexPath
//        title.text       = item.title
//        questions.text   = item.question
//    }
//    
//    class func fromNib() -> NewRequestTypeCell? {
//        var cell: NewRequestTypeCell?
//        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
//        views?.forEach {
//            if let view = $0 as? NewRequestTypeCell {
//                cell = view
//            }
//        }
//        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
//        cell?.questions.preferredMaxLayoutWidth = cell?.questions.bounds.size.width ?? 0.0
//        return cell
//    }
//    
//}
//
//private final class NewRequestTypeCell: MainDataProtocol {
//    
//    let title:      String
//    let question:   String
//    
//    init(title: String, question: String) {
//        self.title      = title
//        self.question   = question
//    }
//}
