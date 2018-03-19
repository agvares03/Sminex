//
//  OSVCell.swift
//  DemoUC
//
//  Created by Роман Тузин on 04.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class OSVCell: UITableViewCell {
    
    var delegate: UIViewController?

    @IBOutlet weak var usluga: UILabel!
    @IBOutlet weak var start: UILabel!
    @IBOutlet weak var plus: UILabel!
    @IBOutlet weak var minus: UILabel!
    @IBOutlet weak var end: UILabel!    
    @IBOutlet weak var img: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
