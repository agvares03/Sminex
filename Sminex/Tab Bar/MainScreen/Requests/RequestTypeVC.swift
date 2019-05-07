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
        updateUserInterface()
        let type: RequestTypeStruct
        type = .init(id: "3", name: "Услуги службы комфорта")
        
        tableView.tableFooterView = UIView()
        if let types = TemporaryHolder.instance.requestTypes?.types {
            data = types
            tableView.reloadData()
        }
        data.append(type)
    }
    
    func updateUserInterface() {
        switch Network.reachability.status {
        case .unreachable:
            let alert = UIAlertController(title: "Ошибка", message: "Отсутствует подключенние к интернету", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Повторить", style: .default) { (_) -> Void in
                self.viewDidLoad()
            }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        case .wifi: break
            
        case .wwan: break
            
        }
    }
    @objc func statusManager(_ notification: Notification) {
        updateUserInterface()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .flagsChanged, object: Network.reachability)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default
            .addObserver(self,
                         selector: #selector(statusManager),
                         name: .flagsChanged,
                         object: Network.reachability)
        updateUserInterface()
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
            if let vc = segue.destination as? NewTechServiceVC, let index = sender as? Int {
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
        let denyIssuanceOfPassSingle:Bool = (UserDefaults.standard.value(forKey: "denyIssuanceOfPassSingle") as! Bool)
        let denyIssuanceOfPassSingleWithAuto:Bool = (UserDefaults.standard.value(forKey: "denyIssuanceOfPassSingleWithAuto") as! Bool)
        if  (denyIssuanceOfPassSingle == true) && (denyIssuanceOfPassSingleWithAuto == true) && (cell.textLabel?.text == "Гостевой пропуск") {
            print("Deleted")
            self.data.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            self.tableView.reloadData()
        }
        let denyCompanyService:Bool = (UserDefaults.standard.value(forKey: "denyCompanyService") as! Bool)
        if  (denyCompanyService) && (cell.textLabel?.text == "Услуги службы комфорта") {
            print("Deleted")
            self.data.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.automatic)
            self.tableView.reloadData()
        }
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
        } else if name == "Услуги службы комфорта" {
            performSegue(withIdentifier: Segues.fromRequestTypeVC.toServiceUK, sender: indexPath.row)
        }
    }
    
}
