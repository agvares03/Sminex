//
//  MainScreenVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/22/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss
import SwiftyXMLParser
import FSPagerView

private protocol MainDataProtocol:  class {}
private protocol CellsDelegate:     class {
    func tapped(name: String)
    func pressed(at indexPath: IndexPath)
    func stockCellPressed(currImg: Int)
}
protocol MainScreenDelegate: class {
    func update(method: String)
}

final class MainScreenVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CellsDelegate, UICollectionViewDelegateFlowLayout, MainScreenDelegate, AppsUserDelegate {
    
    private var business_center_info: Bool?
    private var busines_center_denyInvoiceFiles: Bool?
    private var busines_center_denyTotalOnlinePayments: Bool?
    // выводить или нет qr-код
    private var busines_center_denyQRCode: Bool?
    
    // Можно ли добавить транспорт в пропуск
    private var business_center_PassSingle: Bool?
    private var business_center_PassSingleWithAuto: Bool?
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Segues.fromMainScreenVC.toFinancePay, sender: self)
    }
    
    private var requestId  = ""
    private var surveyName = ""
    private var canCount = true
    private var data: [Int:[Int:MainDataProtocol]] = [
        0 : [
            0 : CellsHeaderData(title: "Опросы")
            ],
        1 : [
            0 : CellsHeaderData(title: "Новости")
            ],
        2 : [
            0 : CellsHeaderData(title: "Акции и предложения"),
            1 : StockCellData(images: [])
            ],
        3 : [
            0 : CellsHeaderData(title: "Заявки")],
        4 : [
            0 : CellsHeaderData(title: "К оплате")
            ],
        5 : [
            0 : CellsHeaderData(title: "Счетчики"),
            1 : SchetCellData(title: "Осталось 4 дня для передачи показаний", date: "Передача с 20 по 25 января")],
        6 : [
            0 : CellsHeaderData(title: "Версия"),
            1 : SchetCellData(title: "Осталось 4 дня для передачи показаний", date: "Передача с 20 по 25 января")]]
//            1 : VersionCellData()]]
    private var questionSize:   CGSize?
    private var newsSize:       CGSize?
    private var dealsSize:      CGSize?
    private var debtSize:       CGSize?
    private var url:            URLRequest?
    private var debt:           AccountDebtJson?
    private var refreshControl: UIRefreshControl?
    private var mainScreenXml:  XML.Accessor?
    private var tappedNews: NewsJson?
    private var deals:  [DealsJson] = []
    private var filteredNews: [NewsJson] = []
    private var dealsIndex = 0
    private var numSections = 0
    private var appsUser: AppsUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Получим данные по Бизнес-центру (выводить или нет Оплаты)
        get_info_business_center()
        
        title = (UserDefaults.standard.string(forKey: "buisness") ?? "") + " by SMINEX"
        
        let date1 = UserDefaults.standard.integer(forKey: "date1")
        let date2 = UserDefaults.standard.integer(forKey: "date2")
        canCount = UserDefaults.standard.integer(forKey: "can_count") == 1 ? true : false
        
        if date1 == 0 && date2 == 0 {
            data[5]![1] = SchetCellData(title: "Показания передавать можно", date: "Передача показаний возможна в любой день текущего месяца")
        
        } else {   
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "LLLL"
            var day = DateComponents()
            day.day = date2 - 1
            let date = Calendar.current.date(byAdding: day, to: dateFormatter.date(from: dateFormatter.string(from: Date()))!)
            dateFormatter.locale = Locale(identifier: "Ru-ru")
            dateFormatter.dateFormat = date2 < 10 ? "d LLLL" : "dd LLLL"
            
            let leftDays = date1 - date2
            
            if leftDays == 1 {
                data[5]![1] = SchetCellData(title: "Осталось \(leftDays) день для передачи показаний", date: "Передача с \(date1) по \(dateFormatter.string(from: date!))")
                
            } else if leftDays == 2 || leftDays == 3 || leftDays == 4 {
                data[5]![1] = SchetCellData(title: "Осталось \(leftDays) дня для передачи показаний", date: "Передача с \(date1) по \(dateFormatter.string(from: date!))")
                
            } else {
                data[5]![1] = SchetCellData(title: "Осталось \(leftDays) дней для передачи показаний", date: "Передача с \(date1) по \(dateFormatter.string(from: date!))")
            }
        }
        fetchNews()
        fetchDebt()
        fetchDeals()
        fetchRequests()
        fetchQuestions()
        collection.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)
        collection.delegate     = self
        collection.dataSource   = self
        automaticallyAdjustsScrollViewInsets = false
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent         = true
        navigationController?.navigationBar.backgroundColor       = .white
        navigationController?.navigationBar.tintColor             = .white
        navigationController?.navigationBar.barTintColor          = .white
        navigationController?.navigationBar.layer.shadowColor     = UIColor.lightGray.cgColor
        navigationController?.navigationBar.layer.shadowOpacity   = 0.5
        navigationController?.navigationBar.layer.shadowOffset    = CGSize(width: 0, height: 1.0)
        navigationController?.navigationBar.layer.shadowRadius    = 1
    }
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.global(qos: .background).async {
                let res = self.getRequests()
                var count = 1
                sleep(2)
                DispatchQueue.main.sync {
                    self.data[3] = [0 : CellsHeaderData(title: "Заявки")]
                    res.forEach {
                        self.data[3]![count] = $0
                        count += 1
                    }
                    self.data[3]![count] = RequestAddCellData(title: "Добавить заявку")
                    self.collection.reloadData()
                }
            }
            self.fetchQuestions()
            self.fetchDeals()
            self.fetchDebt()
            self.fetchNews()
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
        
        tabBarController?.tabBar.tintColor = .black
        tabBarController?.tabBar.selectedItem?.title = "Главная"
        tabBarController?.tabBar.isHidden = false
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 22, weight: .bold) ]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17, weight: .bold) ]
    }
    
    private func get_info_business_center() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_SERVICES + "ident=\(login)")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
