//
//  CreateServiceUK.swift
//  Sminex
//
//  Created by Sergey Ivanov on 31/07/2019.
//

import UIKit
import Alamofire
import DeviceKit

class CreateServiceUK: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, HomePlaceCellDelegate {
    
    
    @IBOutlet private weak var loader:      UIActivityIndicatorView!
    @IBOutlet private weak var edConst:     NSLayoutConstraint!
    @IBOutlet private weak var imgsHeight:  NSLayoutConstraint!
//    @IBOutlet private weak var btnConst:    NSLayoutConstraint!
    @IBOutlet private weak var imageConst:  NSLayoutConstraint!
    @IBOutlet private weak var tableHeight: NSLayoutConstraint!
    @IBOutlet private weak var placeHeight: NSLayoutConstraint!
    @IBOutlet private weak var picker:      UIDatePicker!
    @IBOutlet private weak var scroll:      UIScrollView!
    @IBOutlet private weak var images:      UIScrollView!
    @IBOutlet private weak var edProblem:   UITextView!
    @IBOutlet private weak var edPhone:     UITextField!
    @IBOutlet private weak var edEmail:     UITextField!
    @IBOutlet private weak var serviceDesc: UILabel!
    @IBOutlet private weak var servicePrice:UILabel!
    @IBOutlet private weak var servPriceHeight: NSLayoutConstraint!
    @IBOutlet private weak var serviceTitle:UILabel!
    @IBOutlet private weak var serviceIcon: CircleView2!
    @IBOutlet private weak var dateBtn:     UIButton!
    @IBOutlet private weak var sendBtn:     UIButton!
    @IBOutlet private weak var pickerLine:  UILabel!
    @IBOutlet private weak var tableView:   UITableView!
    @IBOutlet private weak var placeView:   UIView!
    @IBOutlet private weak var placeLbl:    UILabel!
    @IBOutlet private weak var plcLbl:      UILabel!
    @IBOutlet private weak var expImg:      UIImageView!
    
