//
//  QuestionAnswerVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/31/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
var currQuestion = 0
var kek: [Int] = []
var i = Int()

final class QuestionAnswerVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var collection:  UICollectionView!
    @IBOutlet private weak var goButton:    UIButton!
    @IBOutlet private weak var btnBotConst: NSLayoutConstraint!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: answers)
        userDefaults.set(encodedData, forKey: String(question_?.id ?? 0))
        userDefaults.synchronize()
        i = 0
        
        if isFromNotifi_ {
            let viewControllers = navigationController?.viewControllers
            navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
            
        } else if !isFromMain_ {
            navigationController?.popViewController(animated: true)
        
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }
    
    @IBAction private func goButtonPressed(_ sender: UIButton) {
        
        // Добавляем опрос в список начатых опросов
        let defaults = UserDefaults.standard
        var array = defaults.array(forKey: "PollsStarted") as? [Int] ?? [Int]()
        if !array.contains(question_!.id!) {
            array.append(question_!.id!)
            defaults.set(array, forKey: "PollsStarted")
        }
        
        var answerArr: [Int] = []

        if question_?.questions![currQuestion].answers?.count != 0{
            selectedAnswers.forEach {
                answerArr.append((question_?.questions![currQuestion].answers![$0].id)!)
            }
            guard answerArr.count != 0 else { return }
        }
        answers[(question_?.questions![currQuestion].id!)!] = answerArr
        print(answers)
        isAccepted = false
        if (currQuestion + 1) < question_?.questions?.count ?? 0 {
            if answers.count > currQuestion + 1{
                kek = answers[(question_?.questions![currQuestion + 1].id!)!]!
            }
            i = 0
            collection.reloadData()
            currQuestion += 1
            NotificationCenter.default.post(name: NSNotification.Name("Uncheck"), object: nil)
        
        } else {
            if question_?.questions![currQuestion].answers?.count == 0 && (recomendationArray.count == 0 || recomendationArray[currQuestion] == ""){
                let alert = UIAlertController(title: "Ошибка", message: "Введите комментарий", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }else{
                startAnimation()
                DispatchQueue.global(qos: .userInteractive).async {
                    self.sendAnswer()
                }
            }
        }
    }
    
    public var isFromMain_ = false
    public var isFromNotifi_ = false
    public var delegate: MainScreenDelegate?
    public var question_: QuestionDataJson?
    public var questionDelegate: QuestionTableDelegate?
    
    private var answers: [Int:[Int]] = [:]
    private var tap: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stopAnimation()
        updateUserInterface()
        navigationItem.title    = question_?.name
        let decoded = UserDefaults.standard.object(forKey: String(question_?.id ?? 0))
        if decoded != nil {
            answers = NSKeyedUnarchiver.unarchiveObject(with: decoded as! Data) as! [Int:[Int]]
        }
//        currQuestion = answers.count
        currQuestion = 0
        print("=")
        print(answers)
        kek = answers[(question_?.questions![currQuestion].id!)!] ?? [0]
        print(kek)
        if kek.count == 1 && kek[0] == 0 {
            goButton.backgroundColor = mainGrayColor
        }else if kek.count > 1 || (kek.count == 1 && kek[0] != 0){
            goButton.backgroundColor = mainGreenColor
        }
        automaticallyAdjustsScrollViewInsets = false
        collection.delegate     = self
        collection.dataSource   = self
        
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped(_:)))
        edgePan.edges = .left
        view.addGestureRecognizer(edgePan)
        
        tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        if !(question_?.isReaded!)!{
            sendRead(groupID: (question_?.id)!)
        }
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
            TemporaryHolder.instance.menuQuesions = TemporaryHolder.instance.menuQuesions - 1
            }.resume()
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
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
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
//        view.frame.origin.y = -125
        if let keyboardSize = (sender?.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            view.frame.origin.y = 0 - keyboardHeight
            collection.contentInset.top = keyboardHeight
        }
    }
    
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.removeGestureRecognizer(tap!)
//        view.frame.origin.y = 0
        view.frame.origin.y = 0
        collection.contentInset.top = 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return question_?.questions![currQuestion].answers?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        isSomeAnswers = (question_?.questions![currQuestion].isAcceptSomeAnswers)!
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionAnswerCell", for: indexPath) as! QuestionAnswerCell
        cell.display((question_?.questions![currQuestion].answers![indexPath.row])!, index: indexPath.row)
//        if view.frame.size.width == 320{
            cell.frame = CGRect(x: cell.frame.origin.x, y: cell.frame.origin.y, width: cell.frame.size.width, height: heightForTitle(text: (question_?.questions![currQuestion].answers![indexPath.row].text)!, width: cell.frame.size.width - 60) + 30)