//                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.business_center_info = Business_Center_Data(json: json!)?.DenyOnlinePayments
                self.busines_center_denyInvoiceFiles = Business_Center_Data(json: json!)?.DenyInvoiceFiles
                self.busines_center_denyTotalOnlinePayments = Business_Center_Data(json: json!)?.DenyTotalOnlinePayments
                
                self.busines_center_denyQRCode = Business_Center_Data(json: json!)?.DenyQRCode
                
                self.business_center_PassSingle = Business_Center_Data(json: json!)?.DenyIssuanceOfPassSingle
                self.business_center_PassSingleWithAuto = Business_Center_Data(json: json!)?.DenyIssuanceOfPassSingleWithAuto
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8)!)
            #endif
            
            let defaults = UserDefaults.standard
            defaults.set(self.business_center_info, forKey: "denyOnlinePayments")
            defaults.set(self.busines_center_denyInvoiceFiles, forKey: "denyInvoiceFiles")
            defaults.set(self.busines_center_denyTotalOnlinePayments, forKey: "denyTotalOnlinePayments")
            defaults.set(self.busines_center_denyQRCode, forKey: "denyQRCode")
            defaults.set(self.business_center_PassSingle, forKey: "denyIssuanceOfPassSingle")
            defaults.set(self.business_center_PassSingleWithAuto, forKey: "denyIssuanceOfPassSingleWithAuto")
            defaults.synchronize()
            
            }.resume()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 && questionSize != nil {
            return 0
            
        } else if section == 1 && newsSize != nil {
            return 0
        } else if data.keys.contains(section) {
            return (data[section]?.count ?? 2) - 1
        
        } else {
            return 0
        }
    }
    
    func remove(index: Int) {
        self.data.removeValue(forKey: index)
        
        let indexPath = IndexPath(row: index, section: 0)
        collection.performBatchUpdates({
            collection.deleteItems(at: [indexPath])
        }, completion: {
            (finished: Bool) in
            self.collection.reloadItems(at: self.collection.indexPathsForVisibleItems)
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
//        if kind == UICollectionElementKindSectionHeader {
        
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CellsHeader", for: indexPath) as! CellsHeader
//        if  indexPath.section != 4 && self.debtSize == nil{
            header.display(data[indexPath.section]![0] as! CellsHeaderData, delegate: self)
//        } else {
//            header.frame.size.height = 0
//        }
            header.frame.size.width = view.frame.size.width - 32
            header.frame.origin.x = 16
            
            if header.title.text == "Акции и предложения" {
                header.backgroundColor = .clear
            } else if header.title.text == "Версия" {
                header.backgroundColor = .clear
                header.title.text = ""
            }  else {
                header.backgroundColor = .white
            }
            
            if #available(iOS 11.0, *) {
                header.clipsToBounds = false
                header.layer.cornerRadius = 4
                header.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            } else {
                let rectShape = CAShapeLayer()
                rectShape.bounds = header.frame
                rectShape.position = header.center
                rectShape.path = UIBezierPath(roundedRect: header.bounds, byRoundingCorners: [.topRight , .topLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                header.layer.mask = rectShape
            }
            
            return header

//        } else {
            
//            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EnableCell", for: indexPath) as! EnableCell
//            footer.display("")
//            return footer
            
//        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "Опросы" {
            let cell = SurveyCell.fromNib()
            cell?.display(data[indexPath.section]![indexPath.row + 1] as! SurveyCellData, indexPath: indexPath, delegate: self)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
            return CGSize(width: view.frame.size.width - 32, height: size.height)
        
        } else if title == "Новости" {
            let cell = NewsCell.fromNib(viewWidth: view.frame.size.width)
            cell?.display(data[indexPath.section]![indexPath.row + 1] as! NewsCellData)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
            return CGSize(width: view.frame.size.width - 32, height: size.height)
        
        } else if title == "Акции и предложения" {
            if (self.dealsSize == nil) {
//                self.dealsSize = CGSize(width: view.frame.size.width, height: 204.0)
                return CGSize(width: view.frame.size.width, height: 0.0)
            } else {
                return CGSize(width: view.frame.size.width, height: 204.0)
            }
        } else if title == "Заявки" {
            if indexPath.row == data[indexPath.section]!.count - 2 {
                return CGSize(width: view.frame.size.width - 32, height: 70.0)
            }
            let cell = RequestCell.fromNib(viewSize: collection.frame.size.width)
            if let requestData = data[indexPath.section]![indexPath.row + 1] as? RequestCellData {
                cell?.display(requestData)
            }
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0.0, height: 0.0)
            return CGSize(width: view.frame.size.width - 32, height: size.height + 3)
        
        } else if title == "К оплате" {
            if busines_center_denyTotalOnlinePayments == true || business_center_info == true {
                return CGSize(width: view.frame.size.width - 32, height: 67.0)
            } else {
                return CGSize(width: view.frame.size.width - 32, height: 110.0)
            }
        } else if title == "Счетчики" {
            let cell = SchetCell.fromNib()
            cell?.display(data[indexPath.section]![indexPath.row + 1] as! SchetCellData)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
            return CGSize(width: view.frame.size.width - 32, height: size.height)
        } else if title == "Версия" {

            return CGSize(width: view.frame.size.width - 32, height: 0.0)
            
        } else {
            return CGSize(width: view.frame.size.width - 32, height: 100.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "Опросы" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SurveyCell", for: indexPath) as! SurveyCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! SurveyCellData, indexPath: indexPath, delegate: self, isLast: data[indexPath.section]!.count == indexPath.row + 2)
            if indexPath.row + 2 == data[indexPath.section]?.count {
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
            }
            return cell
        
        } else if title == "Новости" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as! NewsCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! NewsCellData, isLast: data[indexPath.section]!.count == indexPath.row + 2)
            if indexPath.row + 2 == data[indexPath.section]?.count {
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
            }
            return cell
        
        } else if title == "Акции и предложения" {
            
//            if (self.dealsSize == nil) {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EnableCell", for: indexPath) as! EnableCell
//                return cell
//            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StockCell", for: indexPath) as! StockCell
                cell.display(data[indexPath.section]![indexPath.row + 1] as! StockCellData, delegate: self, indexPath: indexPath)
                return cell
//            }
        
        } else if title == "Заявки" {
            
            if indexPath.row == data[indexPath.section]!.count - 2 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestAddCell", for: indexPath) as! RequestAddCell
                cell.display(data[indexPath.section]![indexPath.row + 1] as! RequestAddCellData, delegate: self)
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
                return cell
                
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestCell", for: indexPath) as! RequestCell
                if let requestData = data[indexPath.section]![indexPath.row + 1] as? RequestCellData {
                    cell.display(requestData)
                }
                return cell
            }
        
        } else if title == "К оплате" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ForPayCell", for: indexPath) as! ForPayCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! ForPayCellData)
            if indexPath.row + 2 == data[indexPath.section]?.count {
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
            }
            return cell
        
        } else if title == "Счетчики" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScetCell", for: indexPath) as! SchetCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! SchetCellData, delegate: self)
            if indexPath.row + 2 == data[indexPath.section]?.count {
                if #available(iOS 11.0, *) {
                    cell.clipsToBounds = false
                    cell.layer.cornerRadius = 4
                    cell.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                } else {
                    let rectShape = CAShapeLayer()
                    rectShape.bounds = cell.frame
                    rectShape.position = cell.center
                    rectShape.path = UIBezierPath(roundedRect: cell.bounds, byRoundingCorners: [.bottomRight , .bottomLeft], cornerRadii: CGSize(width: 4, height: 4)).cgPath
                    cell.layer.mask = rectShape
                }
            }
            return cell
            
        } else if title == "Версия" {

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VersionCell", for: indexPath) as! VersionCell
            return cell
        
        } else {
            return SurveyCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        pressed(at: indexPath)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 0 && questionSize != nil {
            return CGSize(width: 0.0, height: 0.0)
        
        } else if section == 1 && newsSize != nil {
            return CGSize(width: 0.0, height: 0.0)
        } else if section == 2 && dealsSize == nil {
            return CGSize(width: 0.0, height: 0.0)
        } else if section == 2 {
            return CGSize(width: view.frame.size.width, height: 35.0)
        } else {
            return CGSize(width: view.frame.size.width, height: 50.0)
        }
    }
    
    func pressed(at indexPath: IndexPath) {
        if let cell = collection.cellForItem(at: indexPath) as? SurveyCell {
            surveyName = cell.title.text ?? ""
            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestionAnim, sender: self)
        
        } else if let _ = collection.cellForItem(at: indexPath) as? StockCell {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
        
        } else if (collection.cellForItem(at: indexPath) as? NewsCell) != nil {
            tappedNews = self.filteredNews[safe: indexPath.row]
            self.performSegue(withIdentifier: Segues.fromMainScreenVC.toNewsWAnim, sender: self)
        
        } else if (collection.cellForItem(at: indexPath) as? RequestCell) != nil {
            self.requestId = (self.data[3]![indexPath.row + 1] as? RequestCellData)?.id ?? ""
            appsUser = AppsUser()
            appsUser?.requestId_ = requestId
            appsUser?.xml_ = mainScreenXml
            appsUser?.delegate = self
            appsUser?.prepareGroup = DispatchGroup()
            appsUser?.viewDidLoad()
            DispatchQueue.global(qos: .userInitiated).async {
                self.appsUser?.prepareGroup?.wait()
                DispatchQueue.main.async {
                    if self.appsUser?.admission != nil {
                        self.performSegue(withIdentifier: Segues.fromMainScreenVC.toAdmission, sender: self)
                        
                    } else if self.appsUser?.techService != nil {
                        self.performSegue(withIdentifier: Segues.fromMainScreenVC.toService, sender: self)
                    } else {
                        
                    }
                }
            }
//
        }
    }
    
    func tapped(name: String) {
        
        if name == "Заявки" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toRequest, sender: self)
        
        } else if name == "Передать показания" {
            if canCount {
                performSegue(withIdentifier: Segues.fromMainScreenVC.toSchet, sender: self)
            }
            
        } else if name == "Счетчики" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toSchet, sender: self)
            
        } else if name == "Добавить заявку" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toCreateRequest, sender: self)
        
        } else if name == "Опросы" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestions, sender: self)
        
        } else if name == "Акции и предложения" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toDealsList, sender: self)
        
        } else if name == "К оплате" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toFinance, sender: self)
        
        } else if name == "Новости" {
            performSegue(withIdentifier: Segues.fromMainScreenVC.toNews, sender: self)
        }
    }
    
    func stockCellPressed(currImg: Int) {
        self.dealsIndex = currImg
        performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
    }
    
    private func fetchRequests() {
        
        DispatchQueue.global(qos: .background).async {
            let res = self.getRequests()
            var count = 1
            DispatchQueue.main.sync {
                self.data[3] = [0 : CellsHeaderData(title: "Заявки")]
                res.forEach {
                    self.data[3]![count] = $0
                    count += 1
                }
                self.data[3]![count] = RequestAddCellData(title: "Добавить заявку")
                self.collection.reloadData()
            }
        }
    }
    
    func getRequests() -> [RequestCellData] {
        
        var returnArr: [RequestCellData] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            
            let login = UserDefaults.standard.string(forKey: "login") ?? ""
            let pass  = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt())
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass + "&onlyLast=1")!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    group.leave()
                }
                guard data != nil else { return }
                
                let xml = XML.parse(data!)
                self.mainScreenXml = xml
                let requests = xml["Requests"]
                let row = requests["Row"]
                var rows: [Request] = []
                var rowComms: [String : [RequestComment]]  = [:]
                var rowPersons: [String : [RequestPerson]] = [:]
                
                row.forEach { row in
                    rows.append(Request(row: row))
                    rowComms[row.attributes["ID"]!] = []
                    rowPersons[row.attributes["ID"]!] = []
                    
                    row["Comm"].forEach {
                        rowComms[row.attributes["ID"]!]?.append( RequestComment(row: $0) )
                    }
                    row["Persons"].all?.forEach {
                        $0.childElements.forEach {
                            rowPersons[row.attributes["ID"]!]?.append( RequestPerson(row: $0)  )
                        }
                    }
                }
                
                var commentCount = 0
                rows.forEach { row in
                    let isAnswered = (rowComms[row.id!]?.count ?? 0) <= 0 ? false : true
                    
                    let lastComm = (rowComms[row.id!]?.count ?? 0) <= 0 ? nil : rowComms[row.id!]?[(rowComms[row.id!]?.count ?? 1) - 1]
                    if (lastComm?.name ?? "") != (UserDefaults.standard.string(forKey: "name") ?? "") {
                        commentCount += 1
                    }
                    let icon = !(row.status?.contains(find: "Отправлена"))! ? UIImage(named: "check_label")! : UIImage(named: "processing_label")!
                    let isPerson = row.name?.contains(find: "ропуск") ?? false
                    
                    var persons = ""//row.responsiblePerson ?? ""
                    
                    if persons == "" {
                        rowPersons[row.id ?? ""]?.forEach { person in
                            if person.id == rowPersons[row.id ?? ""]?.last?.id {
                                persons += (person.fio ?? "") + " "
                                
                            } else {
                                persons += (person.fio ?? "") + ", "
                            }
                        }
                    }
                    
                    let descText = isPerson ? (persons == "" ? "Не указано" : persons) : row.text ?? ""
                    
                    returnArr.append( RequestCellData(title: row.name ?? "",
                                                      desc: rowComms[row.id!]?.count == 0 ? descText : lastComm?.text ?? "",
                                                      icon: icon,
                                                      date: row.updateDate ?? "",
                                                      status: row.status ?? "",
                                                      isBack: isAnswered,
                                                      id: row.id ?? "") )
                }
                TemporaryHolder.instance.menuRequests = commentCount
            }.resume()
        }
        
        group.wait()
        return returnArr
    }
    
    private func fetchQuestions() {
        DispatchQueue.global().async {
            
            let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                guard data != nil else { return }
                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    let unfilteredData = QuestionsJson(json: json!)?.data
                    var filtered: [QuestionDataJson] = []
                    
                    unfilteredData?.forEach { json in
                        
                        var isContains = true
                        json.questions?.forEach {
                            if !($0.isCompleteByUser ?? false) {
                                isContains = false
                            }
                        }
                        if !isContains {
                            filtered.append(json)
                        }
                    }
                    if filtered.count == 0 {
                        self.questionSize = CGSize(width: 0, height: 0)
                        
                    } else {
                        self.questionSize = nil
                        DispatchQueue.main.sync {
                            self.data.removeValue(forKey: 0)
                            self.data[0] = [0:CellsHeaderData(title: "Опросы")]
                            var count = 1
                            filtered.forEach {
                                
                                
                                
                                var txt = " вопроса"
                                let col_questions = ($0.questions?.count)!
                                if (col_questions > 4) {
                                    txt = " вопросов"
                                } else if (col_questions == 1) {
                                    txt = " вопрос"
                                }
                                if (col_questions > 20) {
                                    let ostatok = col_questions % 10
                                    if (ostatok > 4) {
                                        txt = " вопросов"
                                    } else if ostatok == 1 {
                                        txt = " вопрос"
                                    } else {
                                        txt = " вопроса"
                                    }
                                }
                                
                                var isAnsvered = false
                                let defaults = UserDefaults.standard
                                let array = defaults.array(forKey: "PollsStarted") as? [Int] ?? [Int]()
                                if array.contains($0.id!) {
                                    isAnsvered = true
                                }
                                
                                if isAnsvered {
                                    self.data[0]![count] = SurveyCellData(title: $0.name ?? "", question: "Вы начали опрос")
                                } else {
                                    self.data[0]![count] = SurveyCellData(title: $0.name ?? "", question: "\($0.questions?.count ?? 0)" + txt)
                                }
                                
                                count += 1
                            }
                        }
                    }
                    TemporaryHolder.instance.menuQuesions = filtered.count
                    
                    DispatchQueue.main.sync {
                        self.collection.reloadData()
                    }
                    
                    if unfilteredData?.count == 0 {
                        DispatchQueue.main.sync {
                            self.questionSize = CGSize(width: 0, height: 0)
                            self.collection.reloadData()
                        }
                    }
                }
                
            }.resume()
        }
    }
    
    private final func fetchDeals() {
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PROPOSALS + "ident=\(UserDefaults.standard.string(forKey: "login") ?? "")")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.async {
                    self.collection.reloadData()
                }
            }
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                
                DispatchQueue.main.sync {
//                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.deals = (DealsDataJson(json: json!)?.data)!
            }
            var imgs: [UIImage] = []
            
            if (self.deals.count == 0) {
                self.dealsSize = nil
                
            } else {
                self.dealsSize = CGSize(width: 0, height: 0)
                self.deals.forEach {
                    imgs.append( $0.img ?? UIImage() )
                }
                self.data[2]![1] = StockCellData(images: imgs)
                TemporaryHolder.instance.menuDeals = imgs.count
                
                #if DEBUG
                //                print(String(data: data!, encoding: .utf8) ?? "")
                #endif
            }
            
            }.resume()
    }
    
    private func fetchDebt() {
        
        let defaults = UserDefaults.standard
        
        self.data[4]![1] = ForPayCellData(title: defaults.string(forKey: "ForPayTitle") ?? "", date: defaults.string(forKey: "ForPayDate") ?? "")
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt())
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_DEBT + "login=" + login + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.collection.reloadData()
                }
            }
            guard data != nil else { return }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
