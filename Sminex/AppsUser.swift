//
//  AppsUser.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

class AppsUser: UIViewController, UITableViewDelegate, UITableViewDataSource, AddAppDelegate, ShowAppDelegate {

    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableApps: UITableView!
    
    var fetchedResultsController: NSFetchedResultsController<Applications>?
    
    @IBOutlet weak var switchCloseApps: UISwitch!
    @IBAction func switch_Go(_ sender: UISwitch) {
        updateCloseApps()
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
        
        tableApps.delegate = self
        
        load_data()
        updateTable()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.barTintColor = server.hexStringToUIColor(hex: "#1f287f")
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func load_data() {
        if (switchCloseApps.isOn) {
            self.fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Applications", keysForSort: ["number"]) as? NSFetchedResultsController<Applications>
        } else {
            let close: NSNumber = 1
            let predicateFormat = String(format: " is_close =%@ ", close)
            self.fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Applications", keysForSort: ["number"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Applications>
        }
        
        do {
            try fetchedResultsController!.performFetch()
        } catch {
            print(error)
        }
    }
    
    func updateTable() {
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
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let img = UIImage(named: "ic_comm_list_white")
        #else
            let img = UIImage(named: "ic_comm_list")
        #endif
        
        if (app.is_close == 1) {
            let cell = self.tableApps.dequeueReusableCell(withIdentifier: "AppCell") as! AppsCell
            cell.Number.text    = app.number
            cell.tema.text      = app.tema
            cell.text_app.text  = app.text
            cell.date_app.text  = app.date
            cell.image_app.image = img
            
            #if isGKRZS
                let server = Server()
                cell.Number.textColor = server.hexStringToUIColor(hex: "#1f287f")
            #else
            #endif
            
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_app" {
            let indexPath = tableApps.indexPathForSelectedRow!
            let app = fetchedResultsController!.object(at: indexPath)
            
            let AppUser             = segue.destination as! AppUser
            AppUser.title           = "Заявка №" + app.number!
            AppUser.txt_tema   = app.tema!
            AppUser.txt_text   = app.text!
            AppUser.txt_date   = app.date!
            AppUser.id_app     = app.number!
            AppUser.delegate   = self
            AppUser.App        = app
        } else if (segue.identifier == "show_app_close") {
            let indexPath = tableApps.indexPathForSelectedRow!
            let app = fetchedResultsController!.object(at: indexPath)
            
            let AppUser             = segue.destination as! AppUser
            AppUser.title           = "Заявка №" + app.number!
            AppUser.txt_tema   = app.tema!
            AppUser.txt_text   = app.text!
            AppUser.txt_date   = app.date!
            AppUser.id_app     = app.number!
            AppUser.delegate   = self
            AppUser.App        = app
        } else if (segue.identifier == "add_app") {
            let AddApp = (segue.destination as! UINavigationController).viewControllers.first as! AddAppUser
            AddApp.delegate = self
        }
    }
    
    func addAppDone(addApp: AddAppUser) {
        load_data()
        self.tableApps.reloadData()
    }
    
    func showAppDone(showApp: AppUser) {
        load_data()
        updateTable()
    }
    
    func updateCloseApps() {
        load_data()
        updateTable()
    }

}
