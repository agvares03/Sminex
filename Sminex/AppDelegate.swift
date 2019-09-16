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
import Firebase
import FirebaseInstanceID
import FirebaseMessaging
import YandexMobileMetrica
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        do {
            try Network.reachability = Reachability(hostname: "www.google.com")
        }
        catch {
            switch error as? Network.Error {
            case let .failedToCreateWith(hostname)?:
                print("Network error:\nFailed to create reachability object With host named:", hostname)
            case let .failedToInitializeWith(address)?:
                print("Network error:\nFailed to initialize reachability object With address:", address)
            case .failedToSetCallout?:
                print("Network error:\nFailed to set callout")
            case .failedToSetDispatchQueue?:
                print("Network error:\nFailed to set DispatchQueue")
            case .none:
                print(error)
            }
        }
        FirebaseApp.configure()
//        application.registerForRemoteNotifications()
//        requestNotificationAuthorization(application: application)
        
        self.configureNotification()
        
        Fabric.with([Crashlytics.self])

        // Инициализация AppMetrica SDK
        // Создание объекта конфигурации
        let configuration = YMMYandexMetricaConfiguration.init(apiKey: "5e18cb69-5852-4a9e-9229-c2a2b7c1bf52")
        // Реализуйте логику определения того, является ли запуск приложения первым. В качестве критерия вы можете использовать проверку наличия каких-то файлов (настроек, баз данных и др.), которые приложение создает в свой первый запуск
        // Отслеживание новых пользователей
        configuration?.handleFirstActivationAsUpdate = true
        // Отслеживание аварийной остановки приложений
        configuration?.crashReporting = true
        configuration?.statisticsSending = true
        
        YMMYandexMetrica.activate(with: configuration!)

        if let notification = launchOptions?[.remoteNotification] as? [String:AnyObject]{
            if notification["message"] != nil{
                let message = notification["message"] as? String
                let title = notification["title"] as? String
                
                let notifiType = notification["type"] as? String
                let notifiIdent = notification["ident"] as? String
                
                if (notifiType?.containsIgnoringCase(find: "question"))!{
                    //                UserDefaults.standard.set(true, forKey: "newNotifi")
                    UserDefaults.standard.set(message, forKey: "bodyNotifi")
                    UserDefaults.standard.set(title, forKey: "titleNotifi")
                    UserDefaults.standard.set(notifiType, forKey: "typeNotifi")
                    UserDefaults.standard.set(notifiIdent, forKey: "identNotifi")
                    UserDefaults.standard.set(true, forKey: "openNotification")
                    UserDefaults.standard.synchronize()
                }else{
                    //                UserDefaults.standard.set(true, forKey: "newNotifi")
                    UserDefaults.standard.set(message, forKey: "bodyNotifi")
                    UserDefaults.standard.set(title, forKey: "titleNotifi")
                    UserDefaults.standard.set(notifiType, forKey: "typeNotifi")
                    UserDefaults.standard.set(notifiIdent, forKey: "identNotifi")
                    UserDefaults.standard.set(true, forKey: "openNotification")
                    UserDefaults.standard.synchronize()
                }
            }
            if notification["gcm.notification.message"] != nil{
                let message = notification["gcm.notification.message"]! as? String
                let aps = notification["aps"] as! [String:AnyObject]
//                var body: String = ""
                var title: String = ""
                if let alert = aps["alert"] as? String {
//                    body = alert
                } else if let alert = aps["alert"] as? [String : String] {
//                    body = alert["body"]!
                    title = alert["title"]!
                }
                let notifiType = notification["gcm.notification.type"] as? String
                let notifiIdent = notification["ident"] as? String
                
                
                //                UserDefaults.standard.set(true, forKey: "newNotifi")
                UserDefaults.standard.set(message, forKey: "bodyNotifi")
                UserDefaults.standard.set(title, forKey: "titleNotifi")
                UserDefaults.standard.set(notifiType, forKey: "typeNotifi")
                UserDefaults.standard.set(notifiIdent, forKey: "identNotifi")
                UserDefaults.standard.set(true, forKey: "openNotification")
                UserDefaults.standard.synchronize()
            }
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {}
    func applicationDidEnterBackground(_ application: UIApplication) {}
    func applicationWillEnterForeground(_ application: UIApplication) {}
    func applicationDidBecomeActive(_ application: UIApplication) {}
    func applicationWillTerminate(_ application: UIApplication) {
        UserDefaults.standard.set("", forKey: "bodyNotifi")
        UserDefaults.standard.set("", forKey: "titleNotifi")
        UserDefaults.standard.set("", forKey: "typeNotifi")
        UserDefaults.standard.set("", forKey: "identNotifi")
        UserDefaults.standard.set(false, forKey: "openNotification")
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
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
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        NSLog("[RemoteNotification] applicationState: \(applicationStateString) didReceiveRemoteNotification for iOS9: \(userInfo)")
        print("---УВЕДОМЛЕНИЕ---")
//        guard (userInfo["aps"] as? [String : AnyObject]) != nil else {
//            print("Error parsing")
//            return
//        }
        if userInfo["message"] != nil{
            let message = userInfo["message"]! as? String
            let title = userInfo["title"]! as? String
            
            let notifiType = userInfo["type"] as? String
            let notifiIdent = userInfo["ident"] as? String
            
            
                //                UserDefaults.standard.set(true, forKey: "newNotifi")
            UserDefaults.standard.set(message, forKey: "bodyNotifi")
            UserDefaults.standard.set(title, forKey: "titleNotifi")
            UserDefaults.standard.set(notifiType, forKey: "typeNotifi")
            UserDefaults.standard.set(notifiIdent, forKey: "identNotifi")
            UserDefaults.standard.set(true, forKey: "openNotification")
            UserDefaults.standard.synchronize()
            
            if UIApplication.shared.applicationState == .active {
                //TODO: Handle foreground notification
                let content = UNMutableNotificationContent()
                let categoryIdentifire = "Delete Notification Type"
                
                content.title = NSString.localizedUserNotificationString(forKey: title!, arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: message!, arguments: nil)
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = categoryIdentifire
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let identifier = "Local Notification"
                let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule the notification.
                notificationCenter.add(request)
            } else {
                //TODO: Handle background notification
                let content = UNMutableNotificationContent()
                let categoryIdentifire = "Delete Notification Type"
                
                content.title = NSString.localizedUserNotificationString(forKey: title!, arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: message!, arguments: nil)
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = categoryIdentifire
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let identifier = "Local Notification"
                let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule the notification.
                notificationCenter.add(request)
            }
        }else{
            let aps = userInfo["aps"] as! [String:AnyObject]
            var body: String = ""
            var title: String = ""
            if let alert = aps["alert"] as? String {
                body = alert
            } else if let alert = aps["alert"] as? [String : String] {
                body = alert["body"]!
                title = alert["title"]!
            }
            if userInfo["gcm.notification.message"] != nil{
                let message = userInfo["gcm.notification.message"]! as? String
                
                let notifiType = userInfo["gcm.notification.type"] as? String
                let notifiIdent = userInfo["ident"] as? String
                
                
                //                UserDefaults.standard.set(true, forKey: "newNotifi")
                UserDefaults.standard.set(message, forKey: "bodyNotifi")
                UserDefaults.standard.set(title, forKey: "titleNotifi")
                UserDefaults.standard.set(notifiType, forKey: "typeNotifi")
                UserDefaults.standard.set(notifiIdent, forKey: "identNotifi")
                UserDefaults.standard.set(true, forKey: "openNotification")
                UserDefaults.standard.synchronize()
            }
            if UIApplication.shared.applicationState == .active {
                //TODO: Handle foreground notification
                let content = UNMutableNotificationContent()
                let categoryIdentifire = "Delete Notification Type"
                
                content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = categoryIdentifire
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let identifier = "Local Notification"
                let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule the notification.
                notificationCenter.add(request)
            } else {
                //TODO: Handle background notification
                let content = UNMutableNotificationContent()
                let categoryIdentifire = "Delete Notification Type"
                
                content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
                content.sound = UNNotificationSound.default()
                content.categoryIdentifier = categoryIdentifire
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let identifier = "Local Notification"
                let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule the notification.
                notificationCenter.add(request)
            }
        }
    }
    
    func applicationReceivedRemoteMessage(_ remoteMessage: MessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
    
    var applicationStateString: String {
        if UIApplication.shared.applicationState == .active {
            return "active"
        } else if UIApplication.shared.applicationState == .background {
            return "background"
        }else {
            return "inactive"
        }
    }
    
    func configureNotification() {
        if #available(iOS 10.0, *) {
            notificationCenter.delegate = self
            notificationCenter.requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
        }else{
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func requestNotificationAuthorization(application: UIApplication) {
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            notificationCenter.delegate = self
            //            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            //            UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
            notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
                (granted, error) in
                print("Permission granted: \(granted)")
                guard granted else { return }
                self.getNotificationSettings()
            }
         } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func getNotificationSettings() {
        notificationCenter.getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("TOKEN: ", token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("didFailToRegisterForRemoteNotificationsWithError")
    }
    
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    // iOS10+, called when presenting notification in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        NSLog("[UserNotificationCenter] applicationState: \(applicationStateString) willPresentNotification: \(userInfo)")
        //TODO: Handle foreground notification
//        UserDefaults.standard.set(true, forKey: "openNotification")
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
////        if let homePage = storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq") as? MainScreenVC{
//        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq") as? MainScreenVC
//        (self.window?.rootViewController as? UITabBarController)?.selectedIndex = 0
//        self.window?.makeKeyAndVisible()
//        }
        completionHandler([.alert, .badge, .sound])
    }
    
    // iOS10+, called when received response (default open, dismiss or custom action) for a notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        NSLog("[UserNotificationCenter] applicationState: \(applicationStateString) didReceiveResponse: \(userInfo)")
        UserDefaults.standard.set(true, forKey: "openNotification")
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initialView: UITabBarController = storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq") as! UITabBarController
//        if let homePage = storyboard.instantiateViewController(withIdentifier: "UITabBarController-An5-M4-dcq") as? MainScreenVC{
        if response.notification.request.identifier == "Local Notification" {
            print("Handling notifications with the Local Notification Identifier")
        }
            self.window?.rootViewController = initialView
            (self.window?.rootViewController as? UITabBarController)?.selectedIndex = 0
            self.window?.makeKeyAndVisible()
//        }
        completionHandler()
    }
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        NSLog("[RemoteNotification] didRefreshRegistrationToken: \(fcmToken)")
    }
    
    // iOS9, called when presenting notification in foreground
