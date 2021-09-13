//
//  SampleAppNotify.swift
//  MesiboMessengerSwift
//
//  Copyright © 2020 Mesibo. All rights reserved.
//

import Foundation
import NotificationCenter
import UserNotificationsUI


@objcMembers public class SampleAppNotify : NSObject, UNUserNotificationCenterDelegate {
    static var getInstanceMyInstance: SampleAppNotify? = nil
    
    public class func getInstance() -> SampleAppNotify {
        if nil == getInstanceMyInstance {
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if nil == getInstanceMyInstance {
                    getInstanceMyInstance = SampleAppNotify()
                    getInstanceMyInstance?.initialize()
                }
            }
        }
        return getInstanceMyInstance!
    }
    
    func initialize() {
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { granted, error in
            // Enable or disable features based on authorization.
            //print("on Auth")
        })
        
    }
   
   
    func notify(_ type: Int, subject: String?, message: String?) {
        if (message?.count ?? 0) == 0 {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = subject ?? ""
        content.body = message ?? ""
        content.sound = UNNotificationSound.default
        //Set Badge Number
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.categoryIdentifier = "\(type)"
        
        
        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "MesiboLocalNotification", content: content, trigger: trigger)
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request, withCompletionHandler: { error in
            if let error = error {
                print("Notification Completed: \(error)")
            }
        })
        
    }
    
    func notifyMessage(_ params: MesiboParams?, message: String?) {
        if MESIBO_ORIGIN_REALTIME != params?.origin || MESIBO_MSGSTATUS_OUTBOX == params?.status {
            return
        }
        
        var name = params?.peer
        if params?.profile != nil {
            if params!.profile.isMuted() {
                return
            }
            
            name = params!.profile.getName()
        }
        
        if nil == name {
            return
        }
        
        if params!.groupProfile != nil {
            if params!.groupProfile.isMuted() {
                return
            }
            
            if let name1 = params!.groupProfile.getName() {
                name = "\(name ?? "") @ \(name1)"
            }
        }
        
        
        notify(Int(0), subject: name, message: message)
        return
        
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Info : \(notification.request.content.userInfo)")
        if (notification.request.content.categoryIdentifier == "2") {
            completionHandler([.sound, .alert, .badge])
        } else {
            completionHandler(UNNotificationPresentationOptions(rawValue: 0)) // no foreground notifications
        }
        
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func clear() {
    }
}
