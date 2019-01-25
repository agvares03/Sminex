//
//  SelectItemController.swift
//  DemoUC
//
//  Created by Роман Тузин on 10.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

final class SelectItemController: UITableViewController {

    @IBAction private func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    public var selectedIndex_   = -1
    public var strings_         = [String]()
    public var selectHandler_:    ((Int)->Void)?
    
    override func viewDidLoad() {
        
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) < selectedIndex_ {
            let path = IndexPath(row: selectedIndex_, section: 0)
            tableView.selectRow(at: path, animated: false, scrollPosition: UITableViewScrollPosition.none)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return strings_.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "item")
        cell?.textLabel?.text = strings_[indexPath.row]
        cell?.accessoryType = selectedIndex_ == indexPath.row ? .checkmark : .none
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex_ = indexPath.row
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        if selectHandler_ != nil {
            selectHandler_!(selectedIndex_)
        }
        navigationController?.dismiss(animated: true, completion: nil)
    }

}
