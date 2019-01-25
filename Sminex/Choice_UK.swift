//
//  Choice_UK.swift
//  DemoUC
//
//  Created by Роман Тузин on 12.07.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import Foundation

final class Choice_UK: UIViewController {
    
    // Картинки на подмену
    @IBOutlet private weak var fon_top: UIImageView!
    
    // Какая регистрация будет
    public var roleReg_ = ""
    
    private var opener: ViewController_UK!
    private var regionString = ""
    
    // Массивы для хранения данных
    private var regionsNames: [String] = []
    private var regionsIds:   [String] = []
    private var teckRegion = -1
    
    private var raionsNames: [String] = []
    private var raionsIds:   [String] = []
    private var teckRaion = -1
    
    private var citiesNames: [String] = []
    private var citiesIds:   [String] = []
    private var teckCity = -1
    
    private var uksNames:    [String] = []
    private var uksIds:      [String] = []
    private var uksSities:   [String] = []
    private var teckUk = -1
    
    // Индикаторы для "красоты"
    @IBOutlet private weak var region_indicator:  UIActivityIndicatorView!
    @IBOutlet private weak var raion_indicator:   UIActivityIndicatorView!
    @IBOutlet private weak var city_indicator:    UIActivityIndicatorView!
    @IBOutlet private weak var uk_indicator:      UIActivityIndicatorView!
    @IBOutlet private weak var choice_indicator:  UIActivityIndicatorView!
    
    @IBOutlet private weak var edRegion:  UITextField!
    @IBOutlet private weak var edRaion:   UITextField!
    @IBOutlet private weak var edCity:    UITextField!
    @IBOutlet private weak var edUK:      UITextField!
    
    @IBOutlet private weak var btnRegion: UIButton!
    @IBOutlet private weak var btnRaion:  UIButton!
    @IBOutlet private weak var btnCity:   UIButton!
    @IBOutlet private weak var btnUK:     UIButton!
    @IBOutlet private weak var btnChoice: UIButton!
    
    
    @IBAction private func getRegion(_ sender: UIButton) {}
    @IBAction private func getRaion(_ sender: UIButton) {}
    @IBAction private func getCity(_ sender: UIButton) {}
    @IBAction private func getUK(_ sender: UIButton) {}
    
    @IBAction private func choiceUK(_ sender: UIButton) {
        
        // Выбор упр. компании
        if edUK.text == "" {
            let alert = UIAlertController(title: "Ошибка", message: "Не выбрана упр. компания", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Ок", style: .default) { (_) -> Void in }
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
            
        } else {
            
            let defaults = UserDefaults.standard
            defaults.setValue(edUK.text, forKey: "name_uk")
            defaults.setValue(self.uksSities[teckUk], forKey: "SiteSM")
            defaults.synchronize()
            
            performSegue(withIdentifier: Segues.fromChoiseUK.toLoginActivity, sender: self)
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
        var request = URLRequest(url: URL(string: "http://uk-gkh.org/UKWebService/GetRegions.ashx")!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                return
            }
            
            self.regionString = String(data: data!, encoding: .utf8) ?? ""
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                
                // Получим список регионов
                if let regions = json["Regions"] {
                    for index in 0...(regions.count)!-1 {
                        let obj_region = regions.object(at: index) as! [String:AnyObject]
                        for obj in obj_region {
                            if obj.key == "Name" {
                                self.regionsNames.append(obj.value as! String)
                            }
                            if obj.key == "ID" {
                                self.regionsIds.append(String(describing: obj.value))
                            }
                        }
                    }
                }
                
                self.endChoice()
                
                
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
            }.resume()
    }
    
    private func endChoice() {
        DispatchQueue.main.async {
            self.stopIndicator()
            self.updateView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == Segues.fromChoiseUK.toGetRegions {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = regionsNames
            selectItemController.selectedIndex_ = teckRegion
            selectItemController.selectHandler_ = { selectedIndex in
                
                self.clearRaions()
                self.clearCities()
                self.clearUKs()
                
                self.teckRegion = selectedIndex
                let choice_id_region   = self.regionsIds[selectedIndex]
                
                self.edRegion.text = self.appRegionString()
                
                self.addRaions(id_region: choice_id_region)
                self.addTownsRegions(id_region: choice_id_region)
                
            }
        } else if segue.identifier == Segues.fromChoiseUK.toGetRaions {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = raionsNames
            selectItemController.selectedIndex_ = teckRaion
            selectItemController.selectHandler_ = { selectedIndex in
                
                self.clearCities()
                self.clearUKs()
                
                self.teckRaion = selectedIndex
                let choice_id_raion   = self.raionsIds[selectedIndex]
                
                self.edRaion.text  = self.appRaionString()
                
                self.addTownsRaions(id_region: self.regionsIds[self.teckRegion], id_raion: choice_id_raion)
                
            }
        } else if segue.identifier == Segues.fromChoiseUK.toGetCities {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = citiesNames
            selectItemController.selectedIndex_ = teckCity
            selectItemController.selectHandler_ = { selectedIndex in
                
                self.clearUKs()
                
                self.teckCity = selectedIndex
                let choice_id_city   = self.citiesIds[selectedIndex]
                
                self.edCity.text   = self.appCityString()
                
                self.addUks(id_city: choice_id_city)
                
            }
        } else if segue.identifier == Segues.fromChoiseUK.toGetUKs {
            let selectItemController = (segue.destination as! UINavigationController).viewControllers.first as! SelectItemController
            selectItemController.strings_ = uksNames
            selectItemController.selectedIndex_ = teckUk
            selectItemController.selectHandler_ = { selectedIndex in
                
                self.teckUk = selectedIndex
                
                self.edUK.text     = self.appUKString()
                
                self.updateView()
            }
            
        } else if segue.identifier == Segues.fromChoiseUK.toLoginActivity {
            let vc = segue.destination as! ViewController_UK
            vc.roleReg_ = roleReg_
        }
    }
    
    // Процедуры очистки списков
    private func clearRaions() {
        raionsNames = []
        raionsIds = []
        teckRaion = -1
    }
    
    private func clearCities() {
        citiesNames = []
        citiesIds = []
        teckCity = -1
    }
    
    private func clearUKs() {
        uksNames = []
        uksIds = []
        teckUk = -1
    }
    
    // Процедуры заполения списков
    private func addRaions(id_region: String) {
        
        self.startIndicator(num_ind: "2")
        
        var request = URLRequest(url: URL(string: "http://uk-gkh.org/UKWebService/GetRaions.ashx?regionId=" + id_region)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
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
                                self.raionsNames.append(obj.value as! String)
                            }
                            if obj.key == "ID" {
                                self.raionsIds.append(String(describing: obj.value))
                            }
                        }
                    }
                }
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
            
