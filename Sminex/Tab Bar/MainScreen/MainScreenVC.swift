//
//  MainScreenVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/22/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

private protocol MainDataProtocol:  class {}
private protocol CellsDelegate:    class {
    func tapped(name: String)
    func pressed(at indexPath: IndexPath)
}
protocol MainScreenDelegate: class {
    func update()
}

final class MainScreenVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, CellsDelegate, UICollectionViewDelegateFlowLayout, MainScreenDelegate {
    
    @IBOutlet private weak var collection: UICollectionView!
    
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
            1 : StockCellData(images: [UIImage(named: "AppIcon")!])],
        3 : [
            0 : CellsHeaderData(title: "Заявки")],
        4 : [
            0 : CellsHeaderData(title: "К оплате"),
            1 : ForPayCellData(title: "114 246P", date: "До 31 января")],
        5 : [
            0 : CellsHeaderData(title: "Счетчики"),
            1 : SchetCellData(title: "Осталось 4 дня для передачи показаний", date: "Передача с 20 по 25 января")]]
    
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
        fetchRequests()
        fetchQuestions()
        collection.delegate     = self
        collection.dataSource   = self
        automaticallyAdjustsScrollViewInsets = false
        
        // Поправим Navigation bar
        navigationController?.navigationBar.isTranslucent   = true
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.tintColor       = .white
        navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17, weight: .thin) ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tabBarController?.tabBar.isHidden = false
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (data[section]?.count ?? 2) - 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CellsHeader", for: indexPath) as! CellsHeader
        header.display(data[indexPath.section]![0] as! CellsHeaderData, delegate: self)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let title = (data[indexPath.section]![0] as! CellsHeaderData).title
        
        if title == "Опросы" {
            return CGSize(width: view.frame.size.width, height: 110.0)
        
        } else if title == "Новости" {
            return CGSize(width: view.frame.size.width, height: 75.0)
        
        } else if title == "Акции и предложения" {
            return CGSize(width: view.frame.size.width, height: 200.0)
        
        } else if title == "Заявки" {
            
            if indexPath.row == data[indexPath.section]!.count - 2 {
                return CGSize(width: view.frame.size.width, height: 50.0)
            }
            return CGSize(width: view.frame.size.width, height: 100.0)
        
        } else if title == "К оплате" {
            return CGSize(width: view.frame.size.width, height: 75.0)
        
        } else if title == "Счетчики" {
            return CGSize(width: view.frame.size.width, height: 95.0)
        
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
            cell.display(data[indexPath.section]![indexPath.row + 1] as! StockCellData)
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
        }
    }
    
    private func fetchRequests(_ isBackground: Bool = false) {
        
        var count = 1
        DB().getRequests().forEach {
            data[3]![count] = $0
            count += 1
        }
        data[3]![count] = RequestAddCellData(title: "Добавить заявку")
        
        if !isBackground {
            let vc = AppsUser()
            
            DispatchQueue.global(qos: .background).async {
                let res = vc.getRequests(isBackground: true)
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
    
    private func fetchQuestions() {
        DispatchQueue.global().async {
            
            let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
            
            var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, error, responce in
                
                
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
                    
                    if filtered.count > 1 {
                        self.data[0]![1] = SurveyCellData(title: filtered.last?.name ?? "", question: "\(filtered.last?.questions?.count ?? 0) вопросов")
                        self.data[0]![2] = SurveyCellData(title: filtered[filtered.count - 2].name!, question: "\(filtered[filtered.count - 2].questions?.count ?? 0) вопросов")
                    
                    } else if filtered.count == 1 {
                        self.data[0]![1] = SurveyCellData(title: filtered.last?.name ?? "", question: "\(filtered.last?.questions?.count ?? 0) вопросов")
                    
//                    } else if filtered.count == 0 {
//                        self.data.removeValue(forKey: 0)
                    }
                
                    DispatchQueue.main.sync {
                        self.collection.reloadData()
                    }
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
        }
    }
    
    func update() {
        fetchRequests(true)
        fetchQuestions()
    }
}

final class CellsHeader: UICollectionReusableView {
    
    @IBOutlet private weak var title:   UILabel!
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
}

private final class NewsCellData: MainDataProtocol {
    
    let title:  String
    let desc:   String
    let date:   String
    
    init(title: String, desc: String, date: String) {
        self.title  = title
        self.desc   = desc
        self.date   = date
    }
}

final class StockCell: UICollectionViewCell {
    
    @IBOutlet private weak var image:   UIImageView!
    @IBOutlet private weak var section: UIPageControl!
    
    fileprivate func display(_ item: StockCellData) {
        
        image.image             = item.images.first
        section.currentPage     = 0
        section.numberOfPages   = item.images.count
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
}

private final class SchetCellData: MainDataProtocol {
    
    let title:  String
    let date:   String
    
    init(title: String, date: String) {
        self.title = title
        self.date  = date
    }
}


