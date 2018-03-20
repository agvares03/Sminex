//
//  OSV_User.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

final class OSV_User: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet private weak var fon_app: UIImageView!
    
    private var currYear    = ""
    private var currMonth   = ""
    private var iterYear    = "0"
    private var iterMonth   = "0"
    private var minYear     = ""
    private var minMonth    = ""
    private var maxYear     = ""
    private var maxMonth    = ""
    
    // название месяца для вывода в шапку
    private var name_month  = "";
    
    // Индекс сроки для группировки
    private var selectedRow = -5;

    @IBOutlet private weak var menuButton:  UIBarButtonItem!
    @IBOutlet private weak var tableOSV:    UITableView!
    @IBOutlet private weak var monthLabel:  UILabel!
    @IBOutlet private weak var rigthButton: UIButton!
    @IBOutlet private weak var leftButton:  UIButton!
    
    private var fetchedResultsController: NSFetchedResultsController<Saldo>?
    
    @IBAction private func leftButtonDidPress(_ sender: UIButton) {
        
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
        
    }
    
    @IBAction private func rightButtonDidPress(_ sender: UIButton) {
        
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
        currYear         = defaults.string(forKey: "year_osv")!
        currMonth        = defaults.string(forKey: "month_osv")!
        
        iterMonth   = currMonth
        iterYear    = currYear
        
        // Установим значения текущие (если нет данных вообще)
        minMonth    = iterMonth
        minYear     = iterYear
        maxMonth    = iterMonth
        maxYear     = iterYear
        
        tableOSV.delegate = self
        
        updateBorderDates()
        updateFetchedResultsController()
        updateMonthLabel()
        updateTable()
        updateArrowsEnabled()
    }
    
    private func updateBorderDates() {
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Saldo", keysForSort: ["year"], predicateFormat: nil) as? NSFetchedResultsController<Saldo>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            
            #if DEBUG
                print(error)
            #endif
        }
        
        if (fetchedResultsController?.sections?.count)! > 0 {
            if (fetchedResultsController?.sections?.first?.numberOfObjects)! > 0 {
                let leftCounter = fetchedResultsController?.sections?.first?.objects?.first as! Saldo
                let rightCounter = fetchedResultsController?.sections?.first?.objects?.last as! Saldo
                
                minMonth = leftCounter.num_month!
                minYear  = leftCounter.year!
                maxMonth = rightCounter.num_month!
                maxYear  = rightCounter.year!
            }
        }
    }
    
    private func updateFetchedResultsController() {
        let predicateFormat      = String(format: "num_month = %@ AND year = %@", iterMonth, iterYear)
        fetchedResultsController = CoreDataManager.instance.fetchedResultsControllerSaldo(entityName: "Saldo", keysForSort: ["usluga"], predicateFormat: predicateFormat) as NSFetchedResultsController<Saldo>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            
            #if DEBUG
                print(error)
            #endif
        }
    }
    
    private func updateMonthLabel() {
        monthLabel.text = getNameMonth(number_month: iterMonth) + " " + (iterYear == "0" ? "-" : iterYear)
    }
    
    private func updateTable() {
        tableOSV.reloadData()
    }
    
    private func updateArrowsEnabled() {
        let m = Int(iterMonth)!
        let y = Int(iterYear)!
        let minM = Int(minMonth)!
        let minY = Int(minYear)!
        let maxM = Int(maxMonth)!
        let maxY = Int(maxYear)!
        
        leftButton.isEnabled  = !(m <= minM && y <= minY);
        rigthButton.isEnabled = !(m >= maxM && y >= maxY);
    }

    private func getNameMonth(number_month: String) -> String {
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
}

// MARK: -CELLS

private final class OSVCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var usluga: UILabel!
    @IBOutlet weak var start: UILabel!
    @IBOutlet weak var plus: UILabel!
    @IBOutlet weak var minus: UILabel!
    @IBOutlet weak var end: UILabel!
    @IBOutlet weak var img: UIImageView!
    
}


private final class OSVCell_Group: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var start_diff: UILabel!
    @IBOutlet weak var plus_diff: UILabel!
    @IBOutlet weak var minus_diff: UILabel!
    @IBOutlet weak var end_diff: UILabel!
    
}

private final class OSVCell_Header_Group: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var usluga: UILabel!
}

private final class HeaderOSVCell: UITableViewCell {}

