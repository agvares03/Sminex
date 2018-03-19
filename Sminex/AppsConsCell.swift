//
//  AppsConsCell.swift
//  DemoUC
//
//  Created by Роман Тузин on 15.06.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit

class AppsConsCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var Number: UILabel!
    @IBOutlet weak var tema: UILabel!
    @IBOutlet weak var text_app: UILabel!
    @IBOutlet weak var date_app: UILabel!
    @IBOutlet weak var image_app: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
