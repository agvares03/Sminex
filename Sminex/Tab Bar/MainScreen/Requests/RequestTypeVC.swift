//
//  RequestTypeVC.swift
//  Sminex
//
//  Created by IH0kN3m on 3/23/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

class RequestTypeVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: Properties
    
    open var delegate: AppsUserDelegate?
    
    private var typeName = ""
    private var data = [RequestTypeStruct]()
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        if let types = TemporaryHolder.instance.requestTypes?.types {
            data = types
            tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: Actions
    
    @IBAction private func backButtonPressed(_ sender: UIBarButtonItem) {
        
        let AppsUserDelegate = self.delegate as! AppsUser
        
        if (AppsUserDelegate.isCreatingRequest_) {
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Segues.fromRequestTypeVC.toCreateAdmission:
            if let vc = segue.destination as? CreateRequestVC, let index = sender as? Int {
                vc.delegate = delegate
                vc.name_ = typeName
                vc.type_ = data[index]
            }
        case Segues.fromRequestTypeVC.toCreateServive:
            if let vc = segue.destination as? CreateTechServiceVC, let index = sender as? Int {
                vc.delegate = delegate
                vc.type_ = data[index]
            }
        default: break
        }
    }
}

extension RequestTypeVC: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row].name
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let name = data[indexPath.row].name
        
        if  (name?.contains(find: "ропуск"))! {
            typeName = name ?? ""
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateAdmission, sender: indexPath.row)
            
        } else if name == "Техническое обслуживание" {
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toCreateServive, sender: indexPath.row)
        }
    }
    
}
