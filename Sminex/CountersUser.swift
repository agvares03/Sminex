//
//  CountersUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

final class CountersUser: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet private weak var fon_app: UIImageView!
    
    private var Count: Counters?
    
    private var edLogin = ""
    private var edPass  = ""
    
    private var currYear    = ""
    private var currMonth   = ""
    private var date1       = ""
    private var date2       = ""
    private var can_edit    = ""
    private var iterYear    = "0"
    private var iterMonth   = "0"
    private var minYear     = ""
    private var minMonth    = ""
    private var maxYear     = ""
    private var maxMonth    = ""
    
    private var responseString = ""
    
    // название месяца для вывода в шапку
    private var name_month  = "";
    
    private var fetchedResultsController: NSFetchedResultsController<Counters>?

    @IBOutlet private weak var tableCounters:   UITableView!
    @IBOutlet private weak var monthLabel:      UILabel!
    @IBOutlet private weak var can_count_label: UILabel!
    @IBOutlet private weak var menuButton:      UIBarButtonItem!
    @IBOutlet private weak var leftButton:      UIButton!
    @IBOutlet private weak var rightButton:     UIButton!
    @IBOutlet private weak var indicator:       UIActivityIndicatorView!
    
    // создадим еще параметр - признак, что историю показаний отображать не нужно
    private var history_counters = ""
    
    @IBAction private func leftButtonDidPress(_ sender: Any) {
        var m = Int(iterMonth) ?? 0
        var y = Int(iterYear) ?? 0
        
        if m > 1 {
            m = m - 1
        }
        else {
            m = 12
            y = y - 1
        }
        
        iterMonth = String(m)
        iterYear = String(y)
        
        updateFetchedResultsController()
        updateMonthLabel()
        updateTable()
        updateArrowsEnabled()
        updateEditInfoLabel()
    }
    
    
    @IBAction private func rightButtonDidPress(_ sender: Any) {
        var m = Int(iterMonth) ?? 0
        var y = Int(iterYear) ?? 0
        
        if m < 12 {
            m = m + 1
        }
        else {
            m = 1
            y = y + 1
        }
        
        iterMonth = String(m)
        iterYear = String(y)
        
        updateFetchedResultsController()
        updateMonthLabel()
        updateTable()
        updateArrowsEnabled()
        updateEditInfoLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        // Получим данные из глобальных сохраненных
        let defaults     = UserDefaults.standard
        edLogin          = defaults.string(forKey: "login")!
        edPass           = defaults.string(forKey: "pass")!
        currYear         = defaults.string(forKey: "year")!
        currMonth        = defaults.string(forKey: "month")!
        date1            = defaults.string(forKey: "date1")!
        date2            = defaults.string(forKey: "date2")!
        can_edit         = defaults.string(forKey: "can_count")!
        
        // Необходимо ли отображать историю показаний
        history_counters = defaults.string(forKey: "history_counters")!
        if (history_counters == "0") {
            leftButton.isHidden  = true
            rightButton.isHidden = true
        }
        
        iterMonth = currMonth
        iterYear  = currYear
        
        // Установим значения текущие (если нет показаний вообще)
        minMonth = iterMonth
        minYear  = iterYear
        maxMonth = iterMonth
        maxYear  = iterYear
        
        // Установим значения в шапке
        can_count_label.text = "Возможность передавать показания доступна с " + date1 + " по " + date2 + " числа текущего месяца!"
        
        tableCounters.delegate = self
        
        updateBorderDates()
        updateFetchedResultsController()
        updateMonthLabel()
        updateTable()
        updateArrowsEnabled()
        updateEditInfoLabel()
        
    }
    
    private func updateBorderDates() {
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Counters", keysForSort: ["year"], predicateFormat: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            
            #if DEBUG
            print(error)
            #endif
        }
        
        if (fetchedResultsController?.sections?.count)! > 0 {
            if (fetchedResultsController?.sections?.first?.numberOfObjects)! > 0 {
                let leftCounter = fetchedResultsController?.sections?.first?.objects?.first as! Counters
                let rightCounter = fetchedResultsController?.sections?.first?.objects?.last as! Counters
                
                minMonth = leftCounter.num_month!
                minYear  = leftCounter.year!
                maxMonth = rightCounter.num_month!
                maxYear  = rightCounter.year!
            }
        }
    }
    
    private func updateFetchedResultsController() {
        let predicateFormat      = String(format: "num_month = %@ AND year = %@", iterMonth, iterYear)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Counters", keysForSort: ["count_name"], predicateFormat: predicateFormat)
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            
            #if DEBUG
            print(error)
            #endif
        }
    }
    
    private func updateArrowsEnabled() {
        let m = Int(iterMonth)!
        let y = Int(iterYear)!
        let minM = Int(minMonth)!
        let minY = Int(minYear)!
        let maxM = Int(maxMonth)!
        let maxY = Int(maxYear)!
        
        leftButton.isEnabled  = !(m <= minM && y <= minY);
        rightButton.isEnabled = !(m >= maxM && y >= maxY);
    }
    
    private func updateMonthLabel() {
        monthLabel.text = getNameAndMonth(number_month: iterMonth) + " " + iterYear
    }
    
    private func updateEditInfoLabel() {
        // Возможно пригодится функция для изменения чего-нибудь еще
    }
    
    private func isEditable() -> Bool {
        return iterYear == currYear && iterMonth == currMonth && can_edit == "1"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let counter = (fetchedResultsController?.object(at: indexPath))! as Counters
        self.Count = counter
        if (self.history_counters == "0") {
            let cell = self.tableCounters.dequeueReusableCell(withIdentifier: "Cell_no_history") as! CounterCell_no_history
            cell.name_counter.text = counter.count_name
            cell.teck.text = counter.value.description
            cell.delegate = self
            return cell
        } else {
            let cell = self.tableCounters.dequeueReusableCell(withIdentifier: "Cell") as! CounterCell
            cell.name_counter.text = counter.count_name
            cell.pred.text = counter.prev_value.description
            cell.teck.text = counter.value.description
            cell.count_txt.text = counter.diff.description
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if (self.history_counters == "0") {
            let headerCell = self.tableCounters.dequeueReusableCell(withIdentifier: "HeaderCell_no_history") as! HeaderCounterCEll_no_history
            return headerCell
        } else {
            let headerCell = self.tableCounters.dequeueReusableCell(withIdentifier: "HeaderCell") as? HeaderCounterCell
            return headerCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if isEditable() {
            let counter = (fetchedResultsController?.object(at: indexPath))! as Counters
            let alert = UIAlertController(title: counter.count_name, message: "Введите текущие показания прибора", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in textField.placeholder = "Введите показание..."; textField.keyboardType = .numberPad })
            let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            let okAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                self.sendCount(edLogin: self.edLogin, edPass: self.edPass, counter: counter, count: (alert.textFields?[0].text!)!)
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func updateTable() {
        tableCounters.reloadData()
    }
    
    private func getNameAndMonth(number_month: String) -> String {
        var result: String = ""
        
        if number_month == "1" {
            result = "Январь"
        } else if number_month == "2" {
            result = "Февраль"
        } else if number_month == "3" {
            result = "Март"
        } else if number_month == "4" {
            result = "Апрель"
        } else if number_month == "5" {
            result = "Май"
        } else if number_month == "6" {
            result = "Июнь"
        } else if number_month == "7" {
            result = "Июль"
        } else if number_month == "8" {
            result = "Август"
        } else if number_month == "9" {
            result = "Сентябрь"
        } else if number_month == "10" {
            result = "Октябрь"
        } else if number_month == "11" {
            result = "Ноябрь"
        } else if number_month == "12" {
            result = "Декабрь"
        }
        
        return result
    }
    
    // Передача показаний
    private func sendCount(edLogin: String, edPass: String, counter: Counters, count: String) {
        if count != "" {
            startIndicator()
            
            let strNumber = counter.uniq_num!
            
            let urlPath = Server.SERVER + Server.ADD_METER
                + "login=" + edLogin.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
                + "&pwd=" + edPass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
                + "&meterID=" + strNumber.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
                + "&val=" + count.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            var request = URLRequest(url: URL(string: urlPath)!)
            request.httpMethod = "GET"
            
            URLSession.shared.dataTask(with: request) {
                data, response, error in
                
                if error != nil {
                    DispatchQueue.main.async(execute: {
                        let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                        let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                        alert.addAction(cancelAction)
                        self.present(alert, animated: true, completion: nil)
                    })
                    return
                }
                
                self.responseString = String(data: data!, encoding: .utf8) ?? ""
                
                #if DEBUG
                    print("responseString = \(self.responseString)")
                #endif
                
                self.choice(counter: counter, prev: counter.prev_value, teck: Float(count)!)
                
                }.resume()
        }
    }
    
    private func choice(counter: Counters, prev: Float, teck: Float) {
        DispatchQueue.main.async {
        
        if self.responseString == "0" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Переданы не все параметры. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "1" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не пройдена авторизация. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "2" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не найден прибор у пользователя. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "3" {
                self.stopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Передача показаний невозможна.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            
        } else if self.responseString == "5" {
                // Успешно - обновим значения в БД
                counter.value = teck
                counter.diff = teck - prev
                counter.prev_value = teck - (teck - prev)
                CoreDataManager.instance.saveContext()
                
                self.stopIndicator()
                let alert = UIAlertController(title: "Успешно", message: "Показания переданы", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                    self.updateBorderDates()
                    self.updateFetchedResultsController()
                    self.updateMonthLabel()
                    self.updateTable()
                    self.updateArrowsEnabled()
                    self.updateEditInfoLabel()
                    
                }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    private func startIndicator(){
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    private func stopIndicator(){
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
}

// MARK: -CEllS

private final class CounterCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var name_counter:    UILabel!
    @IBOutlet weak var pred:            UILabel!
    @IBOutlet weak var teck:            UILabel!
    @IBOutlet weak var count_txt:       UILabel!
    
}

private final class CounterCell_no_history: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var name_counter:    UILabel!
    @IBOutlet weak var teck:            UILabel!
    
}

private final class HeaderCounterCell:              UITableViewCell {}
private final class HeaderCounterCEll_no_history:   UITableViewCell {}
