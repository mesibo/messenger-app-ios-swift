/******************************************************************************
* By accessing or copying this work, you agree to comply with the following   *
* terms:                                                                      *
*                                                                             *
* Copyright (c) 2019-2023 mesibo                                              *
* https://mesibo.com                                                          *
* All rights reserved.                                                        *
*                                                                             *
* Redistribution is not permitted. Use of this software is subject to the     *
* conditions specified at https://mesibo.com . When using the source code,    *
* maintain the copyright notice, conditions, disclaimer, and  links to mesibo * 
* website, documentation and the source code repository.                      *
*                                                                             *
* Do not use the name of mesibo or its contributors to endorse products from  *
* this software without prior written permission.                             *
*                                                                             *
* This software is provided "as is" without warranties. mesibo and its        *
* contributors are not liable for any damages arising from its use.           *
*                                                                             *
* Documentation: https://mesibo.com/documentation/                            *
*                                                                             *
* Source Code Repository: https://github.com/mesibo/                          *
*******************************************************************************/

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
        //Mesibo.getInstance().setAppInForeground(nil, screenId: -1, foreground: true)
    }
}
