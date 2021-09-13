//
//  PushKitNotify.swift
//  MesiboMessengerSwift
//
//  Copyright © 2021 Mesibo. All rights reserved.
//

import Foundation
import PushKit

@objcMembers public class SamplePushKitNotify : NSObject, PKPushRegistryDelegate {
    private var pushRegistry: PKPushRegistry?

    static var getInstanceMyInstance: SamplePushKitNotify? = nil
    public class func getInstance() -> SamplePushKitNotify {
        if nil == getInstanceMyInstance {
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if nil == getInstanceMyInstance {
                    getInstanceMyInstance = SamplePushKitNotify()
                    getInstanceMyInstance?.initialize()
                }
            }
        }
        return getInstanceMyInstance!
    }
    
    func initialize() {
        pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
        pushRegistry?.delegate = self
        pushRegistry?.desiredPushTypes = [.voIP]
    }

    public func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        if credentials.token.count == 0 {
            print("token NULL")
            return
        }

        let data = credentials.token
        var sbuf: String = ""
        var i: Int
        for i in 0..<data.count {
            sbuf += String(format: "%02X", UInt8(data[i]))
        }

        SampleAPI.getInstance().setPushToken(sbuf)

    }

    public func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {

        Mesibo.getInstance().setPushRegistryCompletion(completion)
        Mesibo.getInstance().setAppInForeground(nil, screenId: -1, foreground: true)
    }
}