//                    self.present(alert, animated: true, completion: nil)
                }
                
//                self.data.removeValue(forKey: 4)
                
                let dateFormatter = DateFormatter()
                let date = Date()
                dateFormatter.dateFormat = "dd.MM.yyyy"
                
                let comp: DateComponents = Calendar.current.dateComponents([.year, .month], from: date)
                let startOfMonth = Calendar.current.date(from: comp)!
                
                var comps2 = DateComponents()
                comps2.month = 1
                comps2.day = -1
                let endOfMonth = Calendar.current.date(byAdding: comps2, to: startOfMonth)
                let dateText = dateFormatter.string(from: endOfMonth!)
                
                var datePay = dateText
                if (datePay.count) > 9 {
                    datePay.removeLast(8)
                }
                self.data[4]![1] = ForPayCellData(title: (self.debt?.sumPay ?? 0.0).formattedWithSeparator + " ₽", date: datePay)
                
                defaults.setValue(String(self.debt?.sumPay ?? 0.0) + " ₽", forKey: "ForPayTitle")
                defaults.setValue(datePay, forKey: "ForPayDate")
                defaults.synchronize()
                
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                self.debt = AccountDebtData(json: json!)?.data!
            }
            var datePay = self.debt?.datePay
            if (datePay?.count ?? 0) > 9 {
                datePay?.removeLast(9)
            }
            self.data[4]![1] = ForPayCellData(title: (self.debt?.sumPay ?? 0.0).formattedWithSeparator + " ₽", date: datePay ?? "")
            
            defaults.setValue(String(self.debt?.sumPay ?? 0.0) + " ₽", forKey: "ForPayTitle")
            defaults.setValue(datePay, forKey: "ForPayDate")
            defaults.synchronize()
            
            #if DEBUG
