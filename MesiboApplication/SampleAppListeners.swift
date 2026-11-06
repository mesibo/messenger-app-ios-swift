//
//  SampleAppListeners.swift
//  MesiboMessengerSwift
//
//  mesibo listeners of the app: messages (notifications), connection (sign out), groups,
//  profiles. Calls are in CallListeners. Same as MesiboListeners on Android.
//

import UIKit
import mesibo

class SampleAppListeners: NSObject, MesiboDelegate, MesiboProfileCustomizationListener {

    static let shared: SampleAppListeners = {
        let listeners = SampleAppListeners()
        Mesibo.getInstance().addListener(listeners)
        return listeners
    }()

    /** the last mesibo screen shown: 0 the chat list, 1 a chat */
    private var screen: Int32 = 0


    /**
     * A notification for a message the user can't see: not for the chat that is open, nor while
     * the chat list is on screen (it shows the message); otherwise also while the app is open.
     */
    func Mesibo_onMessage(message msg: MesiboMessage) {
        if Mesibo.getInstance().isReading(msg) || msg.isCall() {
            return
        }
        if Mesibo.getInstance().isAppInForeground() && screen == 0 {
            return
        }
        SampleAppNotify.shared.notifyMessage(msg)
    }

    /** messages of type 1 are for notifications only and are not kept (normal messages are type 0); calls are kept */
    func Mesibo_onMessageFilter(message msg: MesiboMessage) -> Bool {
        return msg.type != 1 || msg.isCall()
    }

    func Mesibo_onConnectionStatus(status: Int) {
        if status == MESIBO_STATUS_SIGNOUT {
            UIManager.alert(title: "Signed Out", message: "You have signed-in from other device and hence signed out here")
            SampleAPI.shared.logout(forced: true, parent: nil)
        } else if status == MESIBO_STATUS_AUTHFAIL {
            UIManager.alert(title: "Signed Out", message: "Login Expired. Login again to continue.")
            SampleAPI.shared.logout(forced: true, parent: nil)
        }
    }

    func Mesibo_onGroupJoined(groupProfile: MesiboProfile) {
        SampleAppNotify.shared.notify(type: SampleAppNotify.typeOther, subject: "Joined a group",
                                      message: "You have been added to the group \(groupProfile.getName() ?? "")")
    }

    func Mesibo_onGroupLeft(groupProfile: MesiboProfile) {
        SampleAppNotify.shared.notify(type: SampleAppNotify.typeOther, subject: "Left a group",
                                      message: "You left the group \(groupProfile.getName() ?? "")")
    }

    func Mesibo_onForeground(parent: Any, screenId: Int32, foreground: Bool) {
        if foreground {
            screen = screenId
        }
        // the chat list: clear message notifications
        if foreground && screenId == 0 {
            SampleAppNotify.shared.clear()
        }
    }


    // MARK: - MesiboProfileCustomizationListener

    func Mesibo_onCustomizeProfile(profile: MesiboProfile) -> Bool {
        return true
    }

    /** nil: the default (no custom picture) */
    func Mesibo_onGetProfileImage(profile: MesiboProfile) -> UIImage? {
        return nil
    }

    /** the formatted phone number for a contact without a name; nil: the default */
    func Mesibo_onGetProfileName(profile: MesiboProfile) -> String? {
        if profile.isGroup() {
            return nil
        }
        guard let address = profile.getAddress() else { return nil }
        let contact = Mesibo.getInstance().getPhoneContactsManager().getPhoneNumberInfo(address, format: true)
        return contact.formattedPhoneNumber
    }
}
