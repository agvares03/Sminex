//
//  CommConsCell_cons.swift
//  DemoUC
//
//  Created by Роман Тузин on 13.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class CommConsCell_cons: UITableViewCell {
    
    @IBOutlet weak var author: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var text_comm: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