//            print(String(data: data!, encoding: .utf8)!)
            #endif
            
            }.resume()
    }
    
    private func fetchNews() {
        DispatchQueue.global(qos: .userInitiated).async {
            let decoded = UserDefaults.standard.object(forKey: "newsList") as? Data
            
            guard decoded != nil && ((NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]])[0]?.count ?? 0) != 0 else {
                let login = UserDefaults.standard.string(forKey: "id_account") ?? ""
                
                var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login)!)
                request.httpMethod = "GET"
                
                URLSession.shared.dataTask(with: request) {
                    data, error, responce in
                    
                    guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else { return }
                    
                    if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                        TemporaryHolder.instance.news = NewsJsonData(json: json!)!.data!
                    }
                    UserDefaults.standard.set(String(TemporaryHolder.instance.news?.first?.newsId ?? 0), forKey: "newsLastId")
                    TemporaryHolder.instance.newsLastId = String(TemporaryHolder.instance.news?.first?.newsId ?? 0)
                    UserDefaults.standard.synchronize()
                    self.filteredNews = TemporaryHolder.instance.news?.filter { $0.isShowOnMainPage ?? false } ?? []
                    
                    for (ind, item) in self.filteredNews.enumerated() {
                        if ind < 3 {
//                            self.data[1]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                            self.data[1]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "")
                        }
                    }
                    
                    if (self.data[1]?.count ?? 0) < 2 {
                        self.newsSize = CGSize(width: 0, height: 0)
                    
                    } else {
                        self.newsSize = nil
                    }
                    
                    DispatchQueue.main.sync {
                        self.collection.reloadData()
                    }
                    return
                }.resume()
                return
            }
            let decodedNewsDict = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Int:[NewsJson]]
            TemporaryHolder.instance.news = decodedNewsDict[0]!
            for (ind, item) in decodedNewsDict[1]!.enumerated() {
                if ind < 3 {
//                    self.data[1]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                    self.data[1]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "")
                }
            }

            if (self.data[1]?.count ?? 0) < 2 {
                self.newsSize = CGSize(width: 0, height: 0)

            } else {
                self.newsSize = nil
            }
            DispatchQueue.main.sync {
                self.collection.reloadData()
            }

            let login = UserDefaults.standard.string(forKey: "id_account") ?? ""
            let lastId = TemporaryHolder.instance.newsLastId

            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_NEWS + "accID=" + login + ((lastId != "" && lastId != "0") ? "&lastId=" + lastId : ""))!)
            request.httpMethod = "GET"

            URLSession.shared.dataTask(with: request) {
                data, error, responce in

                guard data != nil && !(String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false) else { return }

                if let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? JSON {
                    TemporaryHolder.instance.news?.append(contentsOf: NewsJsonData(json: json!)!.data!)
                }
                UserDefaults.standard.set(String(TemporaryHolder.instance.news?.first?.newsId ?? 0), forKey: "newsLastId")
                TemporaryHolder.instance.newsLastId = String(TemporaryHolder.instance.news?.first?.newsId ?? 0)
                UserDefaults.standard.synchronize()
                self.filteredNews = TemporaryHolder.instance.news?.filter { $0.isShowOnMainPage ?? false } ?? []

                for (ind, item) in self.filteredNews.enumerated() {
                    if ind < 3 {
//                        self.data[1]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.dateStart ?? "")
                        self.data[1]![ind + 1] = NewsCellData(title: item.header ?? "", desc: item.shortContent ?? "", date: item.created ?? "")
                    }
                }

                if (self.data[1]?.count ?? 0) < 2 {
                    self.newsSize = CGSize(width: 0, height: 0)

                } else {
                    self.newsSize = nil
                }

                DispatchQueue.main.sync {
                    self.collection.reloadData()
                }
                }.resume()
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromMainScreenVC.toCreateRequest {
            let vc = segue.destination as! AppsUser
            vc.isCreatingRequest_ = true
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromMainScreenVC.toRequest {
            let vc = segue.destination as! AppsUser
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromMainScreenVC.toSchet {
            let vc = segue.destination as! CounterTableVC
            vc.canCount = canCount
        
        } else if segue.identifier == Segues.fromMainScreenVC.toQuestionAnim {
            let vc = segue.destination as! QuestionsTableVC
            vc.performName_ = surveyName
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromMainScreenVC.toQuestions {
            let vc = segue.destination as! QuestionsTableVC
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromMainScreenVC.toDeals {
            let vc = segue.destination as! DealsListDescVC
            vc.data_ = deals[safe: dealsIndex]
            vc.anotherDeals_ = Array(deals.prefix(3))
        
        } else if segue.identifier == Segues.fromMainScreenVC.toFinancePay {
            let vc = segue.destination as! FinancePayAcceptVC
            vc.accountData_ = debt
        
        } else if segue.identifier == Segues.fromMainScreenVC.toNewsWAnim {
            let vc = segue.destination as! NewsListTVC
            vc.tappedNews = tappedNews
        
        } else if segue.identifier == Segues.fromMainScreenVC.toRequestAnim {
            let vc = segue.destination as! AppsUser
            vc.requestId_ = requestId
            vc.xml_ = mainScreenXml
            vc.delegate = self
        
        } else if segue.identifier == Segues.fromMainScreenVC.toAdmission {
            let vc = segue.destination as! AdmissionVC
            vc.data_ = (appsUser?.admission!)!
            vc.comments_ = (appsUser?.admissionComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            vc.name_ = appsUser?.typeName
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = true
            }
            
        } else if segue.identifier == Segues.fromMainScreenVC.toService {
            let vc = segue.destination as! TechServiceVC
            vc.data_ = (appsUser?.techService!)!
            vc.comments_ = (appsUser?.techServiceComm)!
            vc.reqId_ = appsUser?.reqId ?? ""
            vc.delegate = self
            if appsUser?.requestId_ != "" {
                appsUser?.requestId_ = ""
                appsUser?.xml_ = nil
                vc.isFromMain_ = true
            }
        
        } else if segue.identifier == Segues.fromMainScreenVC.toDealsList {
            let vc = segue.destination as! DealsListVC
            vc.data_ = deals
        }
    }
    
    func update() {
        update(method: "Request")
    }
    
    func update(method: String) {
        if method == "" {
            fetchDeals()
            fetchDebt()
            fetchNews()
            
        } else if method == "Request" {
            fetchRequests()
        
        } else if method == "Questions" {
            DispatchQueue.main.async {
                self.data[0] = [0 : CellsHeaderData(title: "Опросы")]
                self.collection.reloadData()
            }
            fetchQuestions()
        }
    }
}

final class CellsHeader: UICollectionReusableView {
    
    @IBOutlet private(set) weak var title:   UILabel!
    @IBOutlet private weak var detail:  UIButton!
    
    @IBAction private func titlePressed(_ sender: UIButton) {
        delegate?.tapped(name: title.text ?? "")
    }
    
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: CellsHeaderData, delegate: CellsDelegate? = nil) {
        
        title.text = item.title
//
//        if !item.isNeedDetail {
//            detail.isHidden = true
//
//        } else {
//            detail.isHidden = false
//        }
        
        self.delegate = delegate
        
        if item.title == "К оплате" || item.title ==  "Счетчики" {
            self.detail.setTitle("Подробнее", for: .normal)
        } else if item.title == "Версия" {
            self.detail.setTitleColor(UIColor.black, for: .normal)
            self.detail.setTitle("ver. 1.52", for: .normal)
        } else {
            self.detail.setTitle("Все", for: .normal)
        }
        
    }
    
}

private final class CellsHeaderData: MainDataProtocol {
    
    let title:          String
    let isNeedDetail:   Bool
    
    init(title: String, isNeedDetail: Bool = true) {
        self.title          = title
        self.isNeedDetail   = isNeedDetail
    }
}

class SurveyCell: UICollectionViewCell {
    
    @IBOutlet weak var title:               UILabel!
    @IBOutlet private weak var questions:   UILabel!
    @IBOutlet private weak var divider:     UILabel!
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        delegate?.pressed(at: indexPath!)
    }
    
    private var indexPath: IndexPath?
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: SurveyCellData, indexPath: IndexPath, delegate: CellsDelegate, isLast: Bool = false) {
        
        self.indexPath   = indexPath
        self.delegate    = delegate
        
        title.text       = item.title
        questions.text   = item.question
        divider.isHidden = isLast
    }
    
    class func fromNib() -> SurveyCell? {
        var cell: SurveyCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? SurveyCell {
                cell = view
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.questions.preferredMaxLayoutWidth = cell?.questions.bounds.size.width ?? 0.0
        return cell
    }
    
}