//    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
//        NSLog("[RemoteNotification] applicationState: \(applicationStateString) didReceiveRemoteNotification for iOS9: \(userInfo)")
//        print("---УВЕДОМЛЕНИЕ---")
//        guard let notifi = userInfo["aps"] as? [String : AnyObject] else {
//            print("Error parsing")
//            return
//        }
//        var body = ""
//        var title = ""
//        //        var msgURL = ""
//        if let alert = notifi["alert"] as? String {
//            body = alert
//        } else if let alert = notifi["alert"] as? [String : String] {
//            body = alert["body"]!
//            title = alert["title"]!
//        }
//        if userInfo["gcm.notification.type_push"] as? String == "comment"{
//            print("---isCOMMENT---")
//        }
//        print("Body:", body, "Title:", title)
//        print(body, title)
//
//        let notification = notifi["gcm.notification.type_push"] as? String
//        if (notification?.containsIgnoringCase(find: "question"))!{
//            //                UserDefaults.standard.set(true, forKey: "newNotifi")
//            UserDefaults.standard.set(body, forKey: "bodyNotifi")
//            UserDefaults.standard.set(title, forKey: "titleNotifi")
//            UserDefaults.standard.set(true, forKey: "openNotification")
//            UserDefaults.standard.synchronize()
//        }
////        if title.contains("поступил комментарий"){
////            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTheTable"), object: nil)
////        }
//        if UIApplication.shared.applicationState == .active {
//            //TODO: Handle foreground notification
//        } else {
//            //TODO: Handle background notification
//        }
//    }
}

