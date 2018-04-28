//
//  QuestionAnswerVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/31/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class QuestionAnswerVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var goButton:    UIButton!
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: answers)
        userDefaults.set(encodedData, forKey: String(question_?.id ?? 0))
        userDefaults.synchronize()
        
        if !isFromMain_ {
            navigationController?.popViewController(animated: true)
        
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        
        var answerArr: [Int] = []
        
        selectedAnswers.forEach {
            answerArr.append((question_?.questions![currQuestion].answers![$0].id)!)
        }
        guard answerArr.count != 0 else { return }
        
        answers[(question_?.questions![currQuestion].groupId!)!] = answerArr
        
        isAccepted = false
        if (currQuestion + 1) < question_?.questions?.count ?? 0 {
            collection.reloadData()
            currQuestion += 1
        
        } else {
            
            startAnimation()
            DispatchQueue.global(qos: .userInteractive).async {
                self.sendAnswer()
            }
        }
    }
    
    open var isFromMain_ = false
    open var delegate: MainScreenDelegate?
    open var question_: QuestionDataJson?
    
    private var currQuestion = 0
    private var answers: [Int:[Int]] = [:]
    private var tap: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopAnimation()
        navigationItem.title    = question_?.name
        
        let decoded = UserDefaults.standard.object(forKey: String(question_?.id ?? 0))
        if decoded != nil {
            answers = NSKeyedUnarchiver.unarchiveObject(with: decoded as! Data) as! [Int:[Int]]
        }
        currQuestion = answers.count
        
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    @objc private func screenEdgeSwiped(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard currQuestion != 0 else { return }
        
        if #available(iOS 10.0, *) {
            UIViewPropertyAnimator(duration: 0, curve: .linear) {
                self.collection.frame.origin.x = recognizer.location(in: self.view).x
            }.startAnimation()
        } else {
            self.collection.frame.origin.x = recognizer.location(in: self.view).x
        }
        
        if recognizer.state == .ended {
            if recognizer.location(in: view).x > 100 {
                currQuestion -= 1
                collection.alpha = 0
                collection.frame.origin.x = 0
                if #available(iOS 10.0, *) {
                    UIViewPropertyAnimator(duration: 0, curve: .linear) {
                        self.collection.alpha = 1
                    }.startAnimation()
                } else {
                    collection.alpha = 1
                }
                collection.reloadData()
                
            } else {
                if #available(iOS 10.0, *) {
                    UIViewPropertyAnimator(duration: 0, curve: .linear) {
                        self.collection.frame.origin.x = 0
                    }.startAnimation()
                    
                } else {
                    collection.frame.origin.x = 0
                }
            }
        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap!)
        view.frame.origin.y = -250
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.removeGestureRecognizer(tap!)
        view.frame.origin.y = 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return question_?.questions![currQuestion].answers?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        isSomeAnswers = (question_?.questions![currQuestion].isAcceptSomeAnswers)!
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionAnswerCell", for: indexPath) as! QuestionAnswerCell
        cell.display((question_?.questions![currQuestion].answers![indexPath.row])!, index: indexPath.row)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        isSomeAnswers = (question_?.questions![currQuestion].isAcceptSomeAnswers)!
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "QuestionAnswerHeader", for: indexPath) as! QuestionAnswerHeader
        header.display((question_?.questions![currQuestion])!, currentQuestion: currQuestion, questionCount: question_?.questions?.count ?? 0)
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = QuestionAnswerCell.fromNib()
        cell?.display((question_?.questions![currQuestion].answers![indexPath.row])!, index: indexPath.row)
        let size  = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let cell = QuestionAnswerHeader.fromNib()
        cell?.display((question_?.questions![currQuestion])!, currentQuestion: currQuestion, questionCount: question_?.questions?.count ?? 0)
        let size  = cell?.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
        return CGSize(width: view.frame.size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if !isSomeAnswers {
            isAccepted = false
            NotificationCenter.default.post(name: NSNotification.Name("Uncheck"), object: nil)
        }
        (collectionView.cellForItem(at: indexPath) as! QuestionAnswerCell).didTapOnOffButton()
    }
    
    private func startAnimation() {
        loader.isHidden = false
        loader.startAnimating()
        goButton.isHidden = true
    }
    
    private func stopAnimation() {
        loader.isHidden = true
        loader.stopAnimating()
        goButton.isHidden = false
    }
    
    private func sendAnswer() {
        
        let id = UserDefaults.standard.string(forKey: "id_account") ?? ""
        let groupId = question_?.id ?? 0
        
        var request = URLRequest(url: URL(string: "\(Server.SERVER)\(Server.SAVE_ANSWER)accID=\(id)&groupID=\(groupId)")!)
        request.httpMethod = "POST"
        
        var json: [[String:Any]] = []
        
        answers.forEach { (arg) in
            let (key, value) = arg
            value.forEach {
                json.append( ["QuestionID":key, "AnswerID":$0, "Comment":""] )
            }
        }
        
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                alert.addAction( UIAlertAction(title: "ОК", style: .default, handler: { (_) in } ) )
                DispatchQueue.main.sync {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            
            #if DEBUG
                print(String(data: data!, encoding: .utf8) ?? "")
            #endif
            
            DispatchQueue.main.async {
                DispatchQueue.global(qos: .background).async {
                    let userDefaults = UserDefaults.standard
                    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.answers)
                    userDefaults.set(encodedData, forKey: String(self.question_?.id ?? 0))
                    userDefaults.synchronize()
                }
                
                self.stopAnimation()
                self.delegate?.update()
                self.performSegue(withIdentifier: Segues.fromQuestionAnswerVC.toFinal, sender: self)
            }
            
        }.resume()
        return
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromQuestionAnswerVC.toFinal {
            let vc = segue.destination as! QuestionFinalVC
            vc.isFromMain_ = isFromMain_
        }
    }
}

