//
//  Server.swift
//  DemoUC
//
//  Created by Роман Тузин on 17.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import Foundation
import LocalAuthentication

final class Server {
    
    private var responseString: String?
    
    static let SERVER              = "http://tst.sminex.com:1580/"
//    static let SERVER              = "http://client.sminex.com:1580/"
    
    static let REGISTRATION        = "RegisterSimple.ashx?"            // Регистрация
    static let FORGOT              = "remember.ashx?"                  // Забыли пароль
    static let ENTER               = "AutenticateUserAndroid.ashx?"    // Авторизация пользователя
    static let GET_METERS          = "GetMeterValuesNew.ashx?"         // Получить показания по счетчикам
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
    static let ADD_FILE            = "AddFileToRequest.ashx?"          // Загрузка файла на сервер
    static let REQUEST_TYPE        = "GetRequestTypes.ashx?"           // Получение списка типов заявок
    static let GET_QUESTIONS       = "GetQuestions.ashx?"              // Получение списка опросов
    static let SAVE_ANSWER         = "SaveUserAnswers.ashx?"           // Сохранение ответа
    static let EDIT_ACCOUNT        = "EditAccountInfo.ashx?"           // Изменение настроек аккаунта
    static let CONFIGURE_NOTIFY    = "SetNotifySettings.ashx?"         // Изменение настроек уведомлении
    static let PROPOSALS           = "GetProposals.ashx?"              // Получение списка акции
    static let PROPOSALS_NEW       = "GetProposalsNew.ashx?"           // Получение списка акции
    static let ACCOUNT_DEBT        = "GetAccountDebt.ashx?"            // Баланс аккаунта
    static let ACCOUNT_PHONE       = "GetAccountsByPhoneNumber.ashx?"  // Получить список ЛС по номеру телефона
    static let GET_ALL_ACCOUNTS    = "GetAllAccounts.ashx?"            // Получить данные всех аккаунтов
    static let CHECK_ACCOUNT       = "CheckAccountExists.ashx?"        // Проверка нового ЛС
    static let NEW_ACCOUNT_SMS     = "AddAccountSendSMSCode.ashx?"     // Отправить СМС с кодом для нового ЛС
    static let ADD_NEW_LS          = "AddAccountToParentAccount.ashx?" // Добавить ЛС
    static let GET_BILLS           = "GetAccountBills.ashx?"           // Получение списка квитанции
    static let CALCULATIONS        = "GetAccountCalculations.ashx?"    // Получение списка взаиморасчетов
    static let PAY_ONLINE          = "PayOnline.ashx?"                 // Оплата счета
    static let GET_NEWS            = "GetNews.ashx?"                   // Получение списка новостей
    static let GET_CONTACTS        = "GetContacts.ashx?"               // Получение списка контактов
    static let SEND_MESSAGE        = "SendEmailMessage.ashx?"          // Отправка сообщения в тех. поддержку
    static let GET_BC_IMAGE        = "GetBCImage.ashx?"                // Получение фотки Бизнес центра
    static let GET_BILL_FILES      = "GetBillFiles.ashx?"              // Получение списка файлов по квитанции
    static let DOWNLOAD_FILE       = "DownloadBillFile.ashx?"          // Скачать файл по квитанции
    static let GET_SERVICES        = "GetPaidServices.ashx?"           // Получение списка услуг
    static let DELETE_CLIENT       = "DeleteClientDevice.ashx?"        // Удаление девайса из списка
    static let ADD_TECH_SUPPORT    = "AddTechSupportMail.ashx?"        // Добавление информации по письму
    static let ADD_SUPPORT_FILE    = "AddTechSupportFile.ashx?"        // Добавление файлов к письму
    
    static let GET_NOTIFICATIONS   = "GetNotifications.ashx?"          // Получить уведомления для пользователя
    static let GET_PAYS            = "GetPayments.ashx?"               // Получить информацию об оплатах
    
    
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
    
    func isValidEmail(testStr: String) -> Bool{
        let emailRegEx = "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}" + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\" + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-" + "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5" + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-" + "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21" + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])"
        
        let emailTest = NSPredicate(format:"SELF MATCHES[c] %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func machineName() -> String {
      var systemInfo = utsname()
      uname(&systemInfo)
      let machineMirror = Mirror(reflecting: systemInfo.machine)
      return machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
      }
    }
    
    func biometricType() -> String {
        let authContext = LAContext()
        if #available(iOS 11, *) {
            let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
            switch(authContext.biometryType) {
            case .none:
                return "none"
            case .touchID:
                return "touch"
            case .faceID:
                return "face"
            }
        } else {
            return "touch"
        }
    }
}


