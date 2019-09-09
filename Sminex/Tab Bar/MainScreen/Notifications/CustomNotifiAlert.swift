//
//  CustomNotifiAlert.swift
//  Sminex
//
//  Created by Sergey Ivanov on 07/08/2019.
//

import UIKit
import UserNotifications

class CustomNotifiAlert: UIViewController, MainScreenDelegate, UIGestureRecognizerDelegate {
    func update(method: String) {
        print("")
    }
    
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet private weak var picker:      UIDatePicker!
    @IBOutlet private weak var pickerHeight: NSLayoutConstraint!
    
    @IBAction private func goQuestion(_ sender: UIButton){
        if name == "У вас есть непройденные опросы"{
            self.performSegue(withIdentifier: "questionTable", sender: self)
        }else{
            self.performSegue(withIdentifier: "toQuestion", sender: self)
        }
    }
    
    @IBAction private func sendNotification(_ sender: UIButton){
//        if sender != nil {
            view.endEditing(true)
//        }
        picker.isHidden     = false
        pickerHeight.constant = 185
    }
    
    @IBAction private func closeAction(_ sender: UIButton){
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    
    @IBAction private func closePicker(_ sender: UIButton){
        pickerHeight.constant = 0
        picker.isHidden = true
    }
    @IBAction private func sendDate(_ sender: UIButton){
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Опрос:", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: self.name, arguments: nil)
        content.sound = UNNotificationSound.default()
        content.categoryIdentifier = "com.elonchan.localNotification"
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self.date)
        // Deliver the notification in 60 seconds.
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest.init(identifier: "FiveSecond", content: content, trigger: trigger)
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request)
        self.removeFromParentViewController()
        self.view.removeFromSuperview()
    }
    public var name = ""
    public var date = Date()
    override func viewDidLoad() {
        super.viewDidLoad()
        name = UserDefaults.standard.string(forKey: "titleNotifi")!
        nameLbl.text = name
        pickerHeight.constant = 0
        picker.isHidden = true
        picker.addTarget(self, action: #selector(
            datePickerValueChanged), for: UIControlEvents.valueChanged)
        // Do any additional setup after loading the view.
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
        tap.delegate                    = self
        view.isUserInteractionEnabled   = true
        view.addGestureRecognizer(tap)
    }
    
    @objc private func viewTapped(_ sender: UITapGestureRecognizer?) {
        if picker.isHidden{
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
        }else{
            pickerHeight.constant = 0
            picker.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toQuestion" {
            let vc = segue.destination as! QuestionsTableVC
            vc.performName_ = name
            vc.delegate = self
        }
        if segue.identifier == "questionTable" {
            let vc = segue.destination as! QuestionsTableVC
            vc.delegate = self
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if name == ""{
            self.removeFromParentViewController()
            self.view.removeFromSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        name = ""
    }
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        date = sender.date
    }
}
