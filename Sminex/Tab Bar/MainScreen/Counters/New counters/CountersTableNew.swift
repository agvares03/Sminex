//
//  CountersTableNew.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit
import CoreData

class CountersTableNew: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var title_name: String?
    
    @IBOutlet weak var tableView: UITableView!
    var fetchedResultsController: NSFetchedResultsController<Counters>?
    
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let predicate = NSPredicate(format: "owner == %@ AND num_month == %@ AND year == %@", title_name ?? "", UserDefaults.standard.string(forKey: "month") ?? "", UserDefaults.standard.string(forKey: "year") ?? "")
        fetchedResultsController?.fetchRequest.predicate = predicate
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Counters", keysForSort: ["owner"], predicateFormat: nil) as? NSFetchedResultsController<Counters>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }

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
        
        let cell: CounterCellNew = self.tableView.dequeueReusableCell(withIdentifier: "CounterCellNew") as! CounterCellNew
        
        cell.counter_name.text = "Счетчик №" + counter.uniq_num! ?? ""
        
        return cell
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
