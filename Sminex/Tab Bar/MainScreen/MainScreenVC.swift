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

private protocol MainDataProtocol:  class {}
private protocol CellsDelegate:    class {
    func tapped(name: String)
    func pressed(at indexPath: IndexPath)
    func stockCellPressed(currImg: Int)
}
protocol MainScreenDelegate: class {
    func update()
}

final class MainScreenVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CellsDelegate, UICollectionViewDelegateFlowLayout, MainScreenDelegate {
    
    @IBOutlet private weak var collection: UICollectionView!
    
    @IBAction private func payButtonPressed(_ sender: UIButton) {
        requestPay()
    }
    
    private var surveyName = ""
    private var canCount = true
    private var data: [Int:[Int:MainDataProtocol]] = [
        0 : [
            0 : CellsHeaderData(title: "Опросы")
            ],
        1 : [
            0 : CellsHeaderData(title: "Новости"),
            1 : NewsCellData(title: "Отключение горячей воды", desc: "22 ноябя с 12:00 до 13:00 будет отключена горяча...", date: "сегодня, 10:05"),
            2 : NewsCellData(title: "Собрание жильцов", desc: "20 ноября, с 11:00 до 18:00", date: "15 октября"),
            3 : NewsCellData(title: "Вынесено решение придомового комитета о поводу подземной парковки", desc: "20 ноября, с 11:00 до 18:00", date: "13 октября")],
        2 : [
            0 : CellsHeaderData(title: "Акции и предложения", isNeedDetail: false),
            1 : StockCellData(images: [])
            ],
        3 : [
            0 : CellsHeaderData(title: "Заявки")],
        4 : [
            0 : CellsHeaderData(title: "К оплате")
            ],
        5 : [
            0 : CellsHeaderData(title: "Счетчики"),
            1 : SchetCellData(title: "Осталось 4 дня для передачи показаний", date: "Передача с 20 по 25 января")]]
    private var questionSize:   CGSize?
    private var url:            URLRequest?
    private var debt:           AccountDebtJson?
    private var deals: [DealsJson] = []
    private var dealsIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        fetchDebt()
        fetchDeals()
        fetchRequests()
        fetchQuestions()
        collection.delegate     = self
        collection.dataSource   = self
        automaticallyAdjustsScrollViewInsets = false
        
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent   = true
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.tintColor       = .white
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17, weight: .heavy) ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.selectedItem?.title = "Главная"
        tabBarController?.tabBar.isHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if data.keys.contains(section) {
            return (data[section]?.count ?? 2) - 1
            
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CellsHeader", for: indexPath) as! CellsHeader
        header.display(data[indexPath.section]![0] as! CellsHeaderData, delegate: self)
        
        if header.title.text == "Опросы" && questionSize != nil {
            header.frame.size = questionSize!
        }
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "Опросы" {
            return questionSize == nil ? CGSize(width: view.frame.size.width, height: 110.0) : questionSize!
        
        } else if title == "Новости" {
            let cell = NewsCell.fromNib()
            cell?.display(data[indexPath.section]![indexPath.row + 1] as! NewsCellData)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
            return CGSize(width: view.frame.size.width, height: size.height)
        
        } else if title == "Акции и предложения" {
            return CGSize(width: view.frame.size.width, height: 200.0)
        
        } else if title == "Заявки" {
            if indexPath.row == data[indexPath.section]!.count - 2 {
                return CGSize(width: view.frame.size.width, height: 50.0)
            }
            return CGSize(width: view.frame.size.width, height: 100.0)
        
        } else if title == "К оплате" {
            return CGSize(width: view.frame.size.width, height: 80.0)
        
        } else if title == "Счетчики" {
            let cell = SchetCell.fromNib()
            cell?.display(data[indexPath.section]![indexPath.row + 1] as! SchetCellData)
            let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
            return CGSize(width: view.frame.size.width, height: size.height)
        
        } else {
            return CGSize(width: view.frame.size.width, height: 100.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "Опросы" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SurveyCell", for: indexPath) as! SurveyCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! SurveyCellData, indexPath: indexPath, delegate: self)
            return cell
        
        } else if title == "Новости" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as! NewsCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! NewsCellData)
            return cell
        
        } else if title == "Акции и предложения" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StockCell", for: indexPath) as! StockCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! StockCellData, delegate: self, indexPath: indexPath)
            return cell
        
        } else if title == "Заявки" {
            
            if indexPath.row == data[indexPath.section]!.count - 2 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestAddCell", for: indexPath) as! RequestAddCell
                cell.display(data[indexPath.section]![indexPath.row + 1] as! RequestAddCellData, delegate: self)
                return cell
                
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestCell", for: indexPath) as! RequestCell
                cell.display(data[indexPath.section]![indexPath.row + 1] as! RequestCellData)
                return cell
            }
        
        } else if title == "К оплате" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ForPayCell", for: indexPath) as! ForPayCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! ForPayCellData)
            return cell
        
        } else if title == "Счетчики" {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScetCell", for: indexPath) as! SchetCell
            cell.display(data[indexPath.section]![indexPath.row + 1] as! SchetCellData, delegate: self)
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
    
    func pressed(at indexPath: IndexPath) {
        if let cell = collection.cellForItem(at: indexPath) as? SurveyCell {
            surveyName = cell.title.text ?? ""
            performSegue(withIdentifier: Segues.fromMainScreenVC.toQuestionAnim, sender: self)
        
//        } else if let _ = collection.cellForItem(at: indexPath) as? StockCell {
//            performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
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
        
//        } else if name == "Акции и предложения" {
//            performSegue(withIdentifier: Segues.fromMainScreenVC.toDeals, sender: self)
        
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
    
    private func fetchRequests(_ isBackground: Bool = false) {
        
        var count = 1
        DB().getRequests().forEach {
            data[3]![count] = $0
            count += 1
        }
        data[3]![count] = RequestAddCellData(title: "Добавить заявку")
        
        if !isBackground {
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
        }
    }
    
    func getRequests() -> [RequestCellData] {
        
        var returnArr: [RequestCellData] = []
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            
            let login = UserDefaults.standard.string(forKey: "login")!
            let pass  = getHash(pass: UserDefaults.standard.string(forKey: "pass")!, salt: self.getSalt(login: login))
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_APPS_COMM + "login=" + login + "&pwd=" + pass)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                defer {
                    group.leave()
                }
                
                #if DEBUG
                    print(String(data: data!, encoding: .utf8)!)
                #endif
                
                let xml = XML.parse(data!)
                let requests = xml["Requests"]
                let row = requests["Row"]
                var rows: [Request] = []
                var rowComms: [String : [RequestComment]]  = [:]
                
                row.forEach { row in
                    rows.append(Request(row: row))
                    rowComms[row.attributes["ID"]!] = []
                    
                    row["Comm"].forEach {
                        rowComms[row.attributes["ID"]!]?.append( RequestComment(row: $0) )
                    }
                }
                
                rows.forEach {
                    let isAnswered = rowComms[$0.id!]?.count == 0 ? false : true
                    
                    var date = $0.planDate!
                    date.removeLast(9)
                    let lastComm = rowComms[$0.id!]?[(rowComms[$0.id!]?.count)! - 1]
                    let icon = !($0.status?.contains(find: "Отправлена"))! ? UIImage(named: "check_label")! : UIImage(named: "processing_label")!
                    returnArr.append( RequestCellData(title: $0.name!,
                                                      desc: rowComms[$0.id!]?.count == 0 ? $0.text! : (lastComm?.text!)!,
                                                      icon: icon,
                                                      date: date,
                                                      status: $0.status!,
                                                      isBack: isAnswered) )
                }
            }.resume()
        }
        
        group.wait()
        var ret: [RequestCellData] = []
        
        if returnArr.count != 0 {
            ret.append(returnArr.popLast()!)
        }
        if returnArr.count != 0 {
            ret.append(returnArr.popLast()!)
        }
        return ret
    }
    
    // Качаем соль
    private func getSalt(login: String) -> Data {
        
        var salt: Data?
        let queue = DispatchGroup()
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.SOLE + "login=" + login)!)
        request.httpMethod = "GET"
        
        queue.enter()
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            defer {
                queue.leave()
            }
            
            if error != nil {
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            salt = data
            
            #if DEBUG
                print("salt is = \(String(describing: String(data: data!, encoding: .utf8)))")
            #endif
            
            }.resume()
        
        queue.wait()
        return salt ?? Data()
    }
    
    private func fetchQuestions() {
        DispatchQueue.global().async {
            
            let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                guard data != nil else { return }
                let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                let unfilteredData = QuestionsJson(json: json! as! JSON)?.data
                var filtered: [QuestionDataJson] = []
                unfilteredData?.forEach { json in
                    
                    var isContains = false
                    json.questions?.forEach {
                        if $0.isCompleteByUser ?? true {
                            isContains = true
                        }
                    }
                    if !isContains {
                        filtered.append(json)
                    }
                    
                    if filtered.count == 0 {
                        self.questionSize = CGSize(width: 0, height: 0)
                    }
                    if filtered.count == 1 {
                        self.questionSize = nil
                        self.data[0]![1] = SurveyCellData(title: filtered.last?.name ?? "", question: "\(filtered.last?.questions?.count ?? 0) вопросов")
                    }
                    if filtered.count > 1 {
                        self.questionSize = nil
                        self.data[0]![1] = SurveyCellData(title: filtered.last?.name ?? "", question: "\(filtered.last?.questions?.count ?? 0) вопросов")
                        self.data[0]![2] = SurveyCellData(title: filtered[filtered.count - 2].name!, question: "\(filtered[filtered.count - 2].questions?.count ?? 0) вопросов")
                    }
                
                    DispatchQueue.main.sync {
                        self.collection.reloadData()
                    }
                }
                
                if unfilteredData?.count == 0 {
                    DispatchQueue.main.sync {
                        self.questionSize = CGSize(width: 0, height: 0)
                        self.collection.reloadData()
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
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.deals = (DealsDataJson(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)?.data)!
            var imgs: [UIImage] = []
            
            self.deals.forEach {
                imgs.append( $0.img ?? UIImage() )
            }
            self.data[2]![1] = StockCellData(images: imgs)
            
            #if DEBUG
            //                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
    }
    
    private func fetchDebt() {
        
        let defaults = UserDefaults.standard
        
        self.data[4]![1] = ForPayCellData(title: defaults.string(forKey: "ForPayTitle") ?? "", date: defaults.string(forKey: "ForPayDate") ?? "")
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.ACCOUNT_DEBT + "login=" + login + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.collection.reloadData()
                }
            }
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in  } ) )
                
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.debt = AccountDebtData(json: try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! JSON)?.data!
            var datePay = self.debt?.datePay
            datePay?.removeLast(9)
            self.data[4]![1] = ForPayCellData(title: String(self.debt?.sumPay ?? 0.0) + " ₽", date: "До " + (datePay ?? ""))
            
            defaults.setValue(String(self.debt?.sumPay ?? 0.0) + " ₽", forKey: "ForPayTitle")
            defaults.setValue("До " + (datePay ?? ""), forKey: "ForPayDate")
            defaults.synchronize()
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8)!)
            #endif
            
            }.resume()
    }
    
    private func requestPay() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let password = getHash(pass: UserDefaults.standard.string(forKey: "pass") ?? "", salt: getSalt(login: login))
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.PAY_ONLINE + "login=" + login + "&pwd=" + password + "&amount=" + String(debt?.sumPay ?? 0.0))!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: String(data: data!, encoding: .utf8)?.replacingOccurrences(of: "error: ", with: "") ?? "", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "OK", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            self.url = URLRequest(url: URL(string: String(data: data!, encoding: .utf8) ?? "")!)
            
            DispatchQueue.main.sync {
                self.performSegue(withIdentifier: Segues.fromMainScreenVC.toFinancePay, sender: self)
            }
            
            #if DEBUG
            print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            }.resume()
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
            vc.data_ = deals[dealsIndex]
        
        } else if segue.identifier == Segues.fromMainScreenVC.toFinancePay {
            let vc = segue.destination as! FinancePayVC
            vc.url_ = url
        }
    }
    
    func update() {
        fetchRequests(true)
        fetchQuestions()
        fetchDeals()
        fetchDebt()
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
        
        if !item.isNeedDetail {
            detail.isHidden = true
        
        } else {
            detail.isHidden = false
        }
        
        self.delegate = delegate
        
        if item.title == "К оплате" || item.title ==  "Счетчики" {
            self.detail.setTitle("Подробнее", for: .normal)
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
    
    @IBOutlet weak var title:       UILabel!
    @IBOutlet private weak var questions:   UILabel!
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        delegate?.pressed(at: indexPath!)
    }
    
    private var indexPath: IndexPath?
    private var delegate: CellsDelegate?
    
    fileprivate func display(_ item: SurveyCellData, indexPath: IndexPath, delegate: CellsDelegate) {
        
        self.indexPath  = indexPath
        self.delegate   = delegate
        
        title.text      = item.title
        questions.text  = item.question
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
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var date:    UILabel!
    
    fileprivate func display(_ item: NewsCellData) {
        
        title.text  = item.title
        desc.text   = item.desc
        date.text   = item.date
    }
    
    class func fromNib() -> NewsCell? {
        var cell: NewsCell?
        let nibViews = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        nibViews?.forEach {
            if let cellView = $0 as? NewsCell {
                cell = cellView
            }
        }
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 25) - 25
        cell?.desc.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 25
        cell?.date.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 25
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

final class StockCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet private weak var scroll:  UIScrollView!
    @IBOutlet private weak var section: UIPageControl!
    
    private var delegate:   CellsDelegate?
    private var indexPath:  IndexPath?
    private var isLoading = false
    
    fileprivate func display(_ item: StockCellData, delegate: CellsDelegate? = nil, indexPath: IndexPath? = nil) {
        
        if item.images.count == 0, let imgData = UserDefaults.standard.data(forKey: "DealsImg"), let img = UIImage(data: imgData)  {
            let image = UIImageView(frame: CGRect(x: 0, y: 0, width: 300, height: Int(scroll.frame.size.height)))
            image.image = img
            isLoading = true
            scroll.addSubview(image)
            
        } else if item.images.count != 0 {
            var x = 0
            isLoading = false
            
            item.images.forEach {
                let image    = UIImageView(frame: CGRect(x: x, y: 0, width: 300, height: Int(scroll.frame.size.height)))
                x           += 320
                image.image  = $0
                scroll.addSubview(image)
            }
            DispatchQueue.global(qos: .background).async {
                UserDefaults.standard.setValue(UIImagePNGRepresentation(item.images.first!), forKey: "DealsImg")
                UserDefaults.standard.synchronize()
            }
            scroll.contentSize  = CGSize(width: CGFloat(x), height: scroll.frame.size.height)
        }
        scroll.delegate         = self
        section.currentPage     = 0
        section.numberOfPages   = item.images.count == 0 ? 1 : item.images.count
        
        self.delegate   = delegate
        self.indexPath  = indexPath
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        scroll.addGestureRecognizer(tap)
    }
    
    @objc private func imageTapped(_ sender: UITapGestureRecognizer) {
        if !isLoading {
            delegate?.stockCellPressed(currImg: section.currentPage)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        section.currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        scroll.setContentOffset(CGPoint(x: 320 * section.currentPage, y: 0), animated: true)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        section.currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
        scroll.setContentOffset(CGPoint(x: 320 * section.currentPage, y: 0), animated: true)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            section.currentPage = Int(round(scrollView.contentOffset.x / scrollView.frame.size.width))
            scroll.setContentOffset(CGPoint(x: 320 * section.currentPage, y: 0), animated: true)
        }
    }
}

private final class StockCellData: MainDataProtocol {
    
    let images:     [UIImage]
    
    init(images: [UIImage]) {
        self.images = images
    }
}

final class RequestCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var icon:    UIImageView!
    @IBOutlet private weak var date:    UILabel!
    @IBOutlet private weak var status:  UILabel!
    @IBOutlet private weak var back:    UIView!
    
    fileprivate func display(_ item: RequestCellData) {
        
        title.text  = item.title
        desc.text   = item.desc
        icon.image  = item.icon
        status.text = item.status
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        date.text = dayDifference(from: dateFormatter.date(from: item.date)!, style: "dd.MM.yyyy")
        
        if item.isBack {
            back.isHidden = false
        }
    }
}

final class RequestCellData: MainDataProtocol {
    
    let title:  String
    let desc:   String
    let icon:   UIImage
    let date:   String
    let status: String
    let isBack: Bool
    
    init(title: String, desc: String, icon: UIImage, date: String, status: String, isBack: Bool) {
        self.title  = title
        self.desc   = desc
        self.icon   = icon
        self.date   = date
        self.status = status
        self.isBack = isBack
    }
}

final class RequestAddCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UIButton!
    @IBOutlet private weak var button:  UIButton!
    
    @IBAction private func pressed(_ sender: UIButton!) {
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
        
        title.text  = item.title
        date.text   = item.date
        
        if item.title.contains(find: "-") {
            title.textColor = .green
        
        } else {
            title.textColor = .black
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
        cell?.title.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 25) - 25
        cell?.date.preferredMaxLayoutWidth  = (cell?.contentView.frame.size.width ?? 25) - 25
        return cell
    }
}

private final class SchetCellData: MainDataProtocol {
    
    let title:  String
    let date:   String
    
    init(title: String, date: String) {
        self.title = title
        self.date  = date
    }
}



