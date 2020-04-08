//
//  CreateRequestVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/24/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit
import Alamofire
import DeviceKit
import AKMaskField

final class CreateRequestVC: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, HomePlaceCellDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var isTransport: NSLayoutConstraint!
    @IBOutlet weak var transportTitle: UILabel!
    @IBOutlet private weak var loader:          UIActivityIndicatorView!
    @IBOutlet private weak var imageConst:      NSLayoutConstraint!
    @IBOutlet weak var commentConst: NSLayoutConstraint!
    @IBOutlet private weak var transportConst:    NSLayoutConstraint!
//    @IBOutlet weak var sendViewConst: NSLayoutConstraint!
    @IBOutlet weak var edConst: NSLayoutConstraint!
    @IBOutlet weak var FioConst: NSLayoutConstraint!
    @IBOutlet private weak var scroll:          UIScrollView!
    @IBOutlet private weak var imgScroll:       UIScrollView!
    @IBOutlet private weak var picker:          UIDatePicker!
    @IBOutlet private weak var edFio:           UITextView!
    @IBOutlet weak var edContact:       AKMaskField!
    @IBOutlet private weak var gosNumber:       UITextView!
    @IBOutlet private weak var markAuto:        UITextView!
    @IBOutlet private weak var edComment:       UITextView!
    @IBOutlet private weak var dateField:       UIButton!
    @IBOutlet private weak var sendButton:      UIButton!
    @IBOutlet private weak var transportSwitch: UISwitch!
    @IBOutlet private weak var gosLine:         UILabel!
    @IBOutlet private weak var markLine:        UILabel!
    @IBOutlet private weak var pickerLine:      UILabel!
    @IBOutlet private weak var descInfoLbl:     UILabel!
    @IBOutlet private weak var descInfoView:    UIView!
    @IBOutlet weak var sendBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var heigthFooter: NSLayoutConstraint!
    @IBOutlet weak var phone_service: UILabel!
    @IBOutlet weak var img_phone_service: UIImageView!
    @IBOutlet weak var dopInfoHeight: NSLayoutConstraint!
    @IBOutlet weak var heigth_phone_service: NSLayoutConstraint!
    
    @IBOutlet private weak var tableView:   UITableView!
    @IBOutlet private weak var placeView:   UIView!
    @IBOutlet private weak var placeLbl:    UILabel!
    @IBOutlet private weak var plcLbl:      UILabel!
    @IBOutlet private weak var expImg:      UIImageView!
    @IBOutlet private weak var tableHeight: NSLayoutConstraint!
    @IBOutlet private weak var placeHeight: NSLayoutConstraint!
    @IBOutlet private weak var notifiBtn: UIBarButtonItem!
    @IBAction private func goNotifi(_ sender: UIBarButtonItem) {
        if !notifiPressed{
            notifiPressed = true
            performSegue(withIdentifier: "goNotifi", sender: self)
        }
    }
    var notifiPressed = false
    @IBAction private func closeButtonPressed(_ sender: UIBarButtonItem) {
        
        let action = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in self.navigationController?.popViewController(animated: true) }))
        present(action, animated: true, completion: nil)
        
    }
    
    @IBAction private func datePickerPressed(_ sender: UIButton?) {
        if sender != nil {
            viewTapped(nil)
        }
        
        if picker.isHidden {
            
            if !imgScroll.isHidden {
                //imageConst.constant     = 180
            }
            picker.isHidden         = false
            pickerLine.isHidden     = false
            imageConst.constant = 150
//            if transportSwitch.isOn{
//                sendBtnTop.constant = 5
//            }else{
//                if sendBtnTop.constant > 150{
//                    sendBtnTop.constant = sendBtnTop.constant - 150
//                }else{
//                    sendBtnTop.constant = 5
//                }
//            }
        } else {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM HH:mm"
            
            dateField.setTitle(dateFormatter.string(from: picker.date), for: .normal)
            picker.isHidden         = true
            pickerLine.isHidden     = true
            
            if !imgScroll.isHidden {
//                sendBtnConst.constant   = 15
//
//            } else {
//                sendBtnConst.constant   = 170
                //imageConst.constant     = 5
            }
            imageConst.constant = 0
            if transportSwitch.isOn{
                changeFooter()
            }else{
//                sendBtnTop.constant = sendBtnTopConstant
            }
        }
    }
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM HH:mm"
        dateField.setTitle(dateFormatter.string(from: sender.date), for: .normal)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        viewTapped(nil)
        if (edFio.text == "" || edFio.text == "ФИО гостей") && edContact.text == ""{
            if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && gosNumber.textColor == placeholderColor && markAuto.textColor == placeholderColor{
                let alert = UIAlertController(title: "Ошибка!", message: "Заполните поля: ФИО, Контактный номер, Марка автомобиля и Госномер", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }else if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && gosNumber.textColor == placeholderColor{
                let alert = UIAlertController(title: "Ошибка!", message: "Заполните поля: ФИО, Контактный номер и Госномер", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }else if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && markAuto.textColor == placeholderColor{
                let alert = UIAlertController(title: "Ошибка!", message: "Заполните поля: ФИО, Контактный номер и Госномер", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }else if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && gosNumber.textColor != placeholderColor && markAuto.textColor != placeholderColor{
                let alert = UIAlertController(title: "Ошибка!", message: "Заполните поля: ФИО и Контактный номер", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }else{
                let alert = UIAlertController(title: "Ошибка!", message: "Заполните поля: ФИО и Контактный номер", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }else if (edFio.text == "" || edFio.text == "ФИО гостей") {
            let alert = UIAlertController(title: "Ошибка!", message: "Заполните поле: ФИО", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else if edContact.text == "" {
            let alert = UIAlertController(title: "Ошибка!", message: "Заполните поле: Контактный номер", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && gosNumber.textColor == placeholderColor && markAuto.textColor == placeholderColor{
            let alert = UIAlertController(title: "Ошибка!", message: "Заполните поля: Госномер и Марка автомобиля", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            //        }else if picker.date < Date(){
            //            let alert = UIAlertController(title: "Ошибка!", message: "Дата пропуска должна быть не меньше текущей", preferredStyle: .alert)
            //            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            //            alert.addAction(cancelAction)
            //            self.present(alert, animated: true, completion: nil)
        } else if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && gosNumber.textColor == placeholderColor{
            let alert = UIAlertController(title: "Ошибка!", message: "Заполните поле: Госномер", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
//        }else if picker.date < Date(){
//            let alert = UIAlertController(title: "Ошибка!", message: "Дата пропуска должна быть не меньше текущей", preferredStyle: .alert)
//            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
//            alert.addAction(cancelAction)
//            self.present(alert, animated: true, completion: nil)
        } else if (!(UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle")) || transportSwitch.isOn == true) && markAuto.textColor == placeholderColor{
            let alert = UIAlertController(title: "Ошибка!", message: "Заполните поле: Марка автомобиля", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            //        }else if picker.date < Date(){
            //            let alert = UIAlertController(title: "Ошибка!", message: "Дата пропуска должна быть не меньше текущей", preferredStyle: .alert)
            //            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            //            alert.addAction(cancelAction)
            //            self.present(alert, animated: true, completion: nil)
        }else{
            if picker.date < Date(){
                picker.date = Date()
            }
            startAnimator()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
            if transportSwitch.isOn == false{
                gosNumber.text = ""
                markAuto.text = ""
            }
            var gos = ""
            var mark = ""
            if gosNumber.textColor != placeholderColor{
                gos = gosNumber.text
            }
            if markAuto.textColor != placeholderColor{
                mark = markAuto.text
            }
            var place = placeLbl.text ?? ""
            if place == "Выбрать помещение(я)"{
                place = ""
                if checkPlace.count != 0{
                    var i = 0
                    checkPlace.forEach{
                        if $0 == false{
                            i += 1
                        }
                    }
                    if i == checkPlace.count{
                        parkingsPlace!.forEach{
                            place = place + $0 + ";"
                        }
                    }
                    if place.last == ";"{
                        place.removeLast()
                    }
                }
            }else{
                if place.contains(find: "; "){
                    let str = place.components(separatedBy: "; ")
                    place = ""
                    str.forEach{
                        place = place + $0 + ";"
                    }
                    if place.last == ";"{
                        place.removeLast()
                    }
                }
            }
            if edComment.text == "Примечание" && edComment.textColor == placeholderColor{
                data = AdmissionHeaderData(icon: UIImage(named: "account")!,
                                           gosti: edFio.text!,
                                           mobileNumber: edContact.text!,
                                           gosNumber: gos , mark: mark ,
                                           date: dateFormatter.string(from: picker.date),
                                           status: "В ОБРАБОТКЕ",
                                           images: images,
                                           imagesUrl: [], desc: "", placeHome: place, isReaded: "1")
            }else{
                data = AdmissionHeaderData(icon: UIImage(named: "account")!,
                                           gosti: edFio.text!,
                                           mobileNumber: edContact.text!,
                                           gosNumber: gos , mark: mark ,
                                           date: dateFormatter.string(from: picker.date),
                                           status: "В ОБРАБОТКЕ",
                                           images: images,
                                           imagesUrl: [], desc: edComment.text!, placeHome: place, isReaded: "1")
            }
            
            uploadRequest()
        }
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        viewTapped(nil)
        let action = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        action.addAction(UIAlertAction(title: "Выбрать из галереи", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .photoLibrary;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Сделать фото", style: .default, handler: { (_) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    private var images: [UIImage] = [] {
        didSet {
            drawImages()
        }
    }
    var placeholderColor = UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
    public var name_ = ""
    public var delegate: AppsUserDelegate?
    public var type_: RequestTypeStruct?
    private var reqId: String?
    private var data: AdmissionHeaderData?
    private var btnConstant: CGFloat = 0.0
    private var sprtTopConst: CGFloat = 0.0
    private var show = false
    public var parkingsPlace: [String]?
    var checkPlace: [Bool] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserInterface()
        scroll.isHidden = true
        edContact.maskExpression = "+7 ({ddd}) {ddd}-{dddd}"
        edContact.maskTemplate = "*"
        self.expImg.image = UIImage(named: "expand")
        tableView.delegate = self
        tableView.dataSource = self
        placeHeight.constant = 0
        tableHeight.constant = 0
        plcLbl.isHidden = true
        parkingsPlace?.forEach{_ in
            checkPlace.append(false)
        }
        if parkingsPlace!.count == 1{
            placeHeight.constant = 20
            placeView.backgroundColor = .white
            plcLbl.isHidden = false
            placeLbl.text = parkingsPlace![0]
            expImg.isHidden = true
        }else{
            let tap1 = UITapGestureRecognizer(target: self, action: #selector(expand))
            placeView.addGestureRecognizer(tap1)
        }
//        if  Device() == .iPhone4 || Device() == .simulator(.iPhone4) ||
//            Device() == .iPhone4s || Device() == .simulator(.iPhone4s) ||
//            Device() == .iPhone5 || Device() == .simulator(.iPhone5) ||
//            Device() == .iPhone5c || Device() == .simulator(.iPhone5c) ||
//            Device() == .iPhone5s || Device() == .simulator(.iPhone5s) ||
//            Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE){
//            edConst.constant -= 22
//        } else if Device() == .iPhone6 || Device() == .simulator(.iPhone6) ||
//            Device() == .iPhone6s || Device() == .simulator(.iPhone6s) ||
//            Device() == .iPhone7 || Device() == .simulator(.iPhone7) ||
//            Device() == .iPhone8 || Device() == .simulator(.iPhone8){
//            edConst.constant -= 22
//        }else if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) ||
//            Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) ||
//            Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) ||
//            Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
//            edConst.constant += 16
//        } else if Device() == .iPhoneX || Device() == .simulator(.iPhoneX) {
//            edConst.constant += 16
//        }
        edConst.constant = 30
        sprtTopConst = pickerLine.frame.origin.y
        btnConstant = sendButton.frame.origin.y
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        sendBtnHeight.constant = 0
        sendButton.isHidden = true
        gosNumber.isHidden      = true
        gosLine.isHidden        = true
        markAuto.isHidden       = true
        markLine.isHidden       = true
        edFio.delegate      = self
        gosNumber.delegate  = self
        markAuto.delegate  = self
        edComment.delegate  = self
        imageConst.constant = 0
        title = "Пропуск"
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        transportSwitch.addTarget(self, action: #selector(stateChanged(_:)), for: .valueChanged)
        if UserDefaults.standard.string(forKey: "contactNumber") == "-" || UserDefaults.standard.string(forKey: "contactNumber") == "" || UserDefaults.standard.string(forKey: "contactNumber") == " "{
            edContact.text = ""
        }else{
            var phone = UserDefaults.standard.string(forKey: "contactNumber") ?? ""
            if phone.first == "8" && phone.count > 10{
                phone.removeFirst()
            }else if phone.first == "+" && phone.count > 10{
                phone = phone.replacingOccurrences(of: "+7", with: "")
            }
            edContact.text = phone
        }
        
        let defaults = UserDefaults.standard
        if (defaults.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) {
            // Уберем автомобиль из пропуска
            isTransport.constant = 8
            transportSwitch.isHidden = true
            transportTitle.isHidden = true
            transportConst.constant = 0
        }else if !(defaults.bool(forKey: "denyIssuanceOfPassSingleWithAuto")) && (defaults.bool(forKey: "denyIssuanceOfPassSingle")){
            transportConst.constant = 53
            transportSwitch.isOn = true
            transportSwitch.isUserInteractionEnabled = false
            commentConst.constant   = 120
            gosNumber.isHidden      = false
            gosLine.isHidden        = false
            markAuto.isHidden       = false
            markLine.isHidden       = false
//            sendViewConst.constant = sendViewConst.constant - 57
        }
        
        edComment.text = "Примечание"
        edFio.text = "ФИО гостей"
        gosNumber.textColor = placeholderColor
        gosNumber.selectedTextRange = gosNumber.textRange(from: gosNumber.beginningOfDocument, to: gosNumber.beginningOfDocument)
        markAuto.textColor = placeholderColor
        markAuto.selectedTextRange = markAuto.textRange(from: markAuto.beginningOfDocument, to: markAuto.beginningOfDocument)
        edComment.textColor = placeholderColor
        edComment.selectedTextRange = edComment.textRange(from: edComment.beginningOfDocument, to: edComment.beginningOfDocument)
        edFio.textColor = placeholderColor
        edFio.selectedTextRange = edFio.textRange(from: edFio.beginningOfDocument, to: edFio.beginningOfDocument)
        heigthFooter.constant = 0
        heigth_phone_service.constant = 0
        dopInfoHeight.constant = 0
        descInfoLbl.isHidden = true
        descInfoView.isHidden = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM HH:mm"
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        let hour = calendar.component(.hour, from: Date()) + 1
        let minute = calendar.component(.minute, from: Date())
        let second = calendar.component(.second, from: Date())
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second)
        let date = calendar.date(from: components)
        dateField.setTitle(dateFormatter.string(from: date!), for: .normal)
        picker.minimumDate = date!
        let tap_phone = UITapGestureRecognizer(target: self, action: #selector(phonePressed(_:)))
        img_phone_service.isUserInteractionEnabled   = true
        img_phone_service.addGestureRecognizer(tap_phone)
//        let scrollSize = scroll.contentSize
//        if scrollSize.height < view.frame.size.height{
//            scroll.contentSize = CGSize(width: scroll.frame.size.width, height: view.frame.size.height)
//        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(true)
        if scroll.contentSize.height < UIScreen.main.bounds.height{
//            sendBtnTop.constant = UIScreen.main.bounds.height - scroll.contentSize.height - 60
            sendBtnTopConstant = UIScreen.main.bounds.height - scroll.contentSize.height - 60
            if Device() == .iPhoneX || Device() == .simulator(.iPhoneX) || Device() == .iPhoneXr || Device() == .simulator(.iPhoneXr) || Device() == .iPhoneXs || Device() == .simulator(.iPhoneXs) || Device() == .iPhoneXsMax || Device() == .simulator(.iPhoneXsMax) {
//                sendBtnTop.constant = UIScreen.main.bounds.height - scroll.contentSize.height - 110
                sendBtnTopConstant = UIScreen.main.bounds.height - scroll.contentSize.height - 110
            }
        }
        scroll.isHidden = false
    }
    var sendBtnTopConstant = CGFloat()
    var tap = UIGestureRecognizer()
    var isExpanded = true
    var expandHeigth = CGFloat()
    @objc func expand() {
        if !isExpanded {
            self.expImg.image = UIImage(named: "expand")
            isExpanded = true
            showTable = false
            tableView.reloadData()
//            DispatchQueue.main.async{
//                if self.transportSwitch.isOn{
//                    self.sendBtnTop.constant = 5
//                }else{
//                    if self.keyboardHeight != 0{
//                        self.sendBtnTop.constant = self.expandHeigth
//                    }else{
//                        self.sendBtnTop.constant = self.sendBtnTop.constant + self.tableH
//                    }
//                }
//            }
        } else {
            self.expImg.image = UIImage(named: "expanded")
            isExpanded = false
            showTable = true
            tableView.reloadData()
            DispatchQueue.main.async{
                if self.parkingsPlace!.count <= 4{
                    self.tableH = CGFloat(44 * self.parkingsPlace!.count)
                }else{
                    self.tableH = 44 * 4
                }
//                if self.transportSwitch.isOn{
//                    self.sendBtnTop.constant = 5
//                }else{
//                    if self.keyboardHeight != 0{
//                        self.expandHeigth = self.sendBtnTop.constant
//                        self.sendBtnTop.constant = 5
//                    }else{
//                        self.sendBtnTop.constant = self.sendBtnTop.constant - self.tableH
//                    }
//                }
            }
        }
    }
    var tableH = CGFloat()
    @objc private func phonePressed(_ sender: UITapGestureRecognizer) {
        let newPhone = phone_service.text?.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        if let url = URL(string: "tel://" + newPhone!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.updateUserInterface()
//                self.viewDidLoad()
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
//        edFio.becomeFirstResponder()
//        sendBtnConst.constant = getPoint()
//        sendViewConst.constant = getPoint() - 60
        tabBarController?.tabBar.isHidden = true
        picker.addTarget(self, action: #selector(
            datePickerValueChanged), for: UIControlEvents.valueChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
        tabBarController?.tabBar.isHidden = false
    }
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        let info = sender?.userInfo!
        keyboardHeight = ((info![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height)!
        view.frame.origin.y = 0 - keyboardHeight
        scroll.contentInset.top = keyboardHeight
        view.addGestureRecognizer(tap)
        let desiredOffset = CGPoint(x: 0, y: -scroll.contentInset.top)
        scroll.setContentOffset(desiredOffset, animated: false)
//        if transportSwitch.isOn{
//            sendBtnTop.constant = 5
//        }else if isExpanded == false{
//            self.sendBtnTop.constant = 5
//        }else{
//            sendBtnTop.constant = sendBtnTop.constant - keyboardHeight
//            if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE){
//                sendBtnTop.constant = 5
//            }
//        }
    }
    var keyboardHeight = CGFloat()
    // И вниз при исчезновении
    var keyboardShow = true
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.removeGestureRecognizer(tap)
        view.frame.origin.y = 0
        scroll.contentInset.top = 0
        keyboardHeight = 0
        changeFooter()
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
//        if !picker.isHidden {
//            datePickerPressed(nil)
//        }
    }
    
    private func getPoint() -> CGFloat {
        var k:CGFloat = 0
        if (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto")){
            k = 51
        }
        if Device() == .iPhone7Plus || Device() == .simulator(.iPhone7Plus) ||
            Device() == .iPhone8Plus || Device() == .simulator(.iPhone8Plus) ||
            Device() == .iPhone6Plus || Device() == .simulator(.iPhone6Plus) ||
            Device() == .iPhone6sPlus || Device() == .simulator(.iPhone6sPlus){
            return (view.frame.size.height - sprtTopConst + 60) - 35 + k
        } else if Device() == .iPhoneX || Device() == .simulator(.iPhoneX){
            return (view.frame.size.height - sprtTopConst + 45) - 70 + k
        } else {
            return (view.frame.size.height - sprtTopConst + 60) + k
        }
    }
    
    @objc private func stateChanged(_ sender: UISwitch) {
        
        if sender.isOn{
            commentConst.constant   = 120
            gosNumber.isHidden      = false
            gosLine.isHidden        = false
            markAuto.isHidden       = false
            markLine.isHidden       = false
//            sendBtnConst.constant = sendBtnConst.constant - 55
//            sendViewConst.constant = sendViewConst.constant - 57
            
            // Увеличим подвал для показа информации (Если это необходимо)
            changeFooter()
        
        } else {
            commentConst.constant   = 8
            gosNumber.isHidden      = true
            gosLine.isHidden        = true
            markAuto.isHidden       = true
            markLine.isHidden       = true
//            sendBtnConst.constant = sendBtnConst.constant + 55
//            sendViewConst.constant = sendViewConst.constant + 57
            
            // Уменьшим подвал для показа информации
//            heigthFooter.constant = 59
            descInfoLbl.isHidden = true
            descInfoView.isHidden = true
            heigth_phone_service.constant = 0
            dopInfoHeight.constant = 0
//            if keyboardHeight != 0{
//                sendBtnTop.constant = sendBtnTopConstant - keyboardHeight
//                if Device() == .iPhoneSE || Device() == .simulator(.iPhoneSE){
//                    sendBtnTop.constant = 5
//                }
//            }else{
//                if isExpanded == true{
//                    sendBtnTop.constant = sendBtnTopConstant
//                }else{
//                    sendBtnTop.constant = sendBtnTopConstant - tableH
//                }
//            }
        }
    }
    
    func changeFooter() {
        if (self.transportSwitch.isOn) {
            if !(UserDefaults.standard.bool(forKey: "denyImportExportPropertyRequest")) {
//                heigthFooter.constant = 160
                self.descInfoLbl.isHidden = false
                let data_: [ContactsJson] = TemporaryHolder.instance.contactsList
                var phone: String = ""
                for data in data_ {
                    if (data.name?.contains(find: "Консьерж"))! {
                        phone = data.phone ?? "";
                    }
                }
                self.dopInfoHeight.constant = heightForView(text: "Вниманию арендаторов помещений! В случае планируемого вывоза имущества Вам необходимо получить подтверждение владельца помещения на вывоз.", font: self.descInfoLbl.font, width: self.view.frame.size.width - 16)
                if (phone != "") {
                    
//                    heigthFooter.constant = 270
                    self.descInfoView.isHidden = false
                    self.heigth_phone_service.constant = 110
                    self.phone_service.text = phone
                } else {
//                    heigthFooter.constant = 160
                    self.heigth_phone_service.constant = 0
                }
//                if keyboardHeight != 0{
//                    self.sendBtnTop.constant = 5
//                }else{
//                    if Device() == .iPhoneX || Device() == .simulator(.iPhoneX) || Device() == .iPhoneXr || Device() == .simulator(.iPhoneXr) || Device() == .iPhoneXs || Device() == .simulator(.iPhoneXs) || Device() == .iPhoneXsMax || Device() == .simulator(.iPhoneXsMax){
//                        self.sendBtnTop.constant = sendBtnTopConstant - 110 - self.heigth_phone_service.constant - self.dopInfoHeight.constant
//                    }else{
//                        self.sendBtnTop.constant = 5
//                    }
//                }
            } else {
                self.descInfoLbl.isHidden = true
                self.descInfoView.isHidden = true
                self.heigth_phone_service.constant = 0
                self.dopInfoHeight.constant = 0
            }
        } else {
            self.descInfoLbl.isHidden = true
            self.descInfoView.isHidden = true
            self.heigth_phone_service.constant = 0
            self.dopInfoHeight.constant = 0
//            if isExpanded == true{
//                if self.scroll.contentSize.height < self.view.frame.size.height{
//                    self.sendBtnTop.constant = sendBtnTopConstant
//                }else{
//                    self.sendBtnTop.constant = 5
//                }
//            }else{
//                sendBtnTop.constant = sendBtnTopConstant - tableH
//            }
        }
    }
    
    private func drawImages() {
        
        if images.count == 0 {
            imgScroll.isHidden = true
            heigthFooter.constant = 0
            if !picker.isHidden {
                imageConst.constant = 8
//                sendBtnConst.constant = 350
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.contentSize.height - 350)
                
            } else {
//                sendBtnConst.constant = 8
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.contentSize.height - 170)
            }

        } else {
            imgScroll.isHidden = false
            heigthFooter.constant = 150
            if !picker.isHidden {
                imageConst.constant = 180
//                sendBtnConst.constant = 350
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.contentSize.height + 350)
            
            } else {
//                sendBtnConst.constant = 170
                scroll.contentSize = CGSize(width: scroll.frame.size.width, height: scroll.contentSize.height + 170)
            }
            
            imgScroll.subviews.forEach {
                $0.removeFromSuperview()
            }
            var x = 0.0
            var tag = 0
            
            images.forEach {
                let img = UIImageView(frame: CGRect(x: x, y: 0.0, width: 150.0, height: 150.0))
                img.image = $0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                tap.delegate = self
                img.isUserInteractionEnabled = true
                img.addGestureRecognizer(tap)
                imgScroll.addSubview(img)
                
                let deleteButton = UIButton(frame: CGRect(x: x + 130.0, y: 0.0, width: 20.0, height: 20.0))
                deleteButton.backgroundColor = .white
                deleteButton.cornerRadius = 0.5 * deleteButton.bounds.size.width
                deleteButton.clipsToBounds = true
                deleteButton.tag = tag
                deleteButton.alpha = 0.7
                deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
                imgScroll.addSubview(deleteButton)
                
                let image = UIImageView(frame: CGRect(x: x + 135.0, y: 5.0, width: 10.0, height: 10.0))
                image.image = UIImage(named: "rossNavbar")
                imgScroll.addSubview(image)
                
                x += 160
                tag += 1
            }
            imgScroll.contentSize = CGSize(width: CGFloat(x), height: imgScroll.frame.size.height)
        }
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        images.remove(at: sender.tag)
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        
        let imageView = sender.view as! UIImageView
        let newImageView = UIImageView(image: imageView.image)
        newImageView.frame = UIScreen.main.bounds
        newImageView.backgroundColor = .black
        newImageView.contentMode = .scaleAspectFit
        newImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage(_:)))
        newImageView.addGestureRecognizer(tap)
        self.view.addSubview(newImageView)
        self.navigationController?.isNavigationBarHidden = true
        self.tabBarController?.tabBar.isHidden = true
    }
    
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        self.navigationController?.isNavigationBarHidden = false
        sender.view?.removeFromSuperview()
    }
    
    private func uploadRequest() {
        
        let login = UserDefaults.standard.string(forKey: "login")!
        let pass = UserDefaults.standard.string(forKey: "pwd") ?? ""
        var comm = edComment.text ?? ""
        if edComment.textColor == placeholderColor{
            comm = ""
        }
        var place = placeLbl.text ?? ""
        if place == "Выбрать помещение(я)"{
            place = ""
            if checkPlace.count != 0{
                var i = 0
                checkPlace.forEach{
                    if $0 == false{
                        i += 1
                    }
                }
                if i == checkPlace.count{
                    parkingsPlace!.forEach{
                        place = place + $0 + ";"
                    }
                }
                if place.last == ";"{
                    place.removeLast()
                }
            }
        }else{
            if place.contains(find: "; "){
                let str = place.components(separatedBy: "; ")
                place = ""
                str.forEach{
                    place = place + $0 + ";"
                }
                if place.last == ";"{
                    place.removeLast()
                }
            }
        }
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(type_?.id?.stringByAddingPercentEncodingForRFC3986() ?? "")&name=\("\(name_) \(formatDate(Date(), format: "dd.MM.yyyy HH:mm:ss"))".stringByAddingPercentEncodingForRFC3986() ?? "")&text=\(comm.stringByAddingPercentEncodingForRFC3986() ?? "")&phonenum=\(edContact.text!.stringByAddingPercentEncodingForRFC3986() ?? "")&email=\(UserDefaults.standard.string(forKey: "mail") ?? "")&isPaidEmergencyRequest=0&isNotify=1&dateFrom=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&dateTo=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&clearAfterWork=&PhoneForFeedBack=\(String(describing: data!.mobileNumber).stringByAddingPercentEncodingForRFC3986() ?? "")&ResponsiblePerson=\(UserDefaults.standard.string(forKey: "name")?.stringByAddingPercentEncodingForRFC3986() ?? "")&premises=\(place.stringByAddingPercentEncodingForRFC3986() ?? "")"
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        
        var requestBody: [String:[Any]] = ["persons":[], "autos":[]]
        let personsArr = edFio.text?.split(separator: ",")
        let autosArr = gosNumber.text?.split(separator: ",")
        let mark = markAuto.text?.split(separator: ",")
        personsArr?.forEach {
            requestBody["persons"]?.append(["FIO":$0, "PassportData":""])
        }
        var i = 0
        if transportSwitch.isOn == true && gosNumber.textColor != placeholderColor && markAuto.textColor != placeholderColor{
            autosArr?.forEach {
                if mark!.count == 0{
                    requestBody["autos"]?.append(["Mark":"", "Color":"", "Number":$0, "Parking":""])
                }else if i < mark!.count{
                    requestBody["autos"]?.append(["Mark":mark?[i], "Color":"", "Number":$0, "Parking":""])
                }else{
                    requestBody["autos"]?.append(["Mark":mark?.last!, "Color":"", "Number":$0, "Parking":""])
                }
                i += 1
            }
        }
        
        if let json = try? JSONSerialization.data(withJSONObject: requestBody, options: .prettyPrinted) {
            request.httpBody = Data(json)
        }
        
        URLSession.shared.dataTask(with: request) {
            responce, error, _ in
            
            guard responce != nil else {
                DispatchQueue.main.async {
                    self.endAnimator()
                }
                return
            }
            if (String(data: responce!, encoding: .utf8)?.contains(find: "error"))! {
                DispatchQueue.main.async {
                    
                    let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                    
                }
                return
            } else {
                #if DEBUG
                print(String(data: responce!, encoding: .utf8)!)
                #endif
                self.reqId = String(data: responce!, encoding: .utf8)
                DispatchQueue.global(qos: .userInteractive).async {
                    
                    self.images.forEach {
                        self.uploadPhoto($0)
                    }
                    DispatchQueue.main.sync {
                        
                        self.endAnimator()
                        self.delegate?.update()
                        self.performSegue(withIdentifier: Segues.fromCreateRequest.toAdmission, sender: self)
                    }
                }
            }
        }.resume()
    }
    
    private func uploadPhoto(_ img: UIImage) {
        
        let group = DispatchGroup()
        let reqID = reqId?.stringByAddingPercentEncodingForRFC3986()
        let id = UserDefaults.standard.string(forKey: "id_account")!.stringByAddingPercentEncodingForRFC3986()
        
        group.enter()
        let uid = UUID().uuidString
        Alamofire.upload(multipartFormData: { multipartFromdata in
            multipartFromdata.append(UIImageJPEGRepresentation(img, 0.5)!, withName: uid, fileName: "+skip\(uid).jpg", mimeType: "image/jpeg")
        }, to: Server.SERVER + Server.ADD_FILE + "reqID=" + reqID! + "&accID=" + id!) { (result) in
            
            switch result {
            case .success(let upload, _, _):
                
                upload.uploadProgress(closure: { (progress) in
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                
                upload.responseJSON { response in
                    print(response.result.value!)
                    group.leave()
                    
                }
                
            case .failure(let encodingError):
                print(encodingError)
            }
        }
        group.wait()
        return
    }
    
    private func startAnimator() {
        sendButton.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    private func endAnimator() {
        sendButton.isHidden = false
        loader.stopAnimating()
        loader.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCreateRequest.toAdmission {
            let vc = segue.destination as! AdmissionVC
            vc.isCreated_ = true
            vc.data_ = data ?? AdmissionHeaderData(icon: UIImage(), gosti: "", mobileNumber: "", gosNumber: "", mark: "", date: "", status: "", images: [], imagesUrl: [], desc: "", placeHome: "", isReaded: "")
            vc.reqId_ = reqId ?? ""
            vc.delegate = delegate
            vc.name_ = name_
        }
    }
    
    private func formatDate(_ date: Date, format: String) -> String {
        
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: date)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        images.append(image)
        dismiss(animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        if textField === edFio {
            edContact.becomeFirstResponder()

        } else if textField === edContact {
            if !gosNumber.isHidden {
                gosNumber.becomeFirstResponder()

            } else {
                edComment.becomeFirstResponder()
            }

        } else if textField === gosNumber {
            edComment.becomeFirstResponder()
        }

        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto") == false && UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle") == true){
            sendBtnHeight.constant = 0
            sendButton.isHidden = true
        
        }else  if (edFio.textColor == placeholderColor || edContact.textColor == placeholderColor){
            sendBtnHeight.constant = 0
            sendButton.isHidden = true
            
        }else {
            sendBtnHeight.constant = 48
            sendButton.isHidden = false
        }
        
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        if textView == gosNumber{
            if updatedText.isEmpty {
                textView.text = "Госномер (или номера через запятую, например, А 033 ЕО 77)"
                sendBtnHeight.constant = 0
                sendButton.isHidden = true
                textView.textColor = placeholderColor
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
                
            } else if textView.textColor == placeholderColor && !text.isEmpty {
                textView.textColor = UIColor.black
                textView.text = text
                sendBtnHeight.constant = 48
                sendButton.isHidden = false
                
            } else {
                return true
            }
        }else if textView == markAuto{
            if updatedText.isEmpty {
                textView.text = "Марка автомобиля \n(или марки через запятую)"
                sendBtnHeight.constant = 0
                sendButton.isHidden = true
                textView.textColor = placeholderColor
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
                
            } else if textView.textColor == placeholderColor && !text.isEmpty {
                textView.textColor = UIColor.black
                textView.text = text
                sendBtnHeight.constant = 48
                sendButton.isHidden = false
                
            } else {
                return true
            }
        }else{
            if (UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingleWithAuto") == false && UserDefaults.standard.bool(forKey: "denyIssuanceOfPassSingle") == true){
                if updatedText.isEmpty {
                    textView.text = "Примечание"
                    if textView.frame.origin.y < 100{
                        textView.text = "ФИО гостей"
                        sendBtnHeight.constant = 0
                        sendButton.isHidden = true
                    }
                    textView.textColor = placeholderColor
                    textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
                    
                } else if textView.textColor == placeholderColor && !text.isEmpty {
                    textView.textColor = UIColor.black
                    textView.text = text
                    if textView.frame.origin.y < 100 && gosNumber.text != ""{
                        sendBtnHeight.constant = 48
                        sendButton.isHidden = false
                    }
                    
                } else {
                    return true
                }
            }else {
                if updatedText.isEmpty {
                    textView.text = "Примечание"
                    if textView.frame.origin.y < 100{
                        textView.text = "ФИО гостей"
                        sendBtnHeight.constant = 0
                        sendButton.isHidden = true
                    }
                    textView.textColor = placeholderColor
                    textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
                    
                } else if textView.textColor == placeholderColor && !text.isEmpty {
                    textView.textColor = UIColor.black
                    textView.text = text
                    if textView.frame.origin.y < 100{
                        sendBtnHeight.constant = 48
                        sendButton.isHidden = false
                    }
                    
                } else {
                    return true
                }
            }
        }
        
        return false
    }
    var previousValue = CGRect.zero
    var lines = 1
    func textViewDidChange(_ textView: UITextView) {
        if textView != gosNumber && textView != markAuto{
            let pos = textView.endOfDocument
            let currentRect = textView.caretRect(for: pos)
            if (currentRect.origin.y > previousValue.origin.y){
                lines += 1
            }else if (currentRect.origin.y < previousValue.origin.y){
                lines -= 1
            }
            
            if (textView.text as NSString).components(separatedBy: .newlines).count < 4 && lines < 4 && textView.frame.origin.y < 100 {
                var height = textView.contentSize.height
                if height == 57 && self.show == false{
                    self.show = true
                }else if (currentRect.origin.y > previousValue.origin.y) && self.show == true{
                    height -= 20
                    self.show = true
                }
                if height == 37{
                    self.show = false
                }
                if height < 40{
                    self.FioConst.constant = 40
                }else{
                    self.FioConst.constant = height
                }
            }
            previousValue = currentRect
        }
        
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == placeholderColor {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
    
    var showTable = false
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        DispatchQueue.main.async {
            if self.showTable{
                if self.parkingsPlace!.count <= 4{
                    self.tableHeight.constant = CGFloat(44 * self.parkingsPlace!.count)
                }else{
                    self.tableHeight.constant = 44 * 4
                }
            }else{
                self.tableHeight.constant = 0
            }
        }
        return self.parkingsPlace!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HomePlaceCell", for: indexPath) as! HomePlaceCell
        cell.display(item: parkingsPlace![indexPath.row], isChecked: checkPlace[indexPath.row], delegate: self)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !checkPlace[indexPath.row] == true{
            placeCheck(text: parkingsPlace![indexPath.row], del: false)
        }else {
            placeCheck(text: parkingsPlace![indexPath.row], del: true)
        }
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func placeCheck(text: String, del: Bool) {
        var str = placeLbl.text
        if del{
            str = str?.replacingOccurrences(of: text, with: "")
            placeLbl.text = str!
            if str?.last == " "{
                str?.removeLast()
                str?.removeLast()
                placeLbl.text = str!
            }
            if str?.first == ","{
                str?.removeFirst()
                str?.removeFirst()
                placeLbl.text = str!
            }
            if placeLbl.text == "" || placeLbl.text == " "{
                placeHeight.constant = 0
                plcLbl.isHidden = true
                placeLbl.text = "Выбрать помещение(я)"
            }
            for i in 0...parkingsPlace!.count - 1{
                if parkingsPlace![i] == text{
                    checkPlace[i] = false
                }
            }
        }else{
            placeHeight.constant = 20
            plcLbl.isHidden = false
            if str == "Выбрать помещение(я)"{
                placeLbl.text = text
            }else{
                placeLbl.text = str! + ", " + text
            }
            for i in 0...parkingsPlace!.count - 1{
                if parkingsPlace![i] == text{
                    checkPlace[i] = true
                }
            }
        }
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        
        return label.frame.height
    }
}
