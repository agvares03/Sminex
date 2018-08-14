//
//  ChoiceLS.swift
//  DemoUC
//
//  Created by Роман Тузин on 12.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

final class ChoiceLS: UITableViewController {

    @IBAction private func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet private weak var streetCell:  UITableViewCell!
    @IBOutlet private weak var flatCell:    UITableViewCell!
    @IBOutlet private weak var lsCell:      UITableViewCell!
    @IBOutlet private weak var phone:       UITextField!
    
    @IBAction private func choice(_ sender: UIButton) {}
    
    private let streetsArray:    [String] = []
    private let flatsArray:      [String] = []
    private let lsArray:         [String] = []
    
    private var street      = -1
    private var ls          = -1
    private var flat        = -1
    private var streetStr   = ""
    private var flatStr     = ""
    private var lsStr       = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar           = self.navigationController?.navigationBar
        navigationBar?.tintColor    = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        loadData()
        updateViews()
        
    }
    
    private func loadData() {}
    
    private func updateViews() {
        streetCell.detailTextLabel?.text    = streetString()
        flatCell.detailTextLabel?.text      = flatString()
        lsCell.detailTextLabel?.text        = lsString()
    }
    
    private func streetString() -> String {
        if street == -1 {
            return "не выбран"
        }
        if street >= 0 && street < streetsArray.count {
            return streetsArray[street]
        }
        return ""
    }
    
    private func flatString() -> String {
        if flat == -1 {
            return "не выбран"
        }
        if flat >= 0 && flat < flatsArray.count {
            return flatsArray[flat]
        }
        return ""
    }
    
    private func lsString() -> String {
        if ls == -1 {
            return "не выбран"
        }
        if ls >= 0 && ls < lsArray.count {
            return lsArray[ls]
        }
        return ""
    }
}
