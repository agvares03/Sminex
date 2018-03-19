//
//  CounterCell_no_history.swift
//  DemoUC
//
//  Created by Роман Тузин on 27.09.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class CounterCell_no_history: UITableViewCell {
    
    var delegate: UIViewController?

    @IBOutlet weak var name_counter: UILabel!
    @IBOutlet weak var teck: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
