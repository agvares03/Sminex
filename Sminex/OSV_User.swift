//
//  OSV_User.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

class OSV_User: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var fon_app: UIImageView!
    
    var currYear: String = ""
    var currMonth: String = ""
    var iterYear: String = "0"
    var iterMonth: String = "0"
    var minYear: String = ""
    var minMonth: String = ""
    var maxYear: String = ""
    var maxMonth: String = ""
    
    // название месяца для вывода в шапку
    var name_month: String = "";
    
    // Индекс сроки для группировки
    var selectedRow = -5;

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableOSV: UITableView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var rigthButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    var fetchedResultsController: NSFetchedResultsController<Saldo>?
    
    @IBAction func leftButtonDidPress(_ sender: UIButton) {
        
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
        
    }
    
    @IBAction func rightButtonDidPress(_ sender: UIButton) {
        
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
        currYear         = defaults.string(forKey: "year_osv")!
        currMonth        = defaults.string(forKey: "month_osv")!
        
        iterMonth = currMonth
        iterYear = currYear
        
        // Установим значения текущие (если нет данных вообще)
        minMonth = iterMonth
        minYear = iterYear
        maxMonth = iterMonth
        maxYear = iterYear
        
        tableOSV.delegate = self
        
        updateBorderDates()
        updateFetchedResultsController()
        updateMonthLabel()
        updateTable()
        updateArrowsEnabled()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
            leftButton.backgroundColor = server.hexStringToUIColor(hex: "#1f287f")
            rigthButton.backgroundColor = server.hexStringToUIColor(hex: "#1f287f")
            fon_app.image = UIImage(named: "fon_counters_gkrzs.jpg")
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func updateBorderDates() {
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Saldo", keysForSort: ["year"], predicateFormat: nil) as? NSFetchedResultsController<Saldo>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        
        if (fetchedResultsController?.sections?.count)! > 0 {
            if (fetchedResultsController?.sections?.first?.numberOfObjects)! > 0 {
                let leftCounter = fetchedResultsController?.sections?.first?.objects?.first as! Saldo
                let rightCounter = fetchedResultsController?.sections?.first?.objects?.last as! Saldo
                
                minMonth = leftCounter.num_month!
                minYear = leftCounter.year!
                maxMonth = rightCounter.num_month!
                maxYear = rightCounter.year!
            }
        }
    }
    
    func updateFetchedResultsController() {
        let predicateFormat = String(format: "num_month = %@ AND year = %@", iterMonth, iterYear)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsControllerSaldo(entityName: "Saldo", keysForSort: ["usluga"], predicateFormat: predicateFormat) as NSFetchedResultsController<Saldo>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
    }
    
    func updateMonthLabel() {
        monthLabel.text = get_name_month(number_month: iterMonth) + " " + (iterYear == "0" ? "-" : iterYear)
    }
    
    func updateTable() {
        tableOSV.reloadData()
    }
    
    func updateArrowsEnabled() {
        let m = Int(iterMonth)!
        let y = Int(iterYear)!
        let minM = Int(minMonth)!
        let minY = Int(minYear)!
        let maxM = Int(maxMonth)!
        let maxY = Int(maxYear)!
        
        leftButton.isEnabled = !(m <= minM && y <= minY);
        rigthButton.isEnabled = !(m >= maxM && y >= maxY);
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let osv = (fetchedResultsController?.object(at: indexPath))! as Saldo
        let cell = self.tableOSV.dequeueReusableCell(withIdentifier: "Cell") as! OSVCell
        cell.usluga.text = osv.usluga
        cell.start.text  = osv.start
        cell.plus.text   = osv.plus
        cell.minus.text  = osv.minus
        cell.end.text    = osv.end
        
        if (indexPath.row == self.selectedRow) {
            cell.img.image = UIImage(named: "circled_chevron_up")
        } else {
            cell.img.image = UIImage(named: "circled_chevron_down")
        }

        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.row == self.selectedRow) {
            return 168
        }
        return 48
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (selectedRow == -5)   //значит сейчас не выбрана никакая ячейка
        {
            selectedRow = indexPath.row;    //сохранили индекс ячейки
        }
        else if (selectedRow == indexPath.row)    //значит нажали на выбраную ячейку
        {
            selectedRow = -5;    //так мы закроем ее, если это не нужно - этот if можно пропустить
        }
        else
        {
        selectedRow = indexPath.row    //сделали выбранной другую ячейку
        }
        
        tableOSV.reloadData()
        
    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 40
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let headerCell = self.tableOSV.dequeueReusableCell(withIdentifier: "HeaderCell") as! HeaderOSVCell
//        return headerCell
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
