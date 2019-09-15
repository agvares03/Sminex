//
//  QuestionsTableVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/31/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

protocol QuestionTableDelegate {
    func update()
}

final class QuestionsTableVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, QuestionTableDelegate {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var emptyLabel:  UILabel!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        UserDefaults.standard.set(true, forKey: "backBtn")
        navigationController?.popViewController(animated: true)
    }
    
    public var delegate: MainScreenDelegate?
    public var performName_ = ""
    
    private var refreshControl: UIRefreshControl?
    private var questions: [QuestionDataJson]? = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        TemporaryHolder.instance.menuQuesions = 0
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            collection.refreshControl = refreshControl
        } else {
            collection.addSubview(refreshControl!)
        }
        
        loader.isHidden = false
        loader.startAnimating()
        getQuestions()
    }
    
    @objc private func refresh(_ sender: UIRefreshControl?) {
        emptyLabel.isHidden = true
        getQuestions()
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
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
        self.refresh(nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return questions?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionsTableCell", for: indexPath) as! QuestionsTableCell
        cell.display(questions![indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if questions![indexPath.row].dateStart != "" && questions![indexPath.row].dateStart != nil && !(questions![indexPath.row].dateStart?.contains(find: "/"))!{
            if questions![indexPath.row].dateStop != ""{
                return CGSize(width: view.frame.size.width, height: heightForTitle(text: questions![indexPath.row].name!, width: self.view.frame.size.width - 62) + 95)
            }
            return CGSize(width: view.frame.size.width, height: heightForTitle(text: questions![indexPath.row].name!, width: self.view.frame.size.width - 62) + 80)
        }else{
            return CGSize(width: view.frame.size.width, height: heightForTitle(text: questions![indexPath.row].name!, width: self.view.frame.size.width - 62) + 55)
        }
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromQuestionsTableVC.toQuestion, sender: self)
    }
    
    func getQuestions() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
        request.httpMethod = "GET"
        print("========")
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.collection.reloadData()
                    self.loader.stopAnimating()
                    self.loader.isHidden = true
                    
                    if #available(iOS 10.0, *) {
                        self.collection.refreshControl?.endRefreshing()
                    } else {
                        self.refreshControl?.endRefreshing()
                    }
                    
                    if self.questions?.count == 0 {
                        self.emptyLabel.isHidden = false
                    
                    } else {
                        self.emptyLabel.isHidden = true
                    }
                    
                    for (index, item) in (self.questions?.enumerated())! {
                        if item.name == self.performName_ {
                            self.index = index
                            self.performSegue(withIdentifier: Segues.fromQuestionsTableVC.toQuestion, sender: self)
                        }
                    }
                    
                }
            }
            guard data != nil else { return }
//            print(String(data: data!, encoding: .utf8) ?? "")
            
            let json = try? JSONSerialization.jsonObject(with: data!,
                                                         options: .allowFragments)
            let unfilteredData = QuestionsJson(json: json! as! JSON)?.data
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
            var kol = 0
            filtered.forEach{
                if !$0.isReaded!{
                    kol += 1
                }
            }
            self.questions = filtered
//            TemporaryHolder.instance.menuQuesions = kol
            filtered.forEach{
                if !$0.isReaded!{
                    self.sendRead(groupID: $0.id!)
                }
            }
            TemporaryHolder.instance.menuQuesions = 0
            }.resume()
    }
    
    private func sendRead(groupID: Int) {
        let id = UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986() ?? ""
        let idGroup = String(groupID).stringByAddingPercentEncodingForRFC3986() ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + "SetQuestionGroupReadedState.ashx?" + "groupID=" + idGroup + "&accID=" + id)!)
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
    
    func update() {
        getQuestions()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromQuestionsTableVC.toQuestion {
            let vc = segue.destination as! QuestionAnswerVC
            vc.question_ = questions?[index]
            vc.delegate = delegate
            vc.isFromMain_ = performName_ != ""
            vc.questionDelegate = self
            performName_ = ""
        } else if segue.identifier == Segues.fromFirstController.toLoginActivity {
            
            let vc = segue.destination as! UINavigationController
            (vc.viewControllers.first as! ViewController).roleReg_ = "1"
            
        }
    }
}

final class QuestionsTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    @IBOutlet private weak var dateStart:   UILabel!
    @IBOutlet weak var titleHeight:     NSLayoutConstraint!
    @IBOutlet weak var dateHeight:      NSLayoutConstraint!
    
    fileprivate func display(_ item: QuestionDataJson) {
        
        title.text = item.name
        /*
        var isAnswered = true
        item.questions?.forEach {
            if !($0.isCompleteByUser ?? false) {
                isAnswered = false
            }
        }
        */
        if item.dateStart != "" && item.dateStart != nil && !(item.dateStart?.contains(find: "/"))!{
            dateStart.text = "Опрос проводится с \(item.dateStart?.replacingOccurrences(of: " 00:00:00", with: "") ?? "")"
            dateHeight.constant = 17
            if item.dateStop != ""{
                dateStart.text = "Опрос проводится с \(item.dateStart!.replacingOccurrences(of: " 00:00:00", with: "")) по \(item.dateStop!.replacingOccurrences(of: " 00:00:00", with: ""))"
                dateHeight.constant = 42
            }
            dateStart.isHidden = false
        }else{
            dateHeight.constant = 0
            dateStart.text = ""
            dateStart.isHidden = true
        }
        var txt = " вопроса"
        let col_questions = (item.questions?.count)!
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
        
        var isAnswered = false
        let defaults = UserDefaults.standard
        let array = defaults.array(forKey: "PollsStarted") as? [Int] ?? [Int]()
        if array.contains(item.id!) {
            isAnswered = true
        }
        titleHeight.constant = heightForTitle(text: item.name!, width: title.frame.size.width) + 10
        print("titleHeight: ", titleHeight.constant)
        desc.text = (isAnswered)
            ? "Вы начали опрос"
            : String(item.questions?.count ?? 0) + txt
        desc.textColor = (isAnswered)
            ? .gray
            : UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1)
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
    
}
