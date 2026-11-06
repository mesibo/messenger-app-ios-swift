//
//  SampleAppNotify.swift
//  MesiboMessengerSwift
//
//  Local notifications for messages, missed calls and group changes.
//

import UIKit
import UserNotifications
import mesibo

class SampleAppNotify {

    static let shared = SampleAppNotify()

    // both 0, same as Android
    static let typeMessage: Int32 = 0
    static let typeOther: Int32 = 0


    /** asks for permission to notify (once) */
    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in }
    }

    func notify(type: Int32, subject: String, message: String) {
        if message.isEmpty {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = subject
        content.body = message
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        content.categoryIdentifier = String(type)

        // shown after a second
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "LocalNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /** a notification for a new incoming message, unless muted or turned off in Settings */
    func notifyMessage(_ msg: MesiboMessage) {
        if !msg.isRealtimeMessage() || msg.isInOutbox() || msg.isOutgoing() {
            return
        }
        guard let profile = msg.profile else { return }

        // Settings: notifications for messages / group messages
        let enabled = msg.groupProfile != nil
            ? SampleAPI.shared.getGroupMessageNotification()
            : SampleAPI.shared.getMessageNotification()
        if !enabled || profile.isMuted() {
            return
        }

        guard var name = profile.getName() else { return }

        if let group = msg.groupProfile {
            if group.isMuted() {
                return
            }
            name = "\(name) @ \(group.getName() ?? "")"
        }

        // the text, or what kind of attachment it is
        var text = msg.message ?? ""
        if text.isEmpty {
            text = msg.title ?? ""
        }
        if text.isEmpty {
            if msg.hasImage() {
                text = "Picture"
            } else if msg.hasVideo() {
                text = "Video"
            } else if msg.hasAudio() {
                text = "Audio"
            } else if msg.hasDocument() {
                text = "Attachment"
            } else if msg.hasLocation() {
                text = "Location"
            }
        }
        if text.isEmpty {
            return
        }

        notify(type: SampleAppNotify.typeMessage, subject: name, message: text)
    }

    func clear() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
