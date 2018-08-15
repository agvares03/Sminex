//
//  UIExtension.swift
//  Sminex
//
//  Created by Igor Ratynski on 07.08.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showAlert(message: String, title: String = "Ошибка") {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}
