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
        navigationController?.popViewController(animated: true)
    }
    
    open var delegate: MainScreenDelegate?
    open var performName_ = ""
    
    private var refreshControl: UIRefreshControl?
    private var questions: [QuestionDataJson]? = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refresh(nil)
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
        return CGSize(width: view.frame.size.width, height: 85.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromQuestionsTableVC.toQuestion, sender: self)
    }
    
    func getQuestions() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
        request.httpMethod = "GET"
        
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
            self.questions = filtered
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
        }
    }
}

final class QuestionsTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
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
        
        desc.text = (isAnswered)
            ? "Вы начали опрос"
            : String(item.questions?.count ?? 0) + txt
        desc.textColor = (isAnswered)
            ? .gray
            : UIColor(red: 1/255, green: 122/255, blue: 255/255, alpha: 1)
    }
    
}
