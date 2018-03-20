//
//  AppsCons.swift
//  DemoUC
//
//  Created by Роман Тузин on 22.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData

final class AppsCons: UIViewController, UITableViewDelegate, UITableViewDataSource, ShowAppConsDelegate {

    @IBOutlet private weak var menuButton: UIBarButtonItem!
    @IBOutlet private weak var tableApps: UITableView!
    
    private var fetchedResultsController: NSFetchedResultsController<Applications>?
    
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
        
        tableApps.delegate = self
        
        loadData()
        updateTable()
    }
    
    private func loadData() {
        let close: NSNumber = 1
        let predicateFormat = String(format: " is_close =%@ ", close)
        self.fetchedResultsController = CoreDataManager.instance.fetchedResultsController(entityName: "Applications", keysForSort: ["number"], predicateFormat: predicateFormat) as? NSFetchedResultsController<Applications>
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
        
        if (app.is_close == 1) {
            let cell = self.tableApps.dequeueReusableCell(withIdentifier: "AppConsCell") as! AppsConsCell
            cell.Number.text     = app.number
            cell.tema.text       = app.tema
            cell.text_app.text   = app.text
            cell.date_app.text   = app.date
            cell.image_app.image = UIImage(named: "ic_comm_list")
            
            cell.delegate = self
            return cell
        } else {
            let cell = self.tableApps.dequeueReusableCell(withIdentifier: "AppConsCellClose") as! AppsConsCloseCell
            cell.tema.text       = app.tema
            cell.text_app.text   = app.text
            cell.date_app.text   = app.date

            cell.delegate = self
            return cell
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "show_app_cons" {
            let indexPath = tableApps.indexPathForSelectedRow!
            let app = fetchedResultsController!.object(at: indexPath)
            
            let AppCons        = segue.destination as! AppCons
            AppCons.title      = "Заявка №" + app.number!
            AppCons.txtTema_   = app.tema!
            AppCons.txtText_   = app.text!
            AppCons.txtDate_   = app.date!
            AppCons.idApp_     = app.number!
            AppCons.txtAdress_ = app.adress!
            AppCons.txtPhone_  = app.phone!
            AppCons.delegate   = self
        }
    }
    
    func showAppDone(showAppCons: AppCons) {
        loadData()
        updateTable()
    }

}
