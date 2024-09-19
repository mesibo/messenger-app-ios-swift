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
import mesibo
import MesiboUI
import MesiboCall
import MesiboUIHelper

@objcMembers public class SampleAppListeners : NSObject, MesiboDelegate {
    
    static var getInstanceMyInstance: SampleAppListeners? = nil
    
    public class func getInstance() -> SampleAppListeners {
        if nil == getInstanceMyInstance {
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if nil == getInstanceMyInstance {
                    getInstanceMyInstance = SampleAppListeners()
                    getInstanceMyInstance?.initialize()
                }
            }
        }
        return getInstanceMyInstance!
    }
    
    func initialize() {
        Mesibo.getInstance().addListener(self)
        //setup listener if you need to customize mesibo call. You need to implement
        // incomung call listener
        //MesiboCall.sharedInstance()!.setListener(self)
    }
    
    public func Mesibo_onMessage(message: MesiboMessage) {
        
        if Mesibo.getInstance().isReading(message) {
            return
        }
        
        if message.isCall() {
            return
        }
        
        
        SampleAppNotify.getInstance().notifyMessage(message)
    }
    
    public func Mesibo_onConnectionStatus(status: Int) {
        
        if (MESIBO_STATUS_SIGNOUT == status) {
            //TBD, inform user
            AppAlert.showDialogue("You have been loggeed out from this device since you loggedin from another device.", withTitle: "Logged out")
            
            SampleAPI.getInstance().logout(true, parent: nil)
        } else if (MESIBO_STATUS_AUTHFAIL == status) {
            SampleAPI.getInstance().logout(true, parent: nil)
        }
        
        if MESIBO_STATUS_ONLINE == status {
            SampleAPI.getInstance().startOnlineAction()
        }
    }
    
    public func Mesibo_onGetProfile(profile: MesiboProfile) -> Bool {
        return true
    }
    
    
    public func Mesibo_onForeground(parent: Any, screenId: Int32, foreground: Bool) {
        if foreground && 0 == screenId {
            SampleAppNotify.getInstance().clear()
        }
    }
    
}

