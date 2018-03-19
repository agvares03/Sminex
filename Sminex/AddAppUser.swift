//
//  AddAppUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 07.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

protocol AddAppDelegate : class {
    func addAppDone(addApp: AddAppUser)
}

class AddAppUser: UITableViewController {
    
    var responseString: String = ""
    // id аккаунта текущего
    var id_author: String = ""
    var name_account: String = ""
    var id_account: String = ""
    var id_app: String = ""
    
    @IBOutlet weak var typeCell: UITableViewCell!
    @IBOutlet weak var priorityCell: UITableViewCell!
    @IBOutlet weak var tema: UITextField!
    @IBOutlet weak var textApp: UITextField!
    
    weak var delegate: AddAppDelegate?
    
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // Создать заявку
    @IBAction func AddApp(_ sender: UIButton) {
        
        self.StartIndicator()
        
        let txtLogin: String = edLogin.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtPass: String  = edPass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtTema: String  = tema.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        let txtText: String  = textApp.text!.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
        
        var itsOk: Bool = true
        if (txtTema == "") {
            itsOk = false
        }
        if (txtText == "") {
            itsOk = false
        }
        if ((self.appType + 1) <= 0) {
            itsOk = false
        }
        if ((self.appPriority + 1) <= 0) {
            itsOk = false
        }
        if (!itsOk) {
            self.StopIndicator()
            var textError: String = "Не заполнены параметры: "
            var firstPar: Bool = true
            if (txtTema == "") {
                textError = textError + "тема"
                firstPar = false
            }
            if (txtText == "") {
                if (firstPar) {
                    textError = textError + "текст"
                    firstPar = false
                } else {
                    textError = textError + ", текст"
                }
            }
            if ((self.appType + 1) <= 0) {
                if (firstPar) {
                    textError = textError + "тип"
                    firstPar = false
                } else {
                    textError = textError + ", тип"
                }
            }
            if ((self.appPriority + 1) <= 0) {
                if (firstPar) {
                    textError = textError + "приоритет"
                    firstPar = false
                } else {
                    textError = textError + ", приоритет"
                }
            }
            let alert = UIAlertController(title: "Ошибка", message: textError, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else {
            let urlPath = Server.SERVER + Server.ADD_APP +
                "login=" + txtLogin +
                "&pwd=" + txtPass +
                "&name=" + txtTema +
                "&text=" + txtText +
                "&type=" + String(self.appType + 1) +
                "&priority=" + String(self.appPriority + 1)
            
            let url: NSURL = NSURL(string: urlPath)!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            
            let task = URLSession.shared.dataTask(with: request as URLRequest,
                                                  completionHandler: {
                                                    data, response, error in
                                                    
                                                    if error != nil {
                                                        DispatchQueue.main.async(execute: {
                                                            self.StopIndicator()
                                                            let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                                                            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                                                            alert.addAction(cancelAction)
                                                            self.present(alert, animated: true, completion: nil)
                                                        })
                                                        return
                                                    }
                                                    
                                                    self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                                                    print("responseString = \(self.responseString)")
                                                    
                                                    self.choice()
            })
            task.resume()
        }
    
    }
    
    var edLogin: String = ""
    var edPass: String = ""
    
    let appTypes = ["Бухгалтерия", "Паспортный стол", "Сантехник", "Электрик", "Другие вопросы"]
    let appPriorities = ["а) низкий", "б) средний", "в) высокий", "г) критичный"]
    
    var appType = -1
    var appTypeStr = ""
    var appPriority = -1
    var appPriorityStr = ""
    var appTheme = ""
    var appText = ""

    func choice() {
        if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "2") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Неверный логин или пароль", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "xxx") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else {
            DispatchQueue.main.async(execute: {
                
                // все ок - запишем заявку в БД (необходимо получить и записать авт. комментарий в БД
                // Запишем заявку в БД
                let db = DB()
                db.add_app(id: 1, number: self.responseString, text: self.textApp.text!, tema: self.tema.text!, date: self.date_teck()!, adress: "", flat: "", phone: "", owner: self.name_account, is_close: 1, is_read: 1, is_answered: 1)
                db.getComByID(login: self.edLogin, pass: self.edPass, number: self.responseString)
                
                self.StopIndicator()
                
                let alert = UIAlertController(title: "Успешно", message: "Создана заявка №" + self.responseString, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    if self.delegate != nil {
                        self.delegate?.addAppDone(addApp: self)
                    }
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            })
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue

        self.StopIndicator()
        
        let defaults = UserDefaults.standard
        edLogin = defaults.string(forKey: "login")!
        edPass = defaults.string(forKey: "pass")!
        // получим id текущего аккаунта
        id_author    = defaults.string(forKey: "id_account")!
        name_account = defaults.string(forKey: "name")!
        id_account   = defaults.string(forKey: "id_account")!
        
        typeCell.detailTextLabel?.text = appTypeString()
        priorityCell.detailTextLabel?.text = appPriorityString()
        tema.text = appTheme
        textApp.text = appText
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
        #else
            // Оставим текущуий интерфейс
        #endif
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tema.resignFirstResponder()
        self.textApp.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func appTypeString() -> String {
        if appType == -1 {
            return "не выбран"
        }
        
        if appType >= 0 && appType < appTypes.count {
            return appTypes[appType]
        }
        
        return ""
    }
    
    func appPriorityString() -> String {
        if appPriority == -1 {
            return "не выбран"
        }
        
        if appPriority >= 0 && appPriority < appPriorities.count {
            return appPriorities[appPriority]
        }
        
        return ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectType" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = appTypes
            selectItemController.selectedIndex = appType
            selectItemController.selectHandler = { selectedIndex in
                self.appType = selectedIndex
                self.typeCell.detailTextLabel?.text = self.appTypeString()
            }
        }
        else if segue.identifier == "selectPriority" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = appPriorities
            selectItemController.selectedIndex = appPriority
            selectItemController.selectHandler = { selectedIndex in
                self.appPriority = selectedIndex
                self.priorityCell.detailTextLabel?.text = self.appPriorityString()
            }
        }
    }
    
    func StartIndicator() {
        self.btnAdd.isEnabled = false
        self.btnAdd.isHidden  = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator() {
        self.btnAdd.isEnabled = true
        self.btnAdd.isHidden  = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    func date_teck() -> (String)? {
        let date = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: date as Date)
        return dateString
        
    }

}
