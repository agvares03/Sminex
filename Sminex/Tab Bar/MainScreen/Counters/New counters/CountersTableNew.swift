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
    @IBOutlet weak var sendLbl:     UILabel!
    var fetchedResultsController: NSFetchedResultsController<Counters>?
    
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dateFrom = UserDefaults.standard.integer(forKey: "meterReadingsDayFrom")
        let dateTo = UserDefaults.standard.integer(forKey: "meterReadingsDayTo")
        let calendar = Calendar.current
        let curDay = calendar.component(.day, from: Date())
        if curDay > dateTo || curDay < dateFrom{
            sendLbl.text = "Передача показаний за этот месяц осуществляется с \(dateFrom) по \(dateTo) число"
            canCount = false
        }else if !canCount!{
            sendLbl.text = "Данные по приборам учета собираются УК самостоятельно"
        }else{
            sendLbl.text = "Передача показаний за этот месяц осуществляется с \(dateFrom) по \(dateTo) число"
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
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data_.count
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
        return CGSize(width: view.frame.size.width, height: size.height)
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
