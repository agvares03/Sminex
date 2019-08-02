//
//  NotificationTableCell.swift
//  Sminex
//
//  Created by Роман Тузин on 02/08/2019.
//

import UIKit

class NotificationTableCell: UITableViewCell {
    
    @IBOutlet weak var Name_push: UILabel!
    @IBOutlet weak var Body_push: UILabel!
    @IBOutlet weak var Date_push: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