private final class SurveyCellData: MainDataProtocol {
    
    let title:      String
    let question:   String
    
    init(title: String, question: String) {
        self.title      = title
        self.question   = question
    }
}

final class NewsCell: UICollectionViewCell {
    
    @IBOutlet private weak var divider: UILabel!
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var date:    UILabel!
    
    fileprivate func display(_ item: NewsCellData, isLast: Bool = false) {
        
        if isLast {
            divider.isHidden = true
        
        } else {
            divider.isHidden = false
        }
        
        title.text  = item.title
        desc.text   = item.desc
        
        if item.date != "" {
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня") {
//            if dayDifference(from: df.date(from: item.date)!, style: "dd MMMM").contains(find: "Сегодня") {
                date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "HH:mm")
            
            } else {
                date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")
            }
        }
        
    }
    
    class func fromNib(viewWidth: CGFloat) -> NewsCell? {
        var cell: NewsCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? NewsCell {
                cell = cellView
            }
        }
        if !isNeedToScroll() {
            cell?.title.preferredMaxLayoutWidth = viewWidth - 55
            cell?.desc.preferredMaxLayoutWidth  = viewWidth - 30
            cell?.date.preferredMaxLayoutWidth  = viewWidth - 30
            
        } else {
            cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 25) - 55
            cell?.desc.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 50
            cell?.date.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 55
        }
        return cell
    }
}

