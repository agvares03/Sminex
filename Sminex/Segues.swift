//
//  Segues.swift
//  Sminex
//
//  Created by IH0kN3m on 3/21/18.
//  Copyright © 2018 The Best. All rights reserved.
//

import Foundation

struct Segues {
    
    struct fromFirstController {
        
        static let toLoginUK        = "login_UK"
        static let toLoginActivity  = "login_activity"
        static let toAppsUserNow    = "AppsUserNow"
        static let toChooiseUk      = "choice_uk"
        static let toLogin          = "login"
        static let toAppsCons       = "AppsCons"
    }
    
    struct fromViewController {
        
        static let toForget         = "goForget"
        static let toRegister       = "goRegister"
        static let toAppsUser       = "AppsUsers"
        static let toAppsCons       = "AppsCons"
    }
    
    struct fromRegistrationSminex {
        
        static let toRegStep1       = "reg_step1"
    }
    
    struct fromRegistrationSminexSMS {
        
        static let toEnterPassword  = "enterPassword"
    }
    
    struct fromViewControllerUK {
        
        static let toChooseUKStreet = "choice_uk_street"
        static let toChooseUK       = "choice_uk"
        static let toAppsCons       = "AppsCons_uk"
        static let toAppsUser       = "AppsUsers_uk"
        
        static let toGoForget       = "goForget"
        static let toGoRegister     = "goRegistration"
        static let toGoForgetUk     = "goForget_uk"
        static let toGoRegisterUk   = "goRegistration_uk"
        static let toGoRegister2    = "goRegistration2"
        static let toGoRegister3    = "goRegistration3"
        static let toRegisterUK4    = "registration_uk4"
        static let toRegister       = "registration"
        static let toRegistrationUK = "registration_uk"
    }
    
    struct fromChooiseStreetUK {
        
        static let toRegionsStreet  = "get_regions_street"
        static let toGetStreets     = "get_streets_street"
        static let toGetCityStreets = "get_cities_street"
        static let toGetRaions     = "get_raions_street"
        static let toGetUKsStreet   = "get_uks_street"
        
        static let toLoginActivity  = "login_activity_uk"
    }
    
    struct fromChoiseUK {
        
        static let toGetRaions      = "get_raions"
        static let toGetCities      = "get_cities"
        static let toGetUKs         = "get_uks"
        static let toGetRegions     = "get_regions"
        
        static let toLoginActivity  = "login_activity_uk"
    }
    
    struct fromRegistrationAddres {
        
        static let toGetAddres      = "get_adress"
        static let toGetFlat        = "get_flat"
    }
    
    struct fromAppsCons {
        
        static let toFront           = "sw_front"
        static let toRear            = "sw_rear"
    }
    
    struct fromAppsUsers {
        
        static let toFront           = "sw_front"
        static let toRear            = "sw_rear"
    }
    
    struct fromMenuUser {
        
        static let toOrder           = "order"
        static let toEvedence        = "evedence"
        static let toOsvUser         = "OSV_User"
        static let toExit            = "exit"
        static let toSettings        = "settings"
        static let toPay             = "pay"
    }
    
    struct fromAppsConsTableView {
        
        static let toOrder           = "order"
        static let toSettings        = "settings"
        static let toExit            = "exit"
    }
    
    struct fromAppsUser {
        
        static let toAddApp          = "add_app"
        static let toShowAppsClose   = "show_app_close"
        static let toShowApp         = "show_app"
    }
    
    struct fromAppUser {
        
        static let toFiles           = "files"
    }
    
    struct fromAppsConses {
        
        static let toAddAppsCons     = "add_app_cons"
    }
    
    struct fromAppCons {
        
        static let toShowAppsCons    = "show_app_cons"
        static let toAppsConsClose   = "show_app_cons_close"
        static let toSelectCons      = "select_cons"
        static let toFiles           = "files"
    }
    
    struct fromAddAppUser {
        
        static let toSelectType      = "selectType"
        static let toSelectPriority  = "selectPriority"
    }
    
    struct fromAddAppCons {
        
        static let toSelectTypeCons  = "selectTypeCons"
        static let toSelectPriority  = "selectPriorityCons"
        static let toChoiseLs        = "chooiseLs"
    }
    
    struct fromChooiseLs {
        
        static let toSelectLs        = "selectLS"
        static let toSelectFlat      = "selectFlat"
    }
    
    struct fromRegistrationSminexEnterPassword {
        
        static let toAppCons         = "appsCons"
        static let toAppsUser        = "toAppsUser"
    }
}
