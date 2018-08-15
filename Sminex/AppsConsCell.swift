//
//  AppsConsCell.swift
//  Sminex
//
//  Created by IH0kN3m on 3/20/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import UIKit

final class AppsConsCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var Number: UILabel!
    @IBOutlet weak var tema: UILabel!
    @IBOutlet weak var text_app: UILabel!
    @IBOutlet weak var date_app: UILabel!
    @IBOutlet weak var image_app: UIImageView!
    
}

final class AppsConsCloseCell: UITableViewCell {
    
    var delegate: UIViewController?
    
    @IBOutlet weak var Number: UILabel!
    @IBOutlet weak var tema: UILabel!
    @IBOutlet weak var text_app: UILabel!
    @IBOutlet weak var date_app: UILabel!
    
}