final class NewsCellData: MainDataProtocol {
    
    let title:  String
    let desc:   String
    let date:   String
    
    init(title: String, desc: String, date: String) {
        self.title  = title
        self.desc   = desc
        self.date   = date
    }
}

final class EnableCell: UICollectionReusableView {
    
    fileprivate func display(_ item: String) {
        
    }
}

final class StockCell: UICollectionViewCell, FSPagerViewDataSource, FSPagerViewDelegate {
    
    @IBOutlet private weak var pagerHeight: NSLayoutConstraint!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var pagerView:   FSPagerView! {
        didSet {
            self.pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
        }
    }
    
    private var imgs: [UIImage] = []
    private var delegate:   CellsDelegate?
    private var indexPath:  IndexPath?
    private var isLoading = false
    
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return imgs.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        cell.imageView?.image = imgs[index]
        return cell
    }
    
    fileprivate func display(_ item: StockCellData, delegate: CellsDelegate? = nil, indexPath: IndexPath? = nil) {
        
        pagerView.interitemSpacing = 20
        pagerView.dataSource = self
        pagerView.delegate   = self
        
        let points = Double(UIScreen.pixelsPerInch ?? 0.0)
        if (300.0...320.0).contains(points) {
            pagerView.itemSize = CGSize(width: 288, height: 144)
            pagerHeight.constant = 144
            
        } else if (320.0...350.0).contains(points) {
            pagerView.itemSize = CGSize(width: 343, height: 174)
            pagerHeight.constant = 174
            
        } else if (350.0...400.0).contains(points) {
            pagerView.itemSize = CGSize(width: 343, height: 170)
            pagerHeight.constant = 170
            
        } else {
            pagerView.itemSize = CGSize(width: 382, height: 191)
            pagerHeight.constant = 191
        }

        
        if item.images.count == 0, let imgData = UserDefaults.standard.data(forKey: "DealsImg"), let img = UIImage(data: imgData)  {
            isLoading = true
            self.imgs = [img]
            self.pageControl.numberOfPages = 1
            self.pagerView.reloadData()
            
        } else if item.images.count != 0 {
            isLoading = false
            self.imgs = item.images
            self.pageControl.numberOfPages = self.imgs.count
            self.pagerView.reloadData()
            
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.setValue(UIImagePNGRepresentation(item.images.first!), forKey: "DealsImg")
                UserDefaults.standard.synchronize()
            }
        }
        
        self.delegate   = delegate
        self.indexPath  = indexPath
        
        
    }
    
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        if !isLoading {
            delegate?.stockCellPressed(currImg: index)
        }
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }
}