            self.endChoice()
            
            }.resume()
    }
    
    private func addTownsRegions(id_region: String) {
        
        self.startIndicator(num_ind: "3")
        
        var request = URLRequest(url: URL(string: "http://uk-gkh.org/UKWebService/GetTowns.ashx?regionId=" + id_region)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
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
                                self.citiesNames.append(obj.value as! String)
                            }
                            if obj.key == "ID" {
                                self.citiesIds.append(String(describing: obj.value))
                            }
                        }
                    }
                }
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
            
            self.endChoice()
            
            }.resume()
    }
    
    private func addTownsRaions(id_region: String, id_raion: String) {
        
        self.startIndicator(num_ind: "3")
        
        var request = URLRequest(url: URL(string: "http://uk-gkh.org/UKWebService/GetTowns.ashx?regionId=" + id_region + "&raionId=" + id_raion)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
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
                                self.citiesNames.append(obj.value as! String)
                            }
                            if obj.key == "ID" {
                                self.citiesIds.append(String(describing: obj.value))
                            }
                        }
                    }
                }
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
            
            self.endChoice()
            
            }.resume()
    }
    
    private func addUks(id_city: String) {
        self.startIndicator(num_ind: "4")
        
        var request = URLRequest(url: URL(string: "http://uk-gkh.org/UKWebService/GetUK.ashx?townId=" + id_city)!)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) {
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
                                self.uksNames.append(obj.value as! String)
                            }
                            if obj.key == "ID" {
                                self.uksIds.append(String(describing: obj.value))
                            }
                            if obj.key == "SiteSM" {
                                self.uksSities.append(String(describing: obj.value))
                            }
                        }
                    }
                }
            } catch let error {
                
                #if DEBUG
                    print(error)
                #endif
            }
            
            self.endChoice()
            
            }.resume()
    }
    
    // Процедуры отображения названий
    private func appRegionString() -> String {
        if teckRegion == -1 {
            return ""
        }
        if teckRegion >= 0 && teckRegion < regionsNames.count {
            return regionsNames[teckRegion]
        }
        return ""
    }
    
    private func appRaionString() -> String {
        if teckRaion == -1 {
            return ""
        }
        if teckRaion >= 0 && teckRaion < raionsNames.count {
            return raionsNames[teckRaion]
        }
        return ""
    }
    
    private func appCityString() -> String {
        if teckCity == -1 {
            return ""
        }
        if teckCity >= 0 && teckCity < citiesNames.count {
            return citiesNames[teckCity]
        }
        return ""
    }
    
    private func appUKString() -> String {
        if teckUk == -1 {
            return ""
        }
        if teckUk >= 0 && teckUk < uksNames.count {
            return uksNames[teckUk]
        }
        return ""
    }
    
    // Общая процедура обновления всех данных на форме
    private func updateView() {
        
        if raionsNames.count == 0 {
            btnRaion.isEnabled = false
        } else {
            btnRaion.isEnabled = true
        }
        
        if citiesNames.count == 0 {
            btnCity.isEnabled = false
        } else {
            btnCity.isEnabled = true
        }
        
        if uksNames.count == 0 {
            btnUK.isEnabled = false
        } else {
            btnUK.isEnabled = true
        }
        
    }
    
    // Процедуры индикации
    private func startIndicator(num_ind: String) {
        if num_ind == "1" {
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
        } else if num_ind == "2" {
            raion_indicator.isHidden  = false
            city_indicator.isHidden   = false
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnRaion.isHidden         = true
            btnCity.isHidden          = true
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if num_ind == "3" {
            city_indicator.isHidden   = false
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnCity.isHidden          = true
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if num_ind == "4" {
            uk_indicator.isHidden     = false
            choice_indicator.isHidden = false
            
            btnUK.isHidden            = true
            btnChoice.isHidden        = true
        } else if num_ind == "5" {
            choice_indicator.isHidden = false
            
            btnChoice.isHidden        = true
        }
    }
    
    private func stopIndicator() {
        
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