    @IBOutlet private weak var timeLine1:   UILabel!
    @IBOutlet private weak var timeLine2:   UILabel!
    @IBOutlet private weak var timeBtn1:    UIButton!
    @IBOutlet private weak var timeBtn2:    UIButton!
    @IBOutlet private weak var timeBtn1Width: NSLayoutConstraint!
    @IBOutlet private weak var timeBtn2Width: NSLayoutConstraint!
    @IBOutlet private weak var dateLbl:     UILabel!
    @IBOutlet private weak var noDateLbl:   UILabel!
    
    
    @IBAction private func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
        viewTapped(nil)
        let action = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in self.navigationController?.popViewController(animated: true) }))
        present(action, animated: true, completion: nil)
    }
    
    var choiceBtn = 1
    var choiceColor = UIColor(red: 210/255, green: 210/255, blue: 210/255, alpha: 1.0)
    var unChoiceColor = UIColor(red: 246/255, green: 249/255, blue: 249/255, alpha: 1.0)
    var placeholderColor = UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
    var extTime = false
    @IBAction private func timeBtn1Action(_ sender: UIButton){
        if choiceBtn == 1{
            choiceBtn = 0
            dateLbl.isHidden = true
            noDateLbl.isHidden = false
            dateBtn.isHidden = true
            extTime = true
            timeBtn2.setTitleColor(mainGrayColor, for: .normal)
            timeLine2.backgroundColor = mainGrayColor
            timeBtn1.setTitleColor(mainGreenColor, for: .normal)
            timeLine1.backgroundColor = mainGreenColor
            if !picker.isHidden{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMMM HH:mm"
                
                dateBtn.setTitle(dateFormatter.string(from: picker.date), for: .normal)
                picker.isHidden         = true
                pickerLine.isHidden     = true
                imageConst.constant = 0
            }
        }
    }
    
    @IBAction private func timeBtn2Action(_ sender: UIButton){
        if choiceBtn == 0{
            choiceBtn = 1
            dateLbl.isHidden = false
            noDateLbl.isHidden = true
            dateBtn.isHidden = false
            extTime = false
            timeBtn2.setTitleColor(mainGreenColor, for: .normal)
            timeLine2.backgroundColor = mainGreenColor
            timeBtn1.setTitleColor(mainGrayColor, for: .normal)
            timeLine1.backgroundColor = mainGrayColor
        }
    }
    
    @IBAction private func dateButtonPressed(_ sender: UIButton?) {
        
        if sender != nil {
            view.endEditing(true)
        }
        if picker.isHidden {
            picker.isHidden     = false
            pickerLine.isHidden = false
            imageConst.constant = 170
            
            if !images.isHidden && isNeedToScrollMore() {
                //                btnConst.constant = 220
                
            } else if images.isHidden && isNeedToScrollMore() {
                //                btnConst.constant = 50
            }
            
        } else {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM HH:mm"
            
            dateBtn.setTitle(dateFormatter.string(from: picker.date), for: .normal)
            picker.isHidden     = true
            pickerLine.isHidden = true
            imageConst.constant = 0
            
            if !images.isHidden && isNeedToScrollMore() {
                //                btnConst.constant = 100
                
            } else if images.isHidden && isNeedToScrollMore() {
                //                btnConst.constant = 50
            }
        }
    }
    var isExpanded = true
    @objc func expand() {
        if !isExpanded {
            self.expImg.image = UIImage(named: "expand")
            isExpanded = true
            showTable = false
            tableView.reloadData()
        } else {
            self.expImg.image = UIImage(named: "expanded")
            isExpanded = false
            showTable = true
            tableView.reloadData()
        }
    }
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM HH:mm"
        dateBtn.setTitle(dateFormatter.string(from: sender.date), for: .normal)
    }
    
    @IBAction private func cameraButtonPressed(_ sender: UIButton) {
        
        if !picker.isHidden {
            dateButtonPressed(nil)
            
        } else {
            view.endEditing(true)
        }
        
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
                imagePicker.sourceType = .camera;
                imagePicker.allowsEditing = false
                self.present(imagePicker, animated: true, completion: nil)
            }
        }))
        action.addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: { (_) in }))
        present(action, animated: true, completion: nil)
    }
    
    @IBAction private func sendButtonPressed(_ sender: UIButton) {
        
        viewTapped(nil)
        //        if picker.date < Date(){
        //            let alert = UIAlertController(title: "Ошибка!", message: "Выберите другую дату", preferredStyle: .alert)
        //            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
        //            alert.addAction(cancelAction)
        //            self.present(alert, animated: true, completion: nil)
        //        }else{
        if picker.date < Date(){
            picker.date = Date()
        }
        if !Server().isValidEmail(testStr: edEmail.text!){
            let alert = UIAlertController(title: "Ошибка!", message: "Введите корректный E-mail", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        startAnimator()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy hh:mm:ss"
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
        data = ServiceAppHeaderData(icon: UIImage(named: "account")!, price: servicePrice.text ?? "", mobileNumber: edPhone.text ?? "", servDesc: serviceDesc.text ?? "", email: edEmail.text ?? "", date: dateFormatter.string(from: picker.date), status: "В ОБРАБОТКЕ", images: imagesArr, imagesUrl: [], desc: edProblem.text!, placeHome: place, soonPossible: extTime, title: data_?.name ?? "", servIcon: serviceIcon.image!, selectPrice: (data_?.selectCost)!, selectPlace: (data_?.selectPlace)!, isReaded: "1")
        uploadRequest()
        //        }
    }
    
    public var delegate: AppsUserDelegate?
    public var type_:     RequestTypeStruct?
    public var data_: ServicesUKJson?
    public var parkingsPlace: [String]?
    var checkPlace: [Bool] = []
    private var data:   ServiceAppHeaderData?
    private var reqId:  String?
    private var constant: CGFloat = 0.0
    private var btnConstant: CGFloat = 0.0
    private var imagesArr: [UIImage] = [] {
        didSet {
            drawImages()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //        constant = btnConst.constant
        btnConstant = sendBtn.frame.origin.y
        //        if isNeedToScrollMore() {
        //            btnConst.constant = 50
        //        }
        if let image = UIImage(data: Data(base64Encoded: ((data_?.picture ?? "").replacingOccurrences(of: "data:image/png;base64,", with: ""))) ?? Data()) {
            serviceIcon.image = image
            serviceIcon.layer.borderColor = UIColor.black.cgColor
            serviceIcon.layer.borderWidth = 1.0
            // Углы
            serviceIcon.layer.cornerRadius = serviceIcon.frame.width / 2
            // Поправим отображения слоя за его границами
            serviceIcon.layer.masksToBounds = true
        }
        let defaults            = UserDefaults.standard
        edEmail.text              = defaults.string(forKey: "mail")
        if (defaults.string(forKey: "mail") == "-") {
            edEmail.text          = ""
        }
        if UserDefaults.standard.string(forKey: "contactNumber") == "-" || UserDefaults.standard.string(forKey: "contactNumber") == "" || UserDefaults.standard.string(forKey: "contactNumber") == " "{
            edPhone.text = ""
        }else{
            edPhone.text = UserDefaults.standard.string(forKey: "contactNumber") ?? ""
        }
        loader.isHidden = true
//        navigationItem.title = data_?.name
        serviceTitle.text = data_?.name
        servicePrice.text  = "Цена услуги: " + (data_?.cost!.replacingOccurrences(of: "руб.", with: "₽"))!
        if data_?.shortDesc == "" || data_?.shortDesc == " "{
            serviceDesc.text  = String((data_?.desc?.prefix(100))!) + "..."
        }else{
            serviceDesc.text  = data_?.shortDesc
        }
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(goService))
        tap2.delegate                    = self
        serviceDesc.isUserInteractionEnabled   = true
        serviceDesc.addGestureRecognizer(tap2)
        
        dateLbl.isHidden = false
        noDateLbl.isHidden = true
        dateBtn.isHidden = false
        self.expImg.image = UIImage(named: "expand")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = true
        placeHeight.constant = 0
        tableHeight.constant = 0
        plcLbl.isHidden = true
        parkingsPlace?.forEach{_ in
            checkPlace.append(false)
        }
        if !(data_?.selectPlace)!{
            placeView.isHidden = true
        }else{
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
        }
        if !(data_?.selectTime)!{
            choiceBtn = 0
            dateLbl.isHidden = true
            noDateLbl.isHidden = false
            dateBtn.isHidden = true
            extTime = true
            timeBtn2.setTitleColor(mainGrayColor, for: .normal)
            timeLine2.backgroundColor = mainGrayColor
            timeBtn1.setTitleColor(mainGreenColor, for: .normal)
            timeLine1.backgroundColor = mainGreenColor
            if !picker.isHidden{
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd MMMM HH:mm"
                
                dateBtn.setTitle(dateFormatter.string(from: picker.date), for: .normal)
                picker.isHidden         = true
                pickerLine.isHidden     = true
                imageConst.constant = 0
            }
            timeBtn2.isHidden = true
            timeLine2.isHidden = true
            timeBtn2Width.constant = 0
            timeBtn1Width.constant = self.view.frame.size.width - 32
        }else{
            timeBtn2.setTitleColor(mainGreenColor, for: .normal)
            timeLine2.backgroundColor = mainGreenColor
            timeBtn1.setTitleColor(mainGrayColor, for: .normal)
            timeLine1.backgroundColor = mainGrayColor
            timeBtn2Width.constant = (self.view.frame.size.width - 32) / 2
            timeBtn1Width.constant = (self.view.frame.size.width - 32) / 2
        }
        if !(data_?.selectCost)!{
            servicePrice.text = ""
            servPriceHeight.constant = 0
        }
        imageConst.constant = 0
        endAnimator()
        automaticallyAdjustsScrollViewInsets = false
        
        tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        
        sendBtn.isEnabled   = false
        sendBtn.alpha       = 0.5
        
        edProblem.delegate = self
        
        // Подхватываем показ клавиатуры
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        //        if !isNeedToScroll() {
        //            btnConst.constant = getConstant()
        //        }
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
        dateBtn.setTitle(dateFormatter.string(from: date!), for: .normal)
        picker.minimumDate = date!
        picker.addTarget(self, action: #selector(
            datePickerValueChanged), for: UIControlEvents.valueChanged)
        edProblem.text = "Введите описание"
        edProblem.textColor = placeholderColor
        edProblem.selectedTextRange = edProblem.textRange(from: edProblem.beginningOfDocument, to: edProblem.beginningOfDocument)
    }
    var tap = UIGestureRecognizer()
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // Двигаем view вверх при показе клавиатуры
    @objc func keyboardWillShow(sender: NSNotification?) {
        if !picker.isHidden {
            dateButtonPressed(nil)
        }
//        self.btnConst.constant = 0
        let info = sender?.userInfo!
        let keyboardSize = (info![UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        if keyboardHeight == 0.0{
//            self.btnConst.constant = (keyboardSize?.height)!
//            scroll.contentSize.height = scroll.contentSize.height + (keyboardSize?.height)!
            keyboardHeight = keyboardSize!.height
            view.frame.origin.y = 0 - keyboardHeight
            scroll.contentInset.top = keyboardHeight
            let desiredOffset = CGPoint(x: 0, y: -scroll.contentInset.top)
            scroll.setContentOffset(desiredOffset, animated: false)
        }else{
//            self.btnConst.constant = (keyboardSize?.height)!
//            scroll.contentSize.height = scroll.contentSize.height - keyboardHeight
//            scroll.contentSize.height = scroll.contentSize.height + (keyboardSize?.height)!
//            keyboardHeight = keyboardSize!.height
            view.frame.origin.y = 0 + keyboardHeight
            scroll.contentInset.top = scroll.contentInset.top - keyboardHeight
            keyboardHeight = keyboardSize!.height
            view.frame.origin.y = 0 - keyboardHeight
            scroll.contentInset.top = keyboardHeight
            let desiredOffset = CGPoint(x: 0, y: -scroll.contentInset.top)
            scroll.setContentOffset(desiredOffset, animated: false)
        }
        view.addGestureRecognizer(tap)
    }
    var keyboardHeight: CGFloat = 0.0
    // И вниз при исчезновении
    @objc func keyboardWillHide(sender: NSNotification?) {
        view.removeGestureRecognizer(tap)
//        scroll.contentSize = CGSize(width: scroll.contentSize.width, height: scroll.contentSize.height - keyboardHeight)
        view.frame.origin.y = 0
        scroll.contentInset.top = 0
        keyboardHeight = 0
//        self.btnConst.constant = 0
//        if Device() == .iPhoneX || Device() == .simulator(.iPhoneX) || Device() == .iPhoneXr || Device() == .simulator(.iPhoneXr) || Device() == .iPhoneXs || Device() == .simulator(.iPhoneXs) || Device() == .iPhoneXsMax || Device() == .simulator(.iPhoneXsMax) {
//            btnConst.constant = 25
//        }
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        view.endEditing(true)
    }
    
    private func drawImages() {
        
        if imagesArr.count == 0 {
            images.isHidden = true
            imageConst.constant = 0
            imgsHeight.constant = 0
            //            if !picker.isHidden && isNeedToScrollMore() {
            //                btnConst.constant = 100
            //
            //            } else if picker.isHidden && isNeedToScrollMore() {
            //                btnConst.constant = 50
            //            }
            
        } else {
            
            //            if !picker.isHidden && isNeedToScrollMore() {
            //                btnConst.constant = 220
            //
            //            } else if picker.isHidden && isNeedToScrollMore() {
            //                btnConst.constant = 50
            //            }
            
            images.isHidden = false
            imgsHeight.constant = 150
            if picker.isHidden {
                imageConst.constant = 0
                
            } else {
                imageConst.constant = 170
            }
            
            images.subviews.forEach {
                $0.removeFromSuperview()
            }
            var x = 0.0
            var tag = 0
            
            imagesArr.forEach {
                let img = UIImageView(frame: CGRect(x: x, y: 0.0, width: 150.0, height: 150.0))
                img.image = $0
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
                tap.delegate = self
                img.isUserInteractionEnabled = true
                img.addGestureRecognizer(tap)
                images.addSubview(img)
                
                let deleteButton = UIButton(frame: CGRect(x: x + 130.0, y: 0.0, width: 20.0, height: 20.0))
                deleteButton.backgroundColor = .white
                deleteButton.cornerRadius = 0.5 * deleteButton.bounds.size.width
                deleteButton.clipsToBounds = true
                deleteButton.tag = tag
                deleteButton.alpha = 0.7
                deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
                images.addSubview(deleteButton)
                
                let image = UIImageView(frame: CGRect(x: x + 135.0, y: 5.0, width: 10.0, height: 10.0))
                image.image = UIImage(named: "rossNavbar")
                images.addSubview(image)
                
                x += 160
                tag += 1
            }
            images.contentSize = CGSize(width: CGFloat(x), height: images.frame.size.height)
        }
    }
    
    @objc private func deleteButtonTapped(_ sender: UIButton) {
        imagesArr.remove(at: sender.tag)
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
        let comm = edProblem.text ?? ""
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
        var soonPossible = ""
        if extTime{
            soonPossible = "1"
        }else{
            soonPossible = "0"
        }
        var paidEmergency = "0"
        if data_?.name == "Дополнительное обслуживание"{
            paidEmergency = "1"
        }
//        print(Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(data_?.id ?? "")&name=\(data_?.name! ?? "")&text=\(comm)&phonenum=\(edPhone.text! )&responsiblePerson=\(data_?.name! ?? "")&emails=\(edEmail.text!)&isPaidEmergencyRequest=\(paidEmergency)&isNotify=1&dateFrom=\(formatDate(Date(), format: "dd.MM.yyyy HH:mm:ss"))&dateTo=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss"))&dateServiceDesired=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss"))&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")))&paidServiceType=\(data_?.id! ?? "")&premises=\(place)&asSoonAsPossible=\(soonPossible)")
        
        let url: String = Server.SERVER + Server.ADD_APP + "login=\(login)&pwd=\(pass)&type=\(data_?.id!.stringByAddingPercentEncodingForRFC3986() ?? "")&name=\(data_?.name!.stringByAddingPercentEncodingForRFC3986()! ?? "")&text=\(comm.stringByAddingPercentEncodingForRFC3986()!)&phonenum=\(edPhone.text!.stringByAddingPercentEncodingForRFC3986() ?? "")&responsiblePerson=\(data_?.name!.stringByAddingPercentEncodingForRFC3986()! ?? "")&emails=\(edEmail.text!.stringByAddingPercentEncodingForRFC3986() ?? "")&isPaidEmergencyRequest=\(paidEmergency.stringByAddingPercentEncodingForRFC3986() ?? "")&isNotify=1&dateFrom=\(formatDate(Date(), format: "dd.MM.yyyy HH:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&dateTo=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&dateServiceDesired=\(formatDate(picker.date, format: "dd.MM.yyyy HH:mm:ss").stringByAddingPercentEncodingForRFC3986() ?? "")&clearAfterWork=&PeriodFrom=\(Date().toString(format: .custom("dd.MM.yyyy HH:mm:ss")).stringByAddingPercentEncodingForRFC3986() ?? "")&paidServiceType=\(data_?.id!.stringByAddingPercentEncodingForRFC3986() ?? "")&premises=\(place.stringByAddingPercentEncodingForRFC3986() ?? "")&asSoonAsPossible=\(soonPossible.stringByAddingPercentEncodingForRFC3986() ?? "")"
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
//        print(request)
        
        URLSession.shared.dataTask(with: request) {
            responce, error, _ in
            
            guard responce != nil else {
                DispatchQueue.main.async {
                    self.endAnimator()
                }
                return
            }
            if (String(data: responce!, encoding: .utf8)?.contains(find: "error"))! {
                DispatchQueue.main.sync {
                    
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
                    
                    self.imagesArr.forEach {
                        self.uploadPhoto($0)
                    }
                    DispatchQueue.main.async {
                        self.delegate?.update()
                    }
                    DispatchQueue.main.sync {
                        
                        self.endAnimator()
                        let viewControllers = self.navigationController?.viewControllers
                        self.navigationController?.popToViewController(viewControllers![viewControllers!.count - 3], animated: true)
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
    
    private func formatDate(_ date: Date, format: String) -> String {
        
        let df = DateFormatter()
        df.dateFormat = format
        return df.string(from: date)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imagesArr.append(image)
        dismiss(animated: true, completion: nil)
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
    
    @objc func goService() {
        view.endEditing(true)
        keyboardHeight = 0
        self.performSegue(withIdentifier: "goService", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCreateTechService.toService {
            let vc = segue.destination as! ServiceAppVC
            vc.isCreated_ = true
            vc.serviceData = data_
            vc.data_ = data ?? ServiceAppHeaderData(icon: UIImage(named: "account")!, price: "", mobileNumber: "", servDesc: "", email: "", date: "", status: "", images: [], imagesUrl: [], desc: "", placeHome: "", soonPossible: false, title: "", servIcon: serviceIcon.image!, selectPrice: true, selectPlace: true, isReaded: "")
            vc.reqId_ = reqId ?? ""
            vc.delegate = delegate
        }
        if segue.identifier == "goService"{
            let vc = segue.destination as! ServicesUKDescVC
            vc.data_ = data_
            var data:[ServicesUKJson] = []
            data.append(data_!)
            vc.allData = data
            vc.index = 0
        }
    }
    
    private func getConstant() -> CGFloat {
        
        if !isXDevice() {
            return (view.frame.size.height - btnConstant) + 50
        } else {
            return (view.frame.size.height - btnConstant)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" && (textView.text as NSString).replacingCharacters(in: range, with: text).components(separatedBy: .newlines).count < 3 {
            edConst.constant += 16
        }
        
        let currentText:String = textView.text
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        
        if updatedText.isEmpty {
            textView.text = "Введите описание"
            textView.textColor = placeholderColor
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            
        } else if textView.textColor == placeholderColor && !text.isEmpty {
            textView.textColor = UIColor.black
            textView.text = text
            
        } else {
            return true
        }
        return false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        if edProblem.text == "" || edProblem.text.count == 1 {
            sendBtn.isEnabled   = false
            sendBtn.alpha       = 0.5
            
        } else {
            sendBtn.isEnabled   = true
            sendBtn.alpha       = 1
        }
        
        if (textView.text as NSString).components(separatedBy: .newlines).count < 3 {
            edConst.constant = textView.contentSize.height
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
    
}
