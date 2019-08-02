//
//  CounterChoiceType.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit
import CoreData
import SwiftyXMLParser

class CounterChoiceType: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func historyPressed(_ sender: UIButton) {
        performSegue(withIdentifier: Segues.fromCounterTableVC.toHistory, sender: self)
    }
    
    @IBOutlet weak var tableView:   UITableView!
    @IBOutlet weak var dateLbl:     UILabel!
    @IBOutlet weak var historyBtn:  UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var fetchedResultsController: NSFetchedResultsController<TypesCounters>?
    
    private var meterArr: [MeterValue] = []
    private var periods: [CounterPeriod] = []
    public var canCount = true
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        dateLbl.isHidden = true
        historyBtn.isHidden = true
        self.indicator.startAnimating()
        self.indicator.isHidden = false
        getCounters()
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "TypesCounters", keysForSort: ["name"], predicateFormat: nil) as? NSFetchedResultsController<TypesCounters>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let counter = (fetchedResultsController?.object(at: indexPath))! as TypesCounters
        
        let cell: CounterTypeCell = self.tableView.dequeueReusableCell(withIdentifier: "TypeCounterCell") as! CounterTypeCell
        
        cell.type_name.text = counter.name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "CounterNew", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CounterList") as! CountersTableNew
        let counter = (fetchedResultsController?.object(at: indexPath))! as TypesCounters
        var metArr = meterArr
        metArr.removeAll()
        meterArr.forEach{
            if ($0.resource?.containsIgnoringCase(find: counter.name!))!{
                metArr.append($0)
            }
        }
        vc.canCount = canCount
        vc.data_ = metArr
        vc.period_ = periods
        vc.title = counter.name
        vc.title_name = counter.name

        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func getCounters() {
        
        let login = UserDefaults.standard.string(forKey: "login") ?? ""
        let pass =  UserDefaults.standard.string(forKey: "pwd") ?? ""
        var request = URLRequest(url: URL(string: Server.SERVER + Server.GET_METERS + "login=" + login.stringByAddingPercentEncodingForRFC3986()! + "&pwd=" + pass)!)
        request.httpMethod = "GET"
        
        print(request)
        
        URLSession.shared.dataTask(with: request) {
            data, error, responce in
            guard data != nil else { return }
            if (String(data: data!, encoding: .utf8)?.contains(find: "логин или пароль"))!{
                self.performSegue(withIdentifier: Segues.fromFirstController.toLoginActivity, sender: self)
            }
            if (String(data: data!, encoding: .utf8)?.contains(find: "error"))! {
                let alert = UIAlertController(title: "Ошибка сервера", message: "Попробуйте позже", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            #if DEBUG
//            print("счетчики:", String(data: data!, encoding: .utf8)!)
            #endif
            
            let xml = XML.parse(data!)
            let metersValues = xml["MetersValues"]
            let period = metersValues["Period"].reversed()
            let meterValue = period.first!["MeterValue"]
            
            var newMeters: [MeterValue] = []
            meterValue.forEach {
                newMeters.append( MeterValue($0, period: period.first?.attributes["NumMonth"] ?? "1") )
            }
            
            var newPeriods: [CounterPeriod] = []
            period.forEach {
                newPeriods.append( CounterPeriod($0) )
            }
            self.meterArr = newMeters
            self.periods  = newPeriods
            DispatchQueue.main.async {
                self.dateLbl.text = self.getNameAndMonth(self.periods.first?.numMonth ?? "1") + " " + (self.periods.first?.year ?? "")
                self.tableView.isHidden = false
                self.dateLbl.isHidden = false
                self.historyBtn.isHidden = false
                self.indicator.stopAnimating()
                self.indicator.isHidden = true
            }
            }.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Counters" {
            let vc     = segue.destination as! CountersTableNew
//            vc.data_   = meterArr
//            vc.period_ = periods
        }else if segue.identifier == Segues.fromCounterTableVC.toHistory {
            let vc     = segue.destination as! CounterHistoryTableVC
            vc.data_   = meterArr
            vc.period_ = periods
        }
    }
    
    private func getNameAndMonth(_ number_month: String) -> String {
        
        if number_month == "1" {
            return "Январь"
        } else if number_month == "2" {
            return "Февраль"
        } else if number_month == "3" {
            return "Март"
        } else if number_month == "4" {
            return "Апрель"
        } else if number_month == "5" {
            return "Май"
        } else if number_month == "6" {
            return "Июнь"
        } else if number_month == "7" {
            return "Июль"
        } else if number_month == "8" {
            return "Август"
        } else if number_month == "9" {
            return "Сентябрь"
        } else if number_month == "10" {
            return "Октябрь"
        } else if number_month == "11" {
            return "Ноябрь"
        } else {
            return "Декабрь"
        }
    }

}
