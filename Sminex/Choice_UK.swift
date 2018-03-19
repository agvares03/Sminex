//
//  Choice_UK.swift
//  DemoUC
//
//  Created by Роман Тузин on 12.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import Foundation

class Choice_UK: UIViewController {
    // Картинки на подмену
    @IBOutlet weak var fon_top: UIImageView!
    
    // какая регистрация будет
    var role_reg: String = ""
    
    var opener: ViewController_UK!
    var regionString: String = ""
    
    // Массивы для хранения данных
    var regions_names: [String] = []
    var regions_ids: [String] = []
    var teck_region = -1
    
    var raions_names: [String] = []
    var raions_ids: [String] = []
    var teck_raion = -1
    
    var cities_names: [String] = []
    var cities_ids: [String] = []
    var teck_city = -1
    
    var uks_names: [String] = []
    var uks_ids: [String] = []
    var uks_sities: [String] = []
    var teck_uk = -1
    
    // Индикаторы для "красоты"
    @IBOutlet weak var region_indicator: UIActivityIndicatorView!
    @IBOutlet weak var raion_indicator: UIActivityIndicatorView!
    @IBOutlet weak var city_indicator: UIActivityIndicatorView!
    @IBOutlet weak var uk_indicator: UIActivityIndicatorView!
    @IBOutlet weak var choice_indicator: UIActivityIndicatorView!
    
    @IBOutlet weak var edRegion: UITextField!
    @IBOutlet weak var edRaion: UITextField!
    @IBOutlet weak var edCity: UITextField!
    @IBOutlet weak var edUK: UITextField!
    
    @IBOutlet weak var btnRegion: UIButton!
    @IBOutlet weak var btnRaion: UIButton!
    @IBOutlet weak var btnCity: UIButton!
    @IBOutlet weak var btnUK: UIButton!
    @IBOutlet weak var btnChoice: UIButton!
    
    
    @IBAction func getRegion(_ sender: UIButton) {
    }
    @IBAction func getRaion(_ sender: UIButton) {
    }
    @IBAction func getCity(_ sender: UIButton) {
    }
    @IBAction func getUK(_ sender: UIButton) {
    }
    @IBAction func choiceUK(_ sender: UIButton) {
        // Выбор упр. компании
        if (edUK.text == "") {
            let alert = UIAlertController(title: "Ошибка", message: "Не выбрана упр. компания", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        } else {
            
            let defaults = UserDefaults.standard
            defaults.setValue(edUK.text, forKey: "name_uk")
            defaults.setValue(self.uks_sities[teck_uk], forKey: "SiteSM")
            defaults.synchronize()
            
            let vc  = self.storyboard?.instantiateViewController(withIdentifier: "login_activity_uk") as!  ViewController_UK
            vc.role_reg = self.role_reg
            self.present(vc, animated: true, completion: nil)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        region_indicator.startAnimating()
        raion_indicator.startAnimating()
        city_indicator.startAnimating()
        uk_indicator.startAnimating()
        choice_indicator.startAnimating()
        
        self.startIndicator(num_ind: "1")
        
        // Первый показ - загрузим регионы
        let urlPath = "http://uk-gkh.org/UKWebService/GetRegions.ashx"
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                self.regionString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
//                                                print("token (add) = \(String(describing: self.regionString))")
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    // Получим список регионов
                                                    if let regions = json["Regions"] {
                                                        for index in 0...(regions.count)!-1 {
                                                            let obj_region = regions.object(at: index) as! [String:AnyObject]
                                                            for obj in obj_region {
                                                                if obj.key == "Name" {
                                                                    self.regions_names.append(obj.value as! String)
                                                                }
                                                                if obj.key == "ID" {
                                                                    self.regions_ids.append(String(describing: obj.value))
                                                                }
                                                            }
                                                        }
                                                    }
                                                    
                                                    self.end_choice()
                                                    
                                                    
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
        })
        task.resume()
        
        // Определим интерфейс для разных ук
        #if isGKRZS
            let server = Server()
            fon_top.image               = UIImage(named: "fon_top_gkrzs")
            btnChoice.backgroundColor   = server.hexStringToUIColor(hex: "#1f287f")
        #else
            // Оставим текущуий интерфейс
        #endif
        
    }
    
