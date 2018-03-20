//
//  AddAppCons.swift
//  DemoUC
//
//  Created by Роман Тузин on 12.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

final class AddAppCons: UITableViewController {

    @IBOutlet private weak var LS_cell: UITableViewCell!
    @IBOutlet private weak var typeCell: UITableViewCell!
    @IBOutlet private weak var priorityCell: UITableViewCell!
    @IBOutlet private weak var tema: UITextField!
    @IBOutlet private weak var textApp: UITextField!
    
    @IBOutlet private weak var btnAdd: UIButton!
    @IBOutlet private weak var indicator: UIActivityIndicatorView!
    
    @IBAction private func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // Создание заявки
    @IBAction private func AddApp(_ sender: UIButton) {
        
    }
    
    private let appTypes = ["Бухгалтерия", "Паспортный стол", "Сантехник", "Электрик", "Другие вопросы"]
    private let appPriorities = ["а) низкий", "б) средний", "в) высокий", "г) критичный"]
    
    private var appLS = -1
    private var addLSStr = ""
    private var appType = -1
    private var appTypeStr = ""
    private var appPriority = -1
    private var appPriorityStr = ""
    private var appTheme = ""
    private var appText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        self.stopIndicator()

        LS_cell.detailTextLabel?.text       = appLSString()
        typeCell.detailTextLabel?.text      = appTypeString()
        priorityCell.detailTextLabel?.text  = appPriorityString()
        tema.text    = appTheme
        textApp.text = appText
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tema.resignFirstResponder()
        self.textApp.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectTypeCons" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = appTypes
            selectItemController.selectedIndex_ = appType
            selectItemController.selectHandler_ = { selectedIndex in
                self.appType = selectedIndex
                self.typeCell.detailTextLabel?.text = self.appTypeString()
            }
        }
        else if segue.identifier == "selectPriorityCons" {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = appPriorities
            selectItemController.selectedIndex_ = appPriority
            selectItemController.selectHandler_ = { selectedIndex in
                self.appPriority = selectedIndex
                self.priorityCell.detailTextLabel?.text = self.appPriorityString()
            }
        }
    }
    
    private func appLSString() -> String {
        if appLS == -1 {
            return "не выбран"
        }
        return ""
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
        let dateFormatter        = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
        let dateString           = dateFormatter.string(from: Date())
        return dateString
        
    }

}
