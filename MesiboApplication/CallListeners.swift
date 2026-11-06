//
//  CallListeners.swift
//  MesiboMessengerSwift
//
//  All call listeners of the app, same as CallListeners on Android:
//  MesiboCallIncomingListener: incoming calls (call properties), missed call notifications.
//  MesiboCallMonitorListener: calls starting and ending - updates the chat list and chats, which
//  show the call in progress button during a call (UIListener).
//

import UIKit
import mesibo
import MesiboUI
import MesiboCall

class CallListeners: NSObject, MesiboCallIncomingListener, MesiboCallMonitorListener {

    static let shared = CallListeners()

    private static var started = false

    /** starts the call library (once) with these listeners */
    static func start() {
        if started {
            return
        }
        started = true

        MesiboCall.start(with: shared, name: "mesibo", icon: nil, callKit: true)
        MesiboCall.getInstance().add(shared)
    }


    // MARK: - MesiboCallIncomingListener

    func MesiboCall_OnIncoming(profile: MesiboProfile, video: Bool, waiting: Bool) -> MesiboCallProperties? {
        return MesiboCall.getInstance().createCallProperties(video)
    }

    func MesiboCall_OnShowUserInterface(call: Any?, properties cp: MesiboCallProperties?) -> Bool {
        return false
    }

    func MesiboCall_OnError(cp: MesiboCallProperties, error: Int32) {
    }

    func MesiboCall_OnNotify(type: Int32, profile: MesiboProfile, video: Bool, ts: MesiboDateTime) -> Bool {
        if type == MESIBOCALL_NOTIFY_MISSED {
            let message = "You missed a mesibo \(video ? "video " : "")call from \(profile.getNameOrAddress())"
            SampleAppNotify.shared.notify(type: SampleAppNotify.typeOther, subject: "Mesibo Missed Call", message: message)
        }
        return true
    }


    // MARK: - MesiboCallMonitorListener

    func MesiboCall_onCallStarted(profile: MesiboProfile, incoming: Bool, video: Bool) {
        MesiboUI.updateScreens()
    }

    func MesiboCall_onCallEnded(profile: MesiboProfile, incoming: Bool, video: Bool) {
        MesiboUI.updateScreens()
    }
}
