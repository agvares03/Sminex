//
//  Server.swift
//  DemoUC
//
//  Created by Роман Тузин on 17.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import Foundation

final class Server {
    
    private var responseString: String?
    
    // Адрес сервера выберем в зависимости от текущего таргета
    //    #if isGKRZS
    //    static let SERVER: String = UserDefaults.standard.string(forKey: "SiteSM") == "" ? "http://uk-gkh.org/otherUK/" : UserDefaults.standard.string(forKey: "SiteSM")!
    //    #elseif isDecember
    //        static let SERVER          = "http://uk-gkh.org/tsgoktyabrskoe/"
    //    #elseif isTeplo
    //        static let SERVER          = "http://uk-gkh.org/teploenergoservice/"
    //    #elseif isDJ
    //        static let SERVER          = "http://uk-gkh.org/dgservicnew/"
    //    #elseif isPocket
    //        static let SERVER          = "http://uk-gkh.org/otherUK/"
    //    #elseif isAlmaz
    //        static let SERVER          = "http://uk-gkh.org/almaz/"
    //    #elseif isT181
    //        static let SERVER          = "http://uk-gkh.org/tsg181/"
    //    #elseif isPSHSK17
    //        static let SERVER          = "http://uk-gkh.org/pshsk17/"
    //    #elseif isStandartDV
    //        static let SERVER          = "http://uk-gkh.org/standartdv/"
    //    #elseif isComfortService
    //        static let SERVER          = "http://uk-gkh.org/komfortservice/"
    //    #elseif isTPobeda1
    //        static let SERVER          = "http://uk-gkh.org/tsgpobeda1/"
    //    #elseif isBlagodatnaya13
    //        static let SERVER          = "http://uk-gkh.org/blagodatnaya1315/"
    //    #elseif isT270
    //        static let SERVER          = "http://uk-gkh.org/tsg270/"
    //    #elseif isTOkolitsa
    //        static let SERVER          = "http://uk-gkh.org/okolitsa/"
    //    #elseif isKomeks
    //        static let SERVER          = "http://uk-gkh.org/komeks/"
    //    #else
    //        static let SERVER          = "http://uk-gkh.org/newjkh/"
    //    #endif
    
    static let SERVER              = "http://185.11.50.170:1580/"
    
    static let REGISTRATION        = "RegisterSimple.ashx?"            // Регистрация
    static let FORGOT              = "remember.ashx?"                  // Забыли пароль
    static let ENTER               = "AutenticateUserAndroid.ashx?"    // Авторизация пользователя
    static let GET_METERS          = "GetMeterValues.ashx?"            // Получить показания по счетчикам
    static let ADD_METER           = "AddMeterValue.ashx?"             // Добавить показание по счетчику
    static let GET_APPS_COMM       = "GetRequestWithMessages.ashx?"    // Получить заявки с комментариями
    static let SEND_COMM           = "chatAddMessage.ashx?"            // Добавить комментарий по заявке
    static let SEND_COMM_CONS      = "AddConsultantMessage.ashx?"      // Добавить комментарий по заявке (консультант)
    static let ADD_APP             = "AddRequest_Android.ashx?"        // Создание заявки
    static let CLOSE_APP           = "chatCloseReq.ashx?"              // Закрытие заявки
    static let SEND_ID_GOOGLE      = "RegisterClientDevice.ashx?"      // Передача ид устройства для уведомлений
    static let GET_HOUSES          = "GetAllAccountsData.ashx"         // Получить данные о домах и квартирах
    static let GET_APP             = "LockRequest.ashx?"               // Принять заявку (консультант)
    static let OK_APP              = "PerformRequest.ashx?"            // Выполнить заявку (консультант)
    static let CLOSE_APP_CONS      = "CloseRequestConsultant.ashx?"    // Закрыть заявку (консультант)
    static let GET_CONS            = "getconsultants.ashx?"            // Получить список консультантов
    static let GET_COMM_ID         = "GetMessages.ashx?"               // Получение комментариев по одной заявке
    static let CH_CONS             = "ChangeConsultant.ashx?"          // Перевести другому консультанту
    static let DOWNLOAD_PIC        = "DownloadRequestFile.ashx?"       // Загрузить пиктограмму файла
    static let CHECK_REGISTRATION  = "CheckShowUKChoice.ashx"          // Способ регистрации и необходимость выбора УК
    static let GET_HOUSES_ONLY     = "GetHouses.ashx"                  // Получить список домов для регистрации (только дома)
    static let GET_HOUSES_FLATS    = "GetHouseData.ashx?"              // Получить список квартир по указанному дому
    
    static let GET_BILLS_SERVICES  = "GetBillServices.ashx?"           // Получить данные ОСВ (взаиморасчеты)
    
    static let SEND_MAIL           = "SendEmailMessage.ashx?"          // Отправить письмо (мне и Юрту)
    
    static let GET_DEBT            = "GetDebtByAccount.ashx?"          // Получить данные о долгах (ДомЖилСервис)
    
    static let REGISTRATION_SMINEX = "RegisterSminex.ashx?"            // Регистрация (Смайнекс)
    
    static let SOLE                = "GetPasswordSaltByUserName.ashx?" // Получение соли для хеширования
    static let COMPLETE_REG        = "CompleteRegisterSminex.ashx?"    // Проверка СМС кода при регистрации
    static let COMPLETE_REM        = "CompleteRemember.ashx?"          // Проверка СМС кода при восстановлении пароля
    static let CHANGE_PASSWRD      = "ChangePassword.ashx?"            // Изменение пароля
    
    func hexStringToUIColor(hex: String) -> UIColor {
        var cString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if (cString.count) != 6 {
            return UIColor.gray
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}