    func end_choice() {
        DispatchQueue.main.async(execute: {
            self.stopIndicator()
            self.update_view()
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "get_regions") {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = regions_names
            selectItemController.selectedIndex = teck_region
            selectItemController.selectHandler = { selectedIndex in
                
                self.ClearRaions()
                self.ClearCities()
                self.ClearUKs()
                
                self.teck_region = selectedIndex
                let choice_id_region   = self.regions_ids[selectedIndex]
                
                self.edRegion.text = self.appRegionString()
                
                self.AddRaions(id_region: choice_id_region)
                self.AddTownsRegions(id_region: choice_id_region)
                
            }
        } else if (segue.identifier == "get_raions") {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = raions_names
            selectItemController.selectedIndex = teck_raion
            selectItemController.selectHandler = { selectedIndex in
                
                self.ClearCities()
                self.ClearUKs()
                
                self.teck_raion = selectedIndex
                let choice_id_raion   = self.raions_ids[selectedIndex]
                
                self.edRaion.text  = self.appRaionString()
                
                self.AddTownsRaions(id_region: self.regions_ids[self.teck_region], id_raion: choice_id_raion)
                
            }
        } else if (segue.identifier == "get_cities") {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = cities_names
            selectItemController.selectedIndex = teck_city
            selectItemController.selectHandler = { selectedIndex in
                
                self.ClearUKs()
                
                self.teck_city = selectedIndex
                let choice_id_city   = self.cities_ids[selectedIndex]
                
                self.edCity.text   = self.appCityString()
                
                self.AddUks(id_city: choice_id_city)
                
            }
        } else if (segue.identifier == "get_uks") {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings = uks_names
            selectItemController.selectedIndex = teck_uk
            selectItemController.selectHandler = { selectedIndex in
                
                self.teck_uk = selectedIndex
                
                self.edUK.text     = self.appUKString()
                
                self.update_view()
            }
        }
    }
    
    // Процедуры очистки списков
    func ClearRaions() {
        raions_names = []
        raions_ids = []
        teck_raion = -1
    }
    
    func ClearCities() {
        cities_names = []
        cities_ids = []
        teck_city = -1
    }
    
    func ClearUKs() {
        uks_names = []
        uks_ids = []
        teck_uk = -1
    }
    
    // Процедуры заполения списков
    func AddRaions(id_region: String) {
        
        self.startIndicator(num_ind: "2")
        
        let urlPath = "http://uk-gkh.org/UKWebService/GetRaions.ashx?regionId=" + id_region
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    // Получим список районов по региону
                                                    if let raions = json["Raions"] {
                                                        for index in 0...(raions.count)!-1 {
                                                            let obj_raion = raions.object(at: index) as! [String:AnyObject]
                                                            for obj in obj_raion {
                                                                if obj.key == "Name" {
                                                                    self.raions_names.append(obj.value as! String)
                                                                }
                                                                if obj.key == "ID" {
                                                                    self.raions_ids.append(String(describing: obj.value))
                                                                }
                                                            }
                                                        }
                                                    }
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
                                                self.end_choice()
                                                
        })
        task.resume()
    }
    
    func AddTownsRegions(id_region: String) {
        
        self.startIndicator(num_ind: "3")
        
        let urlPath = "http://uk-gkh.org/UKWebService/GetTowns.ashx?regionId=" + id_region
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    // Получим список городов по региону
                                                    if let towns = json["Towns"] {
                                                        for index in 0...(towns.count)!-1 {
                                                            let obj_town = towns.object(at: index) as! [String:AnyObject]
                                                            for obj in obj_town {
                                                                if obj.key == "Name" {
                                                                    self.cities_names.append(obj.value as! String)
                                                                }
                                                                if obj.key == "ID" {
                                                                    self.cities_ids.append(String(describing: obj.value))
                                                                }
                                                            }
                                                        }
                                                    }
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
                                                self.end_choice()
                                                
        })
        task.resume()
    }
    
    func AddTownsRaions(id_region: String, id_raion: String) {
        
        self.startIndicator(num_ind: "3")
        
        let urlPath = "http://uk-gkh.org/UKWebService/GetTowns.ashx?regionId=" + id_region + "&raionId=" + id_raion
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    // Получим список городов по району
                                                    if let towns = json["Towns"] {
                                                        for index in 0...(towns.count)!-1 {
                                                            let obj_town = towns.object(at: index) as! [String:AnyObject]
                                                            for obj in obj_town {
                                                                if obj.key == "Name" {
                                                                    self.cities_names.append(obj.value as! String)
                                                                }
                                                                if obj.key == "ID" {
                                                                    self.cities_ids.append(String(describing: obj.value))
                                                                }
                                                            }
                                                        }
                                                    }
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
                                                self.end_choice()
                                                
        })
        task.resume()
    }
    
    func AddUks(id_city: String) {
        self.startIndicator(num_ind: "4")
        
        let urlPath = "http://uk-gkh.org/UKWebService/GetUK.ashx?townId=" + id_city
        let url: NSURL = NSURL(string: urlPath)!
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request as URLRequest,
                                              completionHandler: {
                                                data, response, error in
                                                
                                                if error != nil {
                                                    return
                                                }
                                                
                                                do {
                                                    let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                                                    
                                                    // Получим список управляющих компаний
                                                    if let uks = json["UK"] {
                                                        for index in 0...(uks.count)!-1 {
                                                            let obj_uk = uks.object(at: index) as! [String:AnyObject]
                                                            for obj in obj_uk {
                                                                if obj.key == "Name" {
                                                                    self.uks_names.append(obj.value as! String)
                                                                }
                                                                if obj.key == "ID" {
                                                                    self.uks_ids.append(String(describing: obj.value))
                                                                }
                                                                if obj.key == "SiteSM" {
                                                                    self.uks_sities.append(String(describing: obj.value))
                                                                }
                                                            }
                                                        }
                                                    }
                                                } catch let error as NSError {
                                                    print(error)
                                                }
                                                
                                                self.end_choice()
                                                
        })
        task.resume()
    }
    
    // Процедуры отображения названий
    func appRegionString() -> String {
        if teck_region == -1 {
            return ""
        }
        if teck_region >= 0 && teck_region < regions_names.count {
            return regions_names[teck_region]
        }
        return ""
    }
    
    func appRaionString() -> String {
        if teck_raion == -1 {
            return ""
        }
        if teck_raion >= 0 && teck_raion < raions_names.count {
            return raions_names[teck_raion]
        }
        return ""
    }
    
    func appCityString() -> String {
        if teck_city == -1 {
            return ""
        }
        if teck_city >= 0 && teck_city < cities_names.count {
            return cities_names[teck_city]
        }
        return ""
    }
    
    func appUKString() -> String {
        if teck_uk == -1 {
            return ""
        }
        if teck_uk >= 0 && teck_uk < uks_names.count {
            return uks_names[teck_uk]
        }
        return ""
    }
    
    // Общая процедура обновления всех данных на форме
    func update_view() {
        
        if (raions_names.count == 0) {
            btnRaion.isEnabled = false
        } else {
            btnRaion.isEnabled = true
        }
        
        if (cities_names.count == 0) {
            btnCity.isEnabled = false
        } else {
            btnCity.isEnabled = true
        }
        
        if (uks_names.count == 0) {
            btnUK.isEnabled = false
        } else {
            btnUK.isEnabled = true
        }
        
    }
    
    // Процедуры индикации
    func startIndicator(num_ind: String) {
        if (num_ind == "1") {
            region_indicator.isHidden = false
            raion_indicator.isHidden  = false
            city_indicator.isHidden   = false
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnRegion.isHidden        = true
            btnRaion.isHidden         = true
            btnCity.isHidden          = true
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if (num_ind == "2") {
            raion_indicator.isHidden  = false
            city_indicator.isHidden   = false
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnRaion.isHidden         = true
            btnCity.isHidden          = true
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if (num_ind == "3") {
            city_indicator.isHidden   = false
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnCity.isHidden          = true
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if (num_ind == "4") {
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if (num_ind == "5") {
            choice_indicator.isHidden = false

            btnChoice.isHidden        = true
        }
    }
    
    func stopIndicator() {
        
        region_indicator.isHidden = true
        raion_indicator.isHidden  = true
        city_indicator.isHidden   = true
        uk_indicator.isHidden     = true
        choice_indicator.isHidden = true
        
        btnRegion.isHidden        = false
        btnRaion.isHidden         = false
        btnCity.isHidden          = false
        btnUK.isHidden            = false
        btnChoice.isHidden        = false
        
    }
    
}
