//
//  ChoiceLS.swift
//  DemoUC
//
//  Created by Роман Тузин on 12.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class ChoiceLS: UITableViewController {

    @IBAction func cancelItem(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var streetCell: UITableViewCell!
    @IBOutlet weak var flatCell: UITableViewCell!
    @IBOutlet weak var lsCell: UITableViewCell!
    @IBOutlet weak var phone: UITextField!
    @IBAction func choice(_ sender: UIButton) {
    
    }
    
    let Streets: [String] = []
    let Flats: [String] = []
    let LS: [String] = []
    
    var street = -1
    var streetStr = ""
    var flat = -1
    var flatStr = ""
    var ls = -1
    var lsStr = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Установим общий стиль
        let navigationBar = self.navigationController?.navigationBar
        //        navigationBar?.barStyle = UIBarStyle.black
        //        navigationBar?.backgroundColor = UIColor.blue
        navigationBar?.tintColor = UIColor.white
        navigationBar?.barTintColor = UIColor.blue
        
        load_data()
        update_views()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            navigationBar?.tintColor = server.hexStringToUIColor(hex: "#c0c0c0")
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func load_data() {
        
    }
    
    func update_views() {
        streetCell.detailTextLabel?.text = streetString()
        flatCell.detailTextLabel?.text = flatString()
        lsCell.detailTextLabel?.text = lsString()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func streetString() -> String {
        if street == -1 {
            return "не выбран"
        }
        if street >= 0 && street < Streets.count {
            return Streets[street]
        }
        return ""
    }
    
    func flatString() -> String {
        if flat == -1 {
            return "не выбран"
        }
        if flat >= 0 && flat < Flats.count {
            return Flats[flat]
        }
        return ""
    }
    
    func lsString() -> String {
        if ls == -1 {
            return "не выбран"
        }
        if ls >= 0 && ls < LS.count {
            return LS[ls]
        }
        return ""
    }
}
