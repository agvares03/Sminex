//
//  QuestionsTableVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/31/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class QuestionsTableVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    open var delegate: MainScreenDelegate?
    open var performName_ = ""
    
    private var questions: [QuestionDataJson]? = []
    private var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        
        getQuestions()
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
        return CGSize(width: view.frame.size.width, height: 65.0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        index = indexPath.row
        performSegue(withIdentifier: Segues.fromQuestionsTableVC.toQuestion, sender: self)
    }
    
    func getQuestions() {
        
        loader.isHidden = false
        loader.startAnimating()
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_QUESTIONS + "accID=" + id)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            defer {
                DispatchQueue.main.sync {
                    self.loader.isHidden = true
                    self.loader.stopAnimating()
                    self.collection.reloadData()
                    
                    for (index, item) in (self.questions?.enumerated())! {
                        if item.name == self.performName_ {
                            self.index = index
                            self.performSegue(withIdentifier: Segues.fromQuestionsTableVC.toQuestion, sender: self)
                        }
                    }
                    
                }
            }
            let json = try? JSONSerialization.jsonObject(with: data!,
                                                         options: .allowFragments)
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
            }
            self.questions = filtered
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromQuestionsTableVC.toQuestion {
            let vc = segue.destination as! QuestionAnswerVC
            vc.question_ = questions?[index]
            vc.delegate = delegate
        }
    }
}

final class QuestionsTableCell: UICollectionViewCell {
    
    @IBOutlet private weak var title:   UILabel!
    @IBOutlet private weak var desc:    UILabel!
    
    fileprivate func display(_ item: QuestionDataJson) {
        
        title.text = item.name
        
        var isAnswered = false
        
        item.questions?.forEach {
            if $0.isAcceptSomeAnswers ?? false {
                isAnswered = true
            }
        }
        
        desc.text = (isAnswered)
            ? "Вы начали опрос"
            : String(item.questions?.count ?? 0) + " вопросов"
    }
    
}