//        }
        return cell
    }
    
    func heightForTitle(text:String, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
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
        if view.frame.size.width == 320{
            return CGSize(width: view.frame.size.width - 32, height: heightForTitle(text: (question_?.questions![currQuestion].answers![indexPath.row].text)!, width: cell!.frame.size.width - 60) + 30)
        }
        return CGSize(width: view.frame.size.width - 32, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let cell = QuestionAnswerHeader.fromNib()
        cell?.display((question_?.questions![currQuestion])!, currentQuestion: currQuestion, questionCount: question_?.questions?.count ?? 0)
        let size  = cell?.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
        return CGSize(width: view.frame.size.width - 32, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if !isSomeAnswers {
            isAccepted = false
            NotificationCenter.default.post(name: NSNotification.Name("Uncheck"), object: nil)
        }
        goButton.backgroundColor = mainGreenColor
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
        print("=====")
        
        
        var isManyValue = false
        var index = 0
        print(recomendationArray)
        answers.forEach { (arg) in
            let (key, value) = arg
            isManyValue = false
            value.forEach {
//                if isManyValue {
                    json.append( ["QuestionID":key, "AnswerID":$0, "Comment": ""] )
//                } else {
//                    json.append( ["QuestionID":key, "AnswerID":$0, "Comment": recomendationArray[index] ] )
//                }
                
                isManyValue = true
            }
            if value.count == 0{
                json.append( ["QuestionID":key, "AnswerID":0, "Comment": recomendationArray[index] ] )
            }
            index += 1
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        request.httpBody = jsonData
        
        print(request)
        
//        print(String(data: request.httpBody!, encoding: .utf8))
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            
            guard data != nil else { return }
//            print(String(data: data!, encoding: .utf8))
            
            if String(data: data!, encoding: .utf8)?.contains(find: "error") ?? false {
                DispatchQueue.main.async{
                    self.stopAnimation()
                }
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
            
            UserDefaults.standard.removeObject(forKey: String(self.question_?.id ?? 0))
            UserDefaults.standard.synchronize()
            
            // Удаляем из списка начатых опросов
            var array = UserDefaults.standard.array(forKey: "PollsStarted") as? [Int] ?? [Int]()
            if array.contains(self.question_!.id!) {
                 if let index = array.index(where: { (id) -> Bool in
                    id == self.question_!.id!
                 }) {
                    array.remove(at: index)
                }
                UserDefaults.standard.set(array, forKey: "PollsStarted")
            }
            
            DispatchQueue.main.async {
                
                self.stopAnimation()
                self.delegate?.update(method: "Questions")
                if !self.isFromMain_ {
                    self.questionDelegate?.update()
                }
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
        cell?.question.preferredMaxLayoutWidth = cell?.question.bounds.size.width ?? 0.0
        
        return cell
    }
}


final class QuestionAnswerFooter: UICollectionReusableView {
    @IBOutlet weak var textView: UITextView!{
        didSet{
            textView.layer.borderWidth = 1
            textView.layer.borderColor = UIColor.black.cgColor
        }
    }
}

final class QuestionAnswerCell: UICollectionViewCell {
    
    @IBOutlet private weak var toggle:      OnOffButton!
    @IBOutlet private weak var field:       UITextField!
    @IBOutlet private weak var question:    UILabel!
    @IBOutlet private weak var toggleView:  UIView!
    public var question_: QuestionDataJson?
    
    
    
    @objc fileprivate func didTapOnOffButton(_ sender: UITapGestureRecognizer? = nil) {
        
        if sender != nil && !isSomeAnswers {
            isAccepted = false
            NotificationCenter.default.post(name: NSNotification.Name("Uncheck"), object: nil)
        }
        
        if !isSomeAnswers {
            if isAccepted && checked { return }
            if !isAccepted { isAccepted = true }
        }
        
        
        if checked || ((currIndex == index + 1) && (i < kek.count)){
            if (currIndex == index + 1) && (selectedAnswers.count < kek.count){
                i += 1
                selectedAnswers.append(index)
            }
            if checked{
                selectedAnswers.append(index)
            }
//            print(selectedAnswers)
            
            if isSomeAnswers {
                toggle.checked = true
                toggle.backgroundColor  = mainGreenColor
                toggle.strokeColor      = .white
                toggle.lineWidth        = 2
                toggle.setBackgroundImage(nil, for: .normal)
            
            } else {
                toggle.strokeColor  = mainGreenColor
                toggleView.isHidden = false
                toggle.lineWidth    = 2
                toggle.setBackgroundImage(nil, for: .normal)
            }
            checked                 = false
            isAccepted              = true
            currIndex = 0
            
        }else {
            
            for (ind, item) in selectedAnswers.enumerated() {
                if item == index {
                    selectedAnswers.remove(at: ind)
                }
            }
            if isSomeAnswers {
                toggle.checked = false
                toggle.strokeColor      = .darkGray
                toggle.backgroundColor  = .white
                toggle.lineWidth        = 1
                toggle.setBackgroundImage(nil, for: .normal)
            
            } else {
                toggle.strokeColor  = .lightGray
                toggleView.isHidden = true
                toggle.lineWidth    = 0
                toggle.setBackgroundImage(UIImage(named: "ic_choice"), for: .normal)
            }
            isAccepted              = false
            checked                 = true
        }
        if i == kek.count{
            i = 0
        }
    }
    
    private let blueColor = UIColor(red: 0/255, green: 100/255, blue: 255/255, alpha: 1)
    fileprivate var checked  = false
    private var index = 0
    private var currIndex = 0
    
    fileprivate func display(_ item: QuestionsTextJson, index: Int) {
        self.index = index
        
        kek.forEach {
            if item.id == $0{
                currIndex = index + 1
//                print(currIndex)
            }
        }
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
        cell?.question.preferredMaxLayoutWidth = cell?.question.bounds.size.width ?? 0.0
        return cell
    }
}

var isSomeAnswers   = false
var isAccepted      = false
var selectedAnswers: [Int] = []

var recomendationArray: [String] = []


//------------------------------------------------------------------


extension QuestionAnswerVC : UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool  {
        print(textField.text!)
        recomendationArray[currQuestion] = textField.text!
        textField.resignFirstResponder()
        return true
    }
    
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if(text == "\n") {
////            recomendationArray.removeLast()
//            print(textView.text)
//            recomendationArray[currQuestion] = textView.text
//            textView.resignFirstResponder()
//            return false
//        }
//        return true
//    }
//    func textViewDidEndEditing(_ textView: UITextView) {
////        if(textView == "\n") {
////            recomendationArray.removeLast()
//            print(textView.text)
//            recomendationArray[currQuestion] = textView.text
//            textView.resignFirstResponder()
////            return false
////        }
////        return true
//    }
}
