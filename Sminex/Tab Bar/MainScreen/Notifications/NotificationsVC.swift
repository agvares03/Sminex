//
//  NotificationsVC.swift
//  Sminex
//
//  Created by Роман Тузин on 01/08/2019.
//

import UIKit
import CoreData

class NotificationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var fetchedResultsController: NSFetchedResultsController<Notifications>?
    
    @IBAction func BackPressed(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUserInterface()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Notifications", keysForSort: ["date"], predicateFormat: nil) as? NSFetchedResultsController<Notifications>
        do {
            try fetchedResultsController?.performFetch()
        } catch {
            print(error)
        }
        
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключение к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
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
        
        let push = (fetchedResultsController?.object(at: indexPath))! as Notifications
        
        let cell: NotificationTableCell = self.tableView.dequeueReusableCell(withIdentifier: "NotificationTableCell") as! NotificationTableCell
        
        cell.Name_push.text = getTitle(type: push.type!)
        cell.Body_push.text = push.name!
        cell.Date_push.text = push.date!
        
        return cell
    }
    
    func getTitle(type: String) -> String {
        var rezult: String = "Новое уведомление"
        if (type == "REQUEST_COMMENT") {
            rezult = "Новый комментарий"
        } else if (type == "REQUEST_STATUS") {
            rezult = "Изменен статус"
        } else if (type == "NEWS") {
            rezult = "Новая новость"
        } else if (type == "QUESTION") {
            rezult = "Новый опрос"
        } else if (type == "DEBT") {
            rezult = "Информация"
        } else if (type == "METER_VALUE") {
            rezult = "Информация по приборам"
        }
        return rezult
    }
    
    
    
}
