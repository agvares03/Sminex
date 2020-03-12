//
//  CountersTableNew.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit
import CoreData

protocol NewCounterDelegate: class {
    func pressed(index: Int)
}

class CountersTableNew: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CounterStatementDelegate, NewCounterDelegate {
    func update() {
        print("")
    }
    
    
    
    var title_name: String?
    public var data_: [MeterValue] = []
    public var period_: [CounterPeriod]? = []
    public var canCount: Bool?
    
    @IBOutlet weak var collView:    UICollectionView!
    
    var fetchedResultsController: NSFetchedResultsController<Counters>?
    
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let dateFrom = UserDefaults.standard.integer(forKey: "meterReadingsDayFrom")
//        let dateTo = UserDefaults.standard.integer(forKey: "meterReadingsDayTo")
//        let calendar = Calendar.current
//        let curDay = calendar.component(.day, from: Date())
//        if curDay > dateTo || curDay < dateFrom || UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
//            canCount = false
//        }else{
//            canCount = true
//        }
        if UserDefaults.standard.bool(forKey: "onlyViewMeterReadings"){
            canCount = false
        }else{
            canCount = true
        }
        collView.delegate = self
        collView.dataSource = self
        
//        let predicate = NSPredicate(format: "owner == %@ AND num_month == %@ AND year == %@", title_name ?? "", UserDefaults.standard.string(forKey: "month") ?? "", UserDefaults.standard.string(forKey: "year") ?? "")
//        fetchedResultsController?.fetchRequest.predicate = predicate
//        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Counters", keysForSort: ["owner"], predicateFormat: nil) as? NSFetchedResultsController<Counters>
//        do {
//            try fetchedResultsController?.performFetch()
//        } catch {
//            print(error)
//        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("DATA: ", data_)
        collView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if data_.count != 0{
            return data_.count
        }else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CounterCellNew", for: indexPath) as! CounterCellNew
        cell.display(data_[indexPath.row], delegate: self, index: indexPath.row, delegate2: self, date: period_![0].lastModf!, canCount: canCount!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        index = indexPath.row
//
//        if canCount {
//            performSegue(withIdentifier: Segues.fromCounterTableVC.toStatement, sender: self)
//        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cell = CounterCellNew.fromNib()
        cell?.display(data_[indexPath.row], delegate: self, index: indexPath.row, delegate2: self, date: period_![0].lastModf!, canCount: canCount!)
        let size = cell?.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize) ?? CGSize(width: 0, height: 0)
        return CGSize(width: view.frame.size.width - 32, height: size.height)
    }

    var index = 0
    func pressed(index: Int) {
        self.index = index

        if canCount! {
            performSegue(withIdentifier: Segues.fromCounterTableVC.toStatement, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromCounterTableVC.toStatement {
            let date = (period_![0].periodDate ?? "").split(separator: ".")
            
            let vc = segue.destination as! CounterStatementVCNew
            vc.value_   = data_[index]
            vc.period_ = period_
            vc.kolTarif = data_[index].typeTarif ?? ""
//            vc.kolTarif = "2"
            //            vc.month_   = getNameAndMonth(periods.last?.numMonth ?? "1")
            vc.month_   = getNameAndMonth(period_![0].numMonth ?? "1")
            vc.year_    = period_![0].year ?? ""
            vc.date_    = date[0] + " "
            vc.date_ = vc.date_! + getNameAndMonth(period_![0].numMonth ?? "1") + " " + (period_![0].year ?? "")
            vc.delegate = self
            
            
        }
    }
    
    private func getNameAndMonth(_ number_month: String) -> String {
        
        if number_month == "1" {
            return "ЯНВАРЬ"
        } else if number_month == "2" {
            return "ФЕВРАЛЬ"
        } else if number_month == "3" {
            return "МАРТ"
        } else if number_month == "4" {
            return "АПРЕЛЬ"
        } else if number_month == "5" {
            return "МАЙ"
        } else if number_month == "6" {
            return "ИЮНЬ"
        } else if number_month == "7" {
            return "ИЮЛЬ"
        } else if number_month == "8" {
            return "АВГУСТ"
        } else if number_month == "9" {
            return "СЕНТЯБРЬ"
        } else if number_month == "10" {
            return "ОКТЯБРЬ"
        } else if number_month == "11" {
            return "НОЯБРЬ"
        } else {
            return "ДЕКАБРЬ"
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
