//
//  ServicesUKDescVC.swift
//  Sminex
//
//  Created by IH0kN3m on 5/11/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Gloss

final class ServicesUKDescVC: UIViewController {
    
    @IBOutlet private weak var imgHeight:   NSLayoutConstraint!
    @IBOutlet private weak var titleTop:    NSLayoutConstraint!
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var imgView:     CircleView2!
    @IBOutlet private weak var sendBtn:  UIButton!
    @IBOutlet private weak var titleLabel:  UILabel!
    @IBOutlet private weak var costLabel:   UILabel!
    @IBOutlet private weak var descLabel:   UILabel!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
//        startAnimator()
//        uploadRequest()
        performSegue(withIdentifier: Segues.fromRequestTypeVC.toServiceUK, sender: self)
    }
    
    public var data_: ServicesUKJson?
    public var allData: [ServicesUKJson] = []
    public var index: Int = 0
    
    @IBAction func SwipeRight(_ sender: UISwipeGestureRecognizer) {
        if index > 0{
            index -= 1
            if let image = UIImage(data: Data(base64Encoded: ((allData[index].picture ?? "").replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
                imgView.image = image
            } else {
                imgHeight.constant = 0
                titleTop.constant  = -16
            }
            loader.isHidden = true
            navigationItem.title = allData[index].name
            titleLabel.text = allData[index].name
            costLabel.text  = "Цена услуги: " + allData[index].cost!.replacingOccurrences(of: "руб.", with: "₽")
            descLabel.text  = allData[index].desc
        }
    }
    
    @IBAction func SwipeLeft(_ sender: UISwipeGestureRecognizer) {
        if index < allData.count - 1{
            index += 1
            if let image = UIImage(data: Data(base64Encoded: ((allData[index].picture ?? "").replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
                imgView.image = image
                
            } else {
                imgHeight.constant = 0
                titleTop.constant  = -16
            }
            loader.isHidden = true
            navigationItem.title = allData[index].name
            titleLabel.text = allData[index].name
            costLabel.text  = "Цена услуги: " + allData[index].cost!.replacingOccurrences(of: "руб.", with: "₽")
            descLabel.text  = allData[index].desc
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        let denyCompanyService:Bool = (UserDefaults.standard.value(forKey: "denyCompanyService") as! Bool)
        if let image = UIImage(data: Data(base64Encoded: ((data_?.picture ?? "").replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
            imgView.image = image
            imgView.layer.borderColor = UIColor.black.cgColor
            imgView.layer.borderWidth = 1.0
            // Углы
            imgView.layer.cornerRadius = imgView.frame.width / 2
            // Поправим отображения слоя за его границами
            imgView.layer.masksToBounds = true
        } else {
            imgHeight.constant = 0
            titleTop.constant  = -16
        }
        parkingsPlace = UserDefaults.standard.stringArray(forKey: "parkingsPlace")!
        loader.isHidden = true
        navigationItem.title = data_?.name
        titleLabel.text = data_?.name
        costLabel.text  = "Цена услуги: " + (data_?.cost!.replacingOccurrences(of: "руб.", with: "₽"))!
        descLabel.text  = data_?.desc
        if denyCompanyService{
            sendBtn.alpha     = 0.5
            sendBtn.isEnabled = false
        }else{
            sendBtn.alpha     = 1
            sendBtn.isEnabled = true
        }
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: date)
    }
    
    private func uploadRequest() {
        
        let login = UserDefaults.standard.string(forKey: "login")!
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        let comm = titleLabel.text ?? ""
        
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=bceeab0b-891a-4af8-9953-1bf1ffd7fe29&name=\(comm.stringByAddingPercentEncodingForRFC3986()!)&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)&phonenum=\(UserDefaults.standard.string(forKey: "contactNumber") ?? "")&email=\(UserDefaults.standard.string(forKey: "mail") ?? "")&isPaidEmergencyRequest=&isNotify=1&dateFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986()!)&dateTo=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&paidServiceType=\(allData[index].id!.stringByAddingPercentEncodingForRFC3986() ?? "")"
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        print(request)
        URLSession.shared.dataTask(with: request) {
            responce, error, _ in
            
            guard responce != nil else {
                DispatchQueue.main.async {
                    self.endAnimator()
                }
                return
            }
            #if DEBUG
            print(String(data: responce!, encoding: .utf8)!)
            #endif
            let responseString = String(data: responce!, encoding: .utf8) ?? ""
            let checkInt = self.isStringAnInt(string: responseString)
    
            if checkInt{
                DispatchQueue.main.sync {
                    UserDefaults.standard.set(true, forKey: "backBtn")
                    var title = "Услуга заказана"
                    if (self.allData[self.index].name?.contains(find: "Уборка помещений"))!{
                        title = "Заявка на услугу принята. В ближайшее время сотрудник Службы Комфорта свяжется с Вами для уточнения дополнительных деталей. Спасибо"
                    }
                    let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                        self.endAnimator()
                        self.navigationController?.popViewController(animated: true)
                    }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }else{
                DispatchQueue.main.sync {
                    
                    let alert = UIAlertController(title: "Услуга не заказана", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    self.endAnimator()
                }
                return
                
            }
            }
    .resume()
    }
    
    private var parkingsPlace = [String]()
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromRequestTypeVC.toServiceUK {
            let vc = segue.destination as! CreateServiceUK
//                vc.delegate = delegate as? AppsUserDelegate
            vc.type_ = RequestTypeStruct(id: (allData[index].id)!, name: (allData[index].name)!)
            vc.parkingsPlace = self.parkingsPlace
            vc.data_ = allData[index]
        }
    }
    
    func isStringAnInt(string: String) -> Bool {
        return Int(string) != nil
    }
    
    private func startAnimator() {
        sendBtn.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimator() {
        sendBtn.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
    }
}

@IBDesignable class CircleView2: UIView {
    
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
        imageView.frame = CGRect(x: 5, y: 5, width: 30, height: 30)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    
    func addImage() {
        imageView.image = image
    }
}
