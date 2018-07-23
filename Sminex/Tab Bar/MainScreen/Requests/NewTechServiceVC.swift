//
//  NewTechServiceVC.swift
//  Sminex
//
//  Created by Anton Barbyshev on 23.07.2018.
//  Copyright © 2018 Anton Barbyshev. All rights reserved.
//

import UIKit
import AFDateHelper

private enum ContentType {
    case detailsText
    case time
    case chooseTime
    case photos
}

class NewTechServiceVC: UIViewController {
    
    // MARK: Outlets
    
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: Properties
    
    private var contents: [ContentType] = [.detailsText, .time]
    private var detailText = ""
    private var date = Date()
    private var images = [UIImage]() {
        didSet {
            
        }
    }
    
    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    // MARK: Actions
    
    @IBAction private func cancelButtonPressed(_ sender: UIBarButtonItem) {
        
        view.endEditing(true)
        let action = UIAlertController(title: "Удалить заявку?", message: "Изменения не сохранятся", preferredStyle: .alert)
        action.addAction(UIAlertAction(title: "Отмена", style: .default, handler: { (_) in }))
        action.addAction(UIAlertAction(title: "Удалить", style: .destructive, handler: { (_) in self.navigationController?.popViewController(animated: true) }))
        present(action, animated: true, completion: nil)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

}

extension NewTechServiceVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let content = contents[indexPath.row]
        
        switch content {
        case .detailsText:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextViewCell", for: indexPath) as! TextViewCell
            cell.delegate = self
            cell.textView.text = detailText
            return cell
        case .time:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TimeCell", for: indexPath)
            cell.detailTextLabel?.text = date.toString(format: .custom("dd MMMM HH:mm"))
            return cell
        case .chooseTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DatePickerCell", for: indexPath) as! DatePickerCell
            cell.delegate = self
            cell.configure(date: date)
            return cell
        case .photos:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PhotosCell", for: indexPath) as! PhotosCell
            cell.delegate = self
            cell.configure(images: images)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 1 {
            if contents.contains(.chooseTime) {
                contents.remove(at: 2)
            } else {
                contents.insert(.chooseTime, at: 2)
            }
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var height = UITableViewAutomaticDimension
        let content = contents[indexPath.row]
        
        switch content {
        case .detailsText:
            break
        case .time:
            height = 60
        case .chooseTime:
            height = 150
        case .photos:
            height = 166
        }
        return height
    }
    
}

extension NewTechServiceVC: TextViewCellDelegate {
    
    func textViewCell(cell: TextViewCell, didChangeText text: String) {
        detailText = text
        let size = cell.textView.frame.size
        let newSize = cell.textView.sizeThatFits(CGSize(width: size.width, height: CGFloat.greatestFiniteMagnitude))
        
        if size.height != newSize.height {
            cell.textView.frame.size = newSize
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension NewTechServiceVC: DatePickerCellDelegate {
    
    func dateDidChange(date: Date) {
        self.date = date
    }
    
}

extension NewTechServiceVC: PhotosCellDelegate {
    
    func photoDidDelete(index: Int) {
        
    }
    
    func photoDidOpen(index: Int) {
        
    }
    
}
