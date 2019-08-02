//
//  CounterChoiceType.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit
import CoreData

class CounterChoiceType: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    @IBOutlet weak var tableView: UITableView!
    
    var fetchedResultsController: NSFetchedResultsController<TypesCounters>?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "TypesCounters", keysForSort: ["name"], predicateFormat: nil) as? NSFetchedResultsController<TypesCounters>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        print(fetchedResultsController?.sections?.count)
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            print(sections[section].numberOfObjects)
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
        vc.title = counter.name
        vc.title_name = counter.name

        navigationController?.pushViewController(vc, animated: true)
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