final class QuestionAnswerHeader: UICollectionReusableView {
    
    @IBOutlet private weak var question:    UILabel!
    @IBOutlet private weak var title:       UILabel!
    
    fileprivate func display(_ item: QuestionJson, currentQuestion: Int, questionCount: Int) {
        
        question.text = item.question
        title.text = "\(currentQuestion + 1) из \(questionCount)"
    }
    
    class func fromNib() -> QuestionAnswerHeader? {
        var cell: QuestionAnswerHeader?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? QuestionAnswerHeader {
                cell = view
            }
        }
        cell?.question.preferredMaxLayoutWidth = (cell?.frame.size.width ?? 25) - 25
        return cell
    }
}

final class QuestionAnswerCell: UICollectionViewCell {
    
    @IBOutlet private weak var toggle:      OnOffButton!
    @IBOutlet private weak var field:       UITextField!
    @IBOutlet private weak var question:    UILabel!
    @IBOutlet private weak var toggleView:  UIView!
    
    @objc fileprivate func didTapOnOffButton(_ sender: UITapGestureRecognizer? = nil) {
        
        if sender != nil && !isSomeAnswers {
            isAccepted = false
            NotificationCenter.default.post(name: NSNotification.Name("Uncheck"), object: nil)
        }
        
        if !isSomeAnswers {
            if isAccepted && checked { return }
            if !isAccepted { isAccepted = true }
        }
        if checked {
            selectedAnswers.append(index)
            
            if isSomeAnswers {
                toggle.checked = true
                toggle.backgroundColor  = blueColor
                toggle.strokeColor      = .white
            
            } else {
                toggle.strokeColor  = blueColor
                toggleView.isHidden = false
            }
            checked                 = false
            isAccepted              = true
            
        } else {
            
            for (ind, item) in selectedAnswers.enumerated() {
                if item == index {
                    selectedAnswers.remove(at: ind)
                }
            }
            if isSomeAnswers {
                toggle.checked = false
                toggle.strokeColor      = .darkGray
                toggle.backgroundColor  = .white
            
            } else {
                toggle.strokeColor  = .lightGray
                toggleView.isHidden = true
            }
            isAccepted              = false
            checked                 = true
        }
    }
    
    private let blueColor = UIColor(red: 0/255, green: 100/255, blue: 255/255, alpha: 1)
    fileprivate var checked  = false
    private var index = 0
    
    fileprivate func display(_ item: QuestionsTextJson, index: Int) {
        self.index = index
        
        toggle.checked = false
        
        if !isSomeAnswers {
            toggle.strokeColor  = .lightGray
            toggle.lineWidth    = 2
        
        } else {
            toggle.strokeColor = .darkGray
        }
        
        if item.text?.contains(find: "Свой вариант") ?? false {
            display(isSomeAnswer: true)
            return
        }
        
        question.text = item.text
        
        checked = false
        didTapOnOffButton()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnOffButton(_:)))
        toggle.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("Uncheck"), object: nil, queue: nil) { _ in
            self.checked = false
            self.didTapOnOffButton()
        }
    }
    
    fileprivate func display(isSomeAnswer: Bool) {
        question.isHidden = true
        field.isHidden = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapOnOffButton(_:)))
        toggle.addGestureRecognizer(tap)
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillShow(sender: NSNotification?) {
        if checked {
            didTapOnOffButton()
        }
    }
    
    class func fromNib() -> QuestionAnswerCell? {
        var cell: QuestionAnswerCell?
        let views = Bundle.main.loadNibNamed("DynamicCellsNib", owner: nil, options: nil)
        views?.forEach {
            if let view = $0 as? QuestionAnswerCell {
                cell = view
            }
        }
        cell?.question.preferredMaxLayoutWidth = (cell?.contentView.frame.size.width ?? 0.0) - 50
        return cell
    }
}

var isSomeAnswers   = false
var isAccepted      = false
var selectedAnswers: [Int] = []
