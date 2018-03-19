//
//  CounterCell.swift
//  DemoUC
//
//  Created by Роман Тузин on 28.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class CounterCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var name_counter: UILabel!
    @IBOutlet weak var pred: UILabel!
    @IBOutlet weak var teck: UILabel!    
    @IBOutlet weak var count_txt: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
