//
//  AppsUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

final class AppsUser: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAppDelegate, ShowAppDelegate {

    @IBOutlet private weak var menuButton:    UIBarButtonItem!
    @IBOutlet private weak var tableApps:     UITableView!
    
    private var fetchedResultsController: NSFetchedResultsController<Applications>?
    
    @IBOutlet private weak var switchCloseApps: UISwitch!
    
    @IBAction func switch_Go(_ sender: UISwitch) {
        updateCloseApps()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
//        let navigationBar           = self.navigationController?.navigationBar
//        navigationBar?.tintColor    = UIColor.white
//        navigationBar?.barTintColor = UIColor.blue

        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        tableApps.delegate = self
        
        loadData()
        updateTable()
    }
    
    private func loadData() {
        
        if switchCloseApps.isOn {
            self.fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Applications", keysForSort: ["number"]) as? NSFetchedResultsController<Applications>
        } else {
            let close: NSNumber = 1
            let predicateFormat = String(format: " is_close =%@ ", close)
            self.fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Applications", keysForSort: ["number"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Applications>
        }
        
        do {
            try fetchedResultsController!.performFetch()
        } catch {
            
            #if DEBUG
                print(error)
            #endif
        }
    }
    
    private func updateTable() {
        tableApps.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController?.sections {
            return sections[section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let app = (fetchedResultsController?.object(at: indexPath))! as Applications
        
        if app.is_close == 1 {
            let cell = self.tableApps.dequeueReusableCell(withIdentifier: "AppCell") as! AppsCell
            cell.Number.text        = app.number
            cell.tema.text          = app.tema
            cell.text_app.text      = app.text
            cell.date_app.text      = app.date
            cell.image_app.image    = UIImage(named: "ic_comm_list")
            
            cell.delegate = self
            return cell
            
        } else {
            let cell = self.tableApps.dequeueReusableCell(withIdentifier: "AppCellClose") as! AppsCloseCell
            cell.Number.text    = app.number
            cell.tema.text      = app.tema
            cell.text_app.text  = app.text
            cell.date_app.text  = app.date
            
            cell.delegate = self
            return cell
        }
    
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromAppsUser.toShowApp {
            let indexPath = tableApps.indexPathForSelectedRow!
            let app = fetchedResultsController!.object(at: indexPath)
            
            let appUser             = segue.destination as! AppUser
            appUser.title           = "Заявка №" + app.number!
            appUser.txtTema_   = app.tema!
            appUser.txtText_   = app.text!
            appUser.txtDate_   = app.date!
            appUser.idApp_     = app.number!
            appUser.delegate  = self
            appUser.apps_      = app
        
        } else if segue.identifier == Segues.fromAppsUser.toShowAppsClose {
            let indexPath = tableApps.indexPathForSelectedRow!
            let app = fetchedResultsController!.object(at: indexPath)
            
            let appUser             = segue.destination as! AppUser
            appUser.title           = "Заявка №" + app.number!
            appUser.txtTema_   = app.tema!
            appUser.txtText_   = app.text!
            appUser.txtDate_   = app.date!
            appUser.idApp_     = app.number!
            appUser.delegate  = self
            appUser.apps_      = app
        
        } else if segue.identifier == Segues.fromAppsUser.toAddApp {
            let AddApp = (segue.destination as! UINavigationController).viewControllers.first as! AddAppUser
            AddApp.delegate = self
        }
    }
    
    func addAppDone(addApp: AddAppUser) {
        loadData()
        tableApps.reloadData()
    }
    
    func showAppDone(showApp: AppUser) {
        loadData()
        updateTable()
    }
    
    private func updateCloseApps() {
        loadData()
        updateTable()
    }

}





private final class AppsCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var image_app: UIImageView!
    @IBOutlet weak var Number:    UILabel!
    @IBOutlet weak var tema:      UILabel!
    @IBOutlet weak var text_app:  UILabel!
    @IBOutlet weak var date_app:  UILabel!
    
}

private final class AppsCloseCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var Number:    UILabel!
    @IBOutlet weak var tema:      UILabel!
    @IBOutlet weak var text_app:  UILabel!
    @IBOutlet weak var date_app:  UILabel!
    
}

