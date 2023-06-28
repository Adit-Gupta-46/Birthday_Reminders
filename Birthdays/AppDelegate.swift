//
//  AppDelegate.swift
//  Birthdays
//
//  Created by Adit Gupta on 6/16/22.
//

import UIKit
import Contacts
import BackgroundTasks
import UserNotifications


@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    let userNotificationCenter = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        ContactCheck()
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.birthdays.backgroundAppRefreshIdentifier", using: nil) { task in
            print("[BGTASK] Perform bg fetch com.birthdays.backgroundAppRefreshIdentifier")
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
        return true
    }
    
    func handleAppRefreshTask(task: BGAppRefreshTask) {
        ContactCheck()
        scheduleBackgroundContactsFetch()
    }
    
    func scheduleBackgroundContactsFetch() {
        let contactsFetchTask = BGAppRefreshTaskRequest(identifier: "com.birthdays.backgroundAppRefreshIdentifier")
        contactsFetchTask.earliestBeginDate = Date(timeIntervalSinceNow: 5)
        print("test")
        do {
          try BGTaskScheduler.shared.submit(contactsFetchTask)
        } catch {
          print("Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    func setDefaults() {
        
    }
    
    
    func ContactCheck(){
        requestNotificationAuthorization()
        print("hhh")
        if UserDefaults.standard.object(forKey: "storedContacts") == nil {
            //storedContacts doesn't exist
            let dictionary : [String: String] = [:]
            UserDefaults.standard.set(dictionary, forKey: "storedContacts")
        }
        var ContactsInNotifications = UserDefaults.standard.object(forKey: "storedContacts") as? [String:String]
        
        let contacts = fetchContacts()
        
        let date = Date()
        let currentDate = Calendar.current.component(.day, from: date)
        let currentMonth = Calendar.current.component(.month, from: date)
        
        for contact in contacts {
            let contactMonth = (contact.birthday?.month)!
            let contactDay = (contact.birthday?.day)!
            
            // if birthday is today or yet to come and isn't already added, add it
            if ContactsInNotifications![contact.name] == nil && (contactMonth > currentMonth || (contactMonth == currentMonth && contactDay >= currentDate)){
                //add notification
                addNotification(name: contact.name, bDay: contact.birthday!)
                //Key doesn't exist
                ContactsInNotifications![contact.name] = contact.bDay
                
            }
            
            // if birthday has passed and is added. remove it
            else if ContactsInNotifications![contact.name] != nil && (contactMonth < currentMonth || (contactMonth == currentMonth && contactDay < currentDate)){
                ContactsInNotifications![contact.name] = nil
            }
        }
        
        UserDefaults.standard.set(ContactsInNotifications, forKey: "storedContacts")
    }
    
    func fetchContacts() -> Set<CNContact>{
        var contacts = Set<CNContact>()
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { (granted, error) in
            if let error = error {
                print("failed to request access", error)
                return
            }

            if granted {

                let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactBirthdayKey, CNContactThumbnailImageDataKey]
                let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
                                
                do {
                    try store.enumerateContacts(with: request, usingBlock: { (contact, stopPointer) in
                        if contact.birthday != nil {
                            contacts.insert(contact)
                        }
                    })
                } catch let error {
                    print("Failed to enumerate contact", error)
                }
            } else {
                print("access denied")
            }
        }
        return contacts
    }
    
    
    func addNotification(name: String, bDay: DateComponents){
        userNotificationCenter.delegate = self
        sendNotification(name: name, bDay: bDay)
    }

    func requestNotificationAuthorization() {
        // Auth options
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        
        userNotificationCenter.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
    }

    func sendNotification(name: String, bDay: DateComponents) {
        var triggerTime = DateComponents()
        triggerTime.day = bDay.day
        triggerTime.month = bDay.month
        triggerTime.hour = 8
        triggerTime.minute = 0
        
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "It's \(name)'s birthday!"
        notificationContent.body = "Make sure to wish them a happy birthday!"
        notificationContent.badge = NSNumber(value: 1)
        
        if let url = Bundle.main.url(forResource: "dune",
                                    withExtension: "png") {
            if let attachment = try? UNNotificationAttachment(identifier: "dune",
                                                            url: url,
                                                            options: nil) {
                notificationContent.attachments = [attachment]
            }
        }
        
        let trigger : UNNotificationTrigger
        trigger = UNCalendarNotificationTrigger(dateMatching: triggerTime, repeats: true)
        
        let request = UNNotificationRequest(identifier: name,
                                            content: notificationContent,
                                            trigger: trigger)
        
        userNotificationCenter.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