private final class StockCellData: MainDataProtocol {
    
    let images:     [UIImage]
    
    init(images: [UIImage]) {
        self.images = images
    }
}

final class RequestCell: UICollectionViewCell {
    
    @IBOutlet private var backBottom:  NSLayoutConstraint!
    @IBOutlet private var backTop:     NSLayoutConstraint!
    @IBOutlet private var descTop:     NSLayoutConstraint!
    @IBOutlet private var descBottom:  NSLayoutConstraint!
    
    @IBOutlet private weak var title:       UILabel!
    @IBOutlet private weak var desc:        UILabel!
    @IBOutlet private weak var icon:    	UIImageView!
    @IBOutlet private weak var date:        UILabel!
    @IBOutlet private weak var status:      UILabel!
    @IBOutlet private weak var back:        UIView!
    
    fileprivate func display(_ item: RequestCellData) {

        title.text  = item.title
        desc.text   = item.desc
        icon.image  = item.icon
        status.text = item.status.uppercased()
        
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy hh:mm:ss"
        df.isLenient = true
        date.text = dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM").contains(find: "Сегодня")
            ? dayDifference(from: df.date(from: item.date) ?? Date(), style: "").replacingOccurrences(of: ",", with: "")
            : dayDifference(from: df.date(from: item.date) ?? Date(), style: "dd MMMM")

        if item.isBack {
            backTop.constant    = 6
            backBottom.constant = 6
            descTop.constant    = 12
            descBottom.constant = 17
            back.isHidden = false

        } else {
            backTop.constant    = 0
            backBottom.constant = 0
            descTop.constant    = 2
            descBottom.constant = 12
            back.isHidden = true
        }

        let currTitle = item.title
        let titleDateString = currTitle.substring(fromIndex: currTitle.length - 19)
        df.dateFormat = "dd.MM.yyyy hh:mm:ss"
        if let titleDate = df.date(from: titleDateString) {
            df.dateFormat = "dd MMMM"
            df.locale = Locale(identifier: "Ru-ru")
            title.text = String(currTitle.dropLast(19)) + "на " + df.string(from: titleDate)
        }
        
    }
    
