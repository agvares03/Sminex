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
        
        // Временно перекинем на новое окно
        static let toNewMain        = "newMain"
    }
    
    struct fromViewController {
        
        static let toForget         = "goForget"
        static let toRegister       = "goRegister"
        static let toAppsUser       = "AppsUsers"
        static let toAppsCons       = "AppsCons"
        static let toAppsDisp       = "AppsDisp"
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
        
        static let toRequestType     = "requestType"
        static let toAdmission       = "admission"
        static let toServiceUK       = "toServiceUK"
        static let toAppeal          = "toAppeal"
        static let toService         = "service"
        static let toServiceDisp     = "serviceDisp"
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
        static let toComplete        = "toComplete"
    }
    
    struct fromMainScreenVC {
        
        static let toRequest         = "Request"
        static let toSchet           = "schet"
        static let toCreateRequest   = "createRequest"
        static let toQuestions       = "questionTable"
        static let toQuestionAnim    = "questionTableAnim"
        static let toDeals           = "deals"
        static let toFinance         = "finance"
        static let toFinancePay      = "pay"
        static let toFinanceComm     = "financeComm"
        static let toFinancePayComm  = "payComm"
        static let toNews            = "news"
        static let toNewsWAnim       = "newsWAnim"
        static let toRequestAnim     = "requestAnim"
        static let toAdmission       = "admission"
        static let toService         = "service"
        static let toDealsList       = "dealsList"
    }
    
    struct fromRequestTypeVC {
        
        static let toCreateAdmission = "admission"
        static let toCreateServive   = "service"
        static let toServiceUK   = "serviceUK"
    }
    
    struct fromCreateTechService {
        
        static let toService         = "showService"
    }
    
    struct fromCreateRequest {
        
        static let toAdmission       = "admission"
    }
    
    struct fromCounterTableVC {
        
        static let toStatement       = "statement"
        static let toHistory         = "CounterHistory"
    }
    
    struct fromCounterHistoryTableVC {
        
        static let toHistory         = "history"
    }
    
    struct fromQuestionsTableVC {
        
        static let toQuestion        = "questionAnswers"
    }
    
    struct fromQuestionAnswerVC {
        
        static let toFinal           = "final"
    }
    
    struct fromAccountSettingsVC {
        
        static let toChangePassword   = "accountChangePassword"
        static let toChangeNotific    = "changeNotifications"
        static let toMain             = "toMain"
    }
    
    struct fromAccountChangePasswordVC {
        
        static let toForgot           = "forgot"
    }
    
    struct fromDealsListVC {
        
        static let toDealsDesc        = "dealsDesc"
        static let toDealsAnim        = "dealNotAnimated"
    }
    
    struct fromFinanceVC {
        
        static let toBarcode          = "barcode"
        static let toReceipts         = "receipts"
        static let toCalcs            = "calcs"
        static let toReceiptArchive   = "receiptArchive"
        static let toCalcsArchive     = "calcsArchive"
        static let toPay              = "financePay"
        static let toHistory          = "payHistory"
    }
    
    struct fromFinanceDebtArchiveVC {
        
        static let toReceipt           = "receipt"
    }
    
    struct fromFinanceCalcsArchive {
        
        static let toCalc              = "calc"
    }
    
    struct fromFinanceDebtVC {
        
        static let toBarcode           = "barcode"
        static let toPay               = "pay"
    }
    
    struct fromNewsList {
        
        static let toNews               = "newsOne"
    }
    
    struct fromFinancePayAcceptVC {
        
        static let toPay                 = "toPay"
    }
    
    struct fromMenuVC {
        
        static let toRequest         = "Request"
        static let toSchet           = "schet"
        static let toQuestions       = "questionTable"
        static let toDeals           = "deals"
        static let toNotification    = "goNotifi"
        static let toFinance         = "finance"
        static let toNews            = "news"
        static let toServicesUK      = "ukServices"
        static let toAppeal          = "appeal"
        static let toSupport         = "support"
    }
    
    struct fromContactsVc {
        
        static let toSupport         = "authSupport"
    }
    
    struct fromAccountVC {
        
        static let toSettings        = "settings"
    }
    
    struct fromServicesUKTableVC {
        
        static let toDesc            = "desc"
    }
}
