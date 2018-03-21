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

final class AddAppUser: UITableViewController {
    
    // id аккаунта текущего
    private var authorId = ""
    
    private var responseString    = ""
    private var nameAccount       = ""
    private var idAccount         = ""
    private var idApp             = ""
    
    @IBOutlet private weak var typeCell:      UITableViewCell!
    @IBOutlet private weak var priorityCell:  UITableViewCell!
    @IBOutlet private weak var tema:          UITextField!
    @IBOutlet private weak var textApp:       UITextField!
    
    weak var delegate: AddAppDelegate?
    
    @IBOutlet private weak var btnAdd:    UIButton!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // Создать заявку
    @IBAction func AddApp(_ sender: UIButton) {
        
        self.startIndicator()
        
        let txtLogin = edLogin.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtPass  = edPass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtTema  = tema.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        let txtText  = textApp.text?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed) ?? ""
        
        var itsOk: Bool = true
        if txtTema == "" {
            itsOk = false
        }
        if txtText == "" {
            itsOk = false
        }
        if appType + 1 <= 0 {
            itsOk = false
        }
        if appPriority + 1 <= 0 {
            itsOk = false
        }
        if !itsOk {
            self.stopIndicator()
            var textError: String = "Не заполнены параметры: "
            var firstPar: Bool = true
            if txtTema == "" {
                textError = textError + "тема"
                firstPar = false
            }
            if txtText == "" {
                if firstPar {
                    textError = textError + "текст"
                    firstPar = false
                } else {
                    textError = textError + ", текст"
                }
            }
            if appType + 1 <= 0 {
                if firstPar {
                    textError = textError + "тип"
                    firstPar = false
                } else {
                    textError = textError + ", тип"
                }
            }
            if appPriority + 1 <= 0 {
                if firstPar {
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
            
            var request = URLRequest(url: URL(string: urlPath)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if error != nil {
                    DispatchQueue.main.async {
                        self.stopIndicator()
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    }
                    return
                }
                
                self.responseString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choice()
                
                }.resume()
        }
    }
    
    private var edLogin  = ""
    private var edPass   = ""
    
    private let appTypes      = ["Бухгалтерия", "Паспортный стол", "Сантехник", "Электрик", "Другие вопросы"]
    private let appPriorities = ["а) низкий", "б) средний", "в) высокий", "г) критичный"]
    
    private var appType           = -1
    private var appTypeStr        = ""
    private var appPriority       = -1
    private var appPriorityStr    = ""
    private var appTheme          = ""
    private var appText           = ""
    
    private func choice() {
        DispatchQueue.main.async {
            
            if self.responseString == "1" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не переданы обязательные параметры", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "2" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Неверный логин или пароль", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else if self.responseString == "xxx" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не удалось. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            } else {
                // Все ок - запишем заявку в БД (необходимо получить и записать авт. комментарий в БД
                // Запишем заявку в БД
                let db = DB()
                db.add_app(id: 1, number: self.responseString, text: self.textApp.text!, tema: self.tema.text!, date: self.dateTeck()!, adress: "", flat: "", phone: "", owner: self.nameAccount, is_close: 1, is_read: 1, is_answered: 1)
                db.getComByID(login: self.edLogin, pass: self.edPass, number: self.responseString)
                
                self.stopIndicator()
                
                let alert = UIAlertController(title: "Успешно", message: "Создана заявка №" + self.responseString, preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    if self.delegate != nil {
                        self.delegate?.addAppDone(addApp: self)
                    }
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar = self.navigationController?.navigationBar
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        self.stopIndicator()
        
        let defaults    = UserDefaults.standard
        edLogin         = defaults.string(forKey: "login")!
        edPass          = defaults.string(forKey: "pass")!
        // получим id текущего аккаунта
        authorId        = defaults.string(forKey: "id_account")!
        nameAccount     = defaults.string(forKey: "name")!
        idAccount       = defaults.string(forKey: "id_account")!
        
        typeCell.detailTextLabel?.text      = appTypeString()
        priorityCell.detailTextLabel?.text  = appPriorityString()
        tema.text       = appTheme
        textApp.text    = appText
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tema.resignFirstResponder()
        self.textApp.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func appTypeString() -> String {
        if appType == -1 {
            return "не выбран"
        }
        
        if appType >= 0 && appType < appTypes.count {
            return appTypes[appType]
        }
        
        return ""
    }
    
    private func appPriorityString() -> String {
        if appPriority == -1 {
            return "не выбран"
        }
        
        if appPriority >= 0 && appPriority < appPriorities.count {
            return appPriorities[appPriority]
        }
        
        return ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.fromAddAppUser.toSelectType {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = appTypes
            selectItemController.selectedIndex_ = appType
            selectItemController.selectHandler_ = { selectedIndex in
                self.appType = selectedIndex
                self.typeCell.detailTextLabel?.text = self.appTypeString()
            }
        }
        else if segue.identifier == Segues.fromAddAppUser.toSelectPriority {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = appPriorities
            selectItemController.selectedIndex_ = appPriority
            selectItemController.selectHandler_ = { selectedIndex in
                self.appPriority = selectedIndex
                self.priorityCell.detailTextLabel?.text = self.appPriorityString()
            }
        }
    }
    
    private func startIndicator() {
        self.btnAdd.isEnabled = false
        self.btnAdd.isHidden  = true
        
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator() {
        self.btnAdd.isEnabled = true
        self.btnAdd.isHidden  = false
        
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    private func dateTeck() -> (String)? {
        let dateFormatter           = DateFormatter()
        dateFormatter.dateFormat    = "dd.MM.yyyy HH:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        return dateString
        
    }
}
