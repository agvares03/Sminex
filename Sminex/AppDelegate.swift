//
//  AppDelegate.swift
//  DemoUC
//
//  Created by Роман Тузин on 16.05.17.
//  Copyright © 2017 The Best. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
//import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import YandexMobileMetrica

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
//        if #available(iOS 10.0, *) {
//            // For iOS 10 display notification (sent via APNS)
//            UNUserNotificationCenter.current().delegate = self as! UNUserNotificationCenterDelegate
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })
//            // For iOS 10 data message (sent via FCM
//            Messaging.messaging().remoteMessageDelegate = self as! MessagingDelegate
//        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
//        }
        
        application.registerForRemoteNotifications()
        // TODO: - Uncomment this before release
        //FirebaseApp.configure()
        
        // Инициализация AppMetrica SDK
//        YMMYandexMetrica.activate(with: YMMYandexMetricaConfiguration.init(apiKey: "5e18cb69-5852-4a9e-9229-c2a2b7c1bf52")!)
//        if self === AppDelegate.self {
            // Создание объекта конфигурации
            let configuration = YMMYandexMetricaConfiguration.init(apiKey: "5e18cb69-5852-4a9e-9229-c2a2b7c1bf52")
            // Реализуйте логику определения того, является ли запуск приложения первым. В качестве критерия вы можете использовать проверку наличия каких-то файлов (настроек, баз данных и др.), которые приложение создает в свой первый запуск
            let isFirstApplicationLaunch = false
            // Отслеживание новых пользователей
            configuration?.handleFirstActivationAsUpdate = isFirstApplicationLaunch == false
            // Отслеживание аварийной остановки приложений
            configuration?.crashReporting = true
            // Инициализация AppMetrica SDK
            YMMYandexMetrica.activate(with: configuration!)
//        }
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {
        let core = CoreDataManager()
        core.saveContext()
    }

    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        YMMYandexMetrica.handleOpen(url)
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        YMMYandexMetrica.handleOpen(url)
        return true
    }
    
    // Делегат для трекинга Universal links.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL {
                YMMYandexMetrica.handleOpen(url)
            }
        }
        return true
    }
    
}

