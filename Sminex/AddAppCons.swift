//
//  AddAppCons.swift
//  DemoUC
//
//  Created by Роман Тузин on 12.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class AddAppCons: UITableViewController {

    @IBOutlet weak var LS_cell: UITableViewCell!
    @IBOutlet weak var typeCell: UITableViewCell!
    @IBOutlet weak var priorityCell: UITableViewCell!
    @IBOutlet weak var tema: UITextField!
    @IBOutlet weak var textApp: UITextField!
    
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!    
    
    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // Создание заявки
    @IBAction func AddApp(_ sender: UIButton) {
        
    }
    
    let appTypes = ["Бухгалтерия", "Паспортный стол", "Сантехник", "Электрик", "Другие вопросы"]
    let appPriorities = ["а) низкий", "б) средний", "в) высокий", "г) критичный"]
    
    var appLS = -1
    var addLSStr = ""
    var appType = -1
    var appTypeStr = ""
    var appPriority = -1
    var appPriorityStr = ""
    var appTheme = ""
    var appText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        self.StopIndicator()

        LS_cell.detailTextLabel?.text = appLSString()
        typeCell.detailTextLabel?.text = appTypeString()
        priorityCell.detailTextLabel?.text = appPriorityString()
        tema.text = appTheme
        textApp.text = appText
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.tintColor = server.hexStringToUIColor(hex: "#c0c0c0")
        #else
            // Оставим текущуий интерфейс
        #endif
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tema.resignFirstResponder()
        self.textApp.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectTypeCons" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = appTypes
            selectItemController.selectedIndex = appType
            selectItemController.selectHandler = { selectedIndex in
                self.appType = selectedIndex
                self.typeCell.detailTextLabel?.text = self.appTypeString()
            }
        }
        else if segue.identifier == "selectPriorityCons" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = appPriorities
            selectItemController.selectedIndex = appPriority
            selectItemController.selectHandler = { selectedIndex in
                self.appPriority = selectedIndex
                self.priorityCell.detailTextLabel?.text = self.appPriorityString()
            }
        }
    }
    
    func appLSString() -> String {
        if appLS == -1 {
            return "не выбран"
        }
        return ""
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
