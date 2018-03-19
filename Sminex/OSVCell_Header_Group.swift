//
//  OSVCell_Header_Group.swift
//  DemoUC
//
//  Created by Роман Тузин on 09.10.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class OSVCell_Header_Group: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var usluga: UILabel!    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