    class func fromNib(viewSize: CGFloat) -> RequestCell? {
        var cell: RequestCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? RequestCell {
                cell = view
            }
        }
        if isPlusDevices() {
            cell?.title.preferredMaxLayoutWidth = viewSize - 32//cell?.title.bounds.size.width ?? 0.0 + 20
            cell?.desc.preferredMaxLayoutWidth  = viewSize - 48//cell?.desc.bounds.size.width ?? 0.0 + 20
        
        } else {
            cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
            cell?.desc.preferredMaxLayoutWidth  = cell?.desc.bounds.size.width  ?? 0.0
        }

        return cell
    }
}

final class RequestCellData: MainDataProtocol {
    
    let title:  String
    let desc:   String
    let icon:   UIImage
    let date:   String
    let status: String
    let isBack: Bool
    let id:     String
    
    init(title: String, desc: String, icon: UIImage, date: String, status: String, isBack: Bool, id: String) {
        self.title  = title
        self.desc   = desc
        self.icon   = icon
        self.date   = date
        self.status = status
        self.isBack = isBack
        self.id     = id
    }
}

// Выведем версию приложения внизу
final class VersionCell: UICollectionViewCell {
    
    class func fromNib() -> VersionCell? {
        var cell: VersionCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? VersionCell {
                cell = cellView
            }
        }
        return cell
    }
    
}

final class RequestAddCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UIButton!
    @IBOutlet private weak var button:  UIButton!
    
    @IBAction private func pressed(_ sender: UIButton!) {
        delegate?.tapped(name: "Добавить заявку")
    }
    
    
    @IBAction func addRequestByTitle(_ sender: Any) {
        delegate?.tapped(name: "Добавить заявку")
    }
    
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: RequestAddCellData, delegate: CellsDelegate? = nil) {
        
        self.delegate = delegate
        title.setTitle(item.title, for: .normal)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        button.layer.shadowOpacity = 0.2
    }
}

private final class RequestAddCellData: MainDataProtocol {
    
    let title: String
    
    init(title: String) {
        self.title = title
    }
}

final class ForPayCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var date:    UILabel!
    @IBOutlet private weak var pay:     UIButton!
    
    fileprivate func display(_ item: ForPayCellData) {
        
        let defaults = UserDefaults.standard
        pay.isHidden = defaults.bool(forKey: "denyOnlinePayments")
        if (defaults.bool(forKey: "denyTotalOnlinePayments")) {
            pay.isHidden = true
        }
        
        title.text  = item.title
        
        if item.title.contains(find: "-") {
            title.textColor = .green
        
        } else {
            title.textColor = .black
        }
        
        if item.date != "" {
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yyyy"
            let currDate = df.date(from: item.date)
            df.dateFormat = "dd MMMM"
            df.locale = Locale(identifier: "Ru-ru")
            date.text = "До " + df.string(from: currDate ?? Date())
        }
        
        func fromNib() -> ForPayCell? {
            var cell: ForPayCell?
            let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
            nibViews?.forEach {
                if let cellView = $0 as? ForPayCell {
                    cell = cellView
                }
            }

            return cell
        }
    }
    
}

private final class ForPayCellData: MainDataProtocol {
    
    let title:  String
    let date:   String
    
    init(title: String, date: String) {
        self.title  = title
        self.date   = date
    }
}

final class SchetCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var date:    UILabel!
    @IBOutlet private weak var button:  UIButton!
    
    @IBAction private func buttonPressed(_ sender: UIButton) {
        delegate?.tapped(name: button.titleLabel?.text ?? "")
    }
    
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: SchetCellData, delegate: CellsDelegate? = nil) {
        
        title.text = item.title
        date.text  = item.date
        
        self.delegate = delegate

    }
    
    class func fromNib() -> SchetCell? {
        var cell: SchetCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? SchetCell {
                cell = cellView
            }
        }
        cell?.title.preferredMaxLayoutWidth = cell?.title.bounds.size.width ?? 0.0
        cell?.date.preferredMaxLayoutWidth  = cell?.date.bounds.size.width ?? 0.0
        return cell
    }
}

// Вывод версии
private final class VersionCellData: MainDataProtocol {
    
}

private final class SchetCellData: MainDataProtocol {
    
    let title:  String
    let date:   String
    
    init(title: String, date: String) {
        self.title = title
        self.date  = date
    }
}



