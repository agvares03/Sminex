//
//  CountersUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

class CountersUser: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var fon_app: UIImageView!
    
    var Count: Counters? = nil
    
    var edLogin: String = ""
    var edPass: String = ""
    
    var currYear: String = ""
    var currMonth: String = ""
    var date1: String = ""
    var date2: String = ""
    var can_edit: String = ""
    var iterYear: String = "0"
    var iterMonth: String = "0"
    var minYear: String = ""
    var minMonth: String = ""
    var maxYear: String = ""
    var maxMonth: String = ""
    
    var responseString:NSString = ""
    
    // название месяца для вывода в шапку
    var name_month: String = "";
    
    var fetchedResultsController: NSFetchedResultsController<Counters>?

    @IBOutlet weak var tableCounters: UITableView!
    @IBOutlet weak var monthLabel: UILabel!    
    @IBOutlet weak var can_count_label: UILabel!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    // создадим еще параметр - признак, что историю показаний отображать не нужно
    var history_counters: String = ""
    
    @IBAction func leftButtonDidPress(_ sender: Any) {
        var m = Int(iterMonth)!
        var y = Int(iterYear)!
        
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
    
    
    @IBAction func rightButtonDidPress(_ sender: Any) {
        var m = Int(iterMonth)!
        var y = Int(iterYear)!
        
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
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
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
            leftButton.isHidden = true
            rightButton.isHidden = true
        }
        
        iterMonth = currMonth
        iterYear = currYear
        
        // Установим значения текущие (если нет показаний вообще)
        minMonth = iterMonth
        minYear = iterYear
        maxMonth = iterMonth
        maxYear = iterYear
        
        // Установим значения в шапке
        can_count_label.text = "Возможность передавать показания доступна с " + date1 + " по " + date2 + " числа текущего месяца!"
        
        tableCounters.delegate = self
        
        updateBorderDates()
        updateFetchedResultsController()
        updateMonthLabel()
        updateTable()
        updateArrowsEnabled()
        updateEditInfoLabel()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
            leftButton.backgroundColor = server.hexStringToUIColor(hex: "#1f287f")
            rightButton.backgroundColor = server.hexStringToUIColor(hex: "#1f287f")
            fon_app.image = UIImage(named: "fon_counters_gkrzs.jpg")
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func updateBorderDates() {
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Counters", keysForSort: ["year"], predicateFormat: nil)
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        
        if (fetchedResultsController?.sections?.count)! > 0 {
            if (fetchedResultsController?.sections?.first?.numberOfObjects)! > 0 {
                let leftCounter = fetchedResultsController?.sections?.first?.objects?.first as! Counters
                let rightCounter = fetchedResultsController?.sections?.first?.objects?.last as! Counters
                
                minMonth = leftCounter.num_month!
                minYear = leftCounter.year!
                maxMonth = rightCounter.num_month!
                maxYear = rightCounter.year!
            }
        }
    }
    
    func updateFetchedResultsController() {
        let predicateFormat = String(format: "num_month = %@ AND year = %@", iterMonth, iterYear)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Counters", keysForSort: ["count_name"], predicateFormat: predicateFormat)
        
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    func updateArrowsEnabled() {
        let m = Int(iterMonth)!
        let y = Int(iterYear)!
        let minM = Int(minMonth)!
        let minY = Int(minYear)!
        let maxM = Int(maxMonth)!
        let maxY = Int(maxYear)!
        
        leftButton.isEnabled = !(m <= minM && y <= minY);
        rightButton.isEnabled = !(m >= maxM && y >= maxY);
    }
    
    func updateMonthLabel() {
        monthLabel.text = get_name_month(number_month: iterMonth) + " " + iterYear
    }
    
    func updateEditInfoLabel() {
        // Возможно пригодится функция для изменения чего-нибудь еще
    }
    
    func isEditable() -> Bool {
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
            let headerCell = self.tableCounters.dequeueReusableCell(withIdentifier: "HeaderCell") as! HeaderCounterCell
            return headerCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        
        if (isEditable()) {
            let counter = (fetchedResultsController?.object(at: indexPath))! as Counters
            let alert = UIAlertController(title: counter.count_name, message: "Введите текущие показания прибора", preferredStyle: .alert)
            alert.addTextField(configurationHandler: { (textField) in textField.placeholder = "Введите показание..."; textField.keyboardType = .numberPad })
            let cancelAction = UIAlertAction(title: "Отмена", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            let okAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in
                self.send_count(edLogin: self.edLogin, edPass: self.edPass, counter: counter, count: (alert.textFields?[0].text!)!)
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateTable() {
        tableCounters.reloadData()
    }
    
    func get_name_month(number_month: String) -> String {
        var rezult: String = ""
        
        if (number_month == "1") {
            rezult = "Январь"
        } else if (number_month == "2") {
            rezult = "Февраль"
        } else if (number_month == "3") {
            rezult = "Март"
        } else if (number_month == "4") {
            rezult = "Апрель"
        } else if (number_month == "5") {
            rezult = "Май"
        } else if (number_month == "6") {
            rezult = "Июнь"
        } else if (number_month == "7") {
            rezult = "Июль"
        } else if (number_month == "8") {
            rezult = "Август"
        } else if (number_month == "9") {
            rezult = "Сентябрь"
        } else if (number_month == "10") {
            rezult = "Октябрь"
        } else if (number_month == "11") {
            rezult = "Ноябрь"
        } else if (number_month == "12") {
            rezult = "Декабрь"
        }
        
        return rezult
    }
    
    // Передача показаний
    func send_count(edLogin: String, edPass: String, counter: Counters, count: String) {
        if (count != "") {
            StartIndicator()
            
            let strNumber: String = counter.uniq_num!
            
            let urlPath = Server.SERVER + Server.ADD_METER
                + "login=" + edLogin.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
                + "&pwd=" + edPass.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
                + "&meterID=" + strNumber.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
                + "&val=" + count.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlPathAllowed)!
            
            let url: NSURL = NSURL(string: urlPath)!
            let request = NSMutableURLRequest(url: url as URL)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request as URLRequest,
                                                  completionHandler: {
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
                                                    
                                                    self.responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!
                                                    print("responseString = \(self.responseString)")
                                                    
                                                    self.choice(counter: counter, prev: counter.prev_value, teck: Float(count)!)
                                                    
            })
            
            task.resume()
            
        }
    }
    
    func choice(counter: Counters, prev: Float, teck: Float) {
        if (responseString == "0") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Переданы не все параметры. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "1") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не пройдена авторизация. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "2") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Не найден прибор у пользователя. Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "3") {
            DispatchQueue.main.async(execute: {
                self.StopIndicator()
                let alert = UIAlertController(title: "Ошибка", message: "Передача показаний невозможна.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            })
        } else if (responseString == "5") {
            DispatchQueue.main.async(execute: {
                // Успешно - обновим значения в БД
                counter.value = teck
                counter.diff = teck - prev
                counter.prev_value = teck - (teck - prev)
                CoreDataManager.instance.saveContext()
                
                self.StopIndicator()
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
            })
        }
    }
    
    func StartIndicator(){
        self.indicator.startAnimating()
        self.indicator.isHidden = false
    }
    
    func StopIndicator(){
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
