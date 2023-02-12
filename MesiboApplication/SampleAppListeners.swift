//
//  SampleAppListeners.swift
//  MesiboMessengerSwift

//  Copyright © 2023 Mesibo. All rights reserved.
//

import Foundation
import contactutils
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
        //setup listener if you need to customize mesibo call
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
        
        if profile.getGroupId() != 0 {
            profile.setLookedup(true)
            return true
        }
        
        let addr = profile.getAddress()
        
        if(nil == addr) { return false }
        
        
        let c = ContactUtils.getInstance().lookup(addr, returnCopy: false)
        if c == nil || c?.name == nil {
            return false
        }
        
        profile.setOverrideName(c!.name!)
        return true
    }
    
    
    public func Mesibo_onForeground(parent: Any, screenId: Int32, foreground: Bool) {
        if foreground && 0 == screenId {
            SampleAppNotify.getInstance().clear()
        }
    }
    
        
    public func mesiboCall_(onNotifyIncoming type: Int32, profile: MesiboProfile?, video: Bool) -> Bool {
        
        var n: String? = nil
        var subj: String? = nil
        if MESIBOCALL_NOTIFY_INCOMING == type {
            subj = "Mesibo Incoming Call"
            if let name = profile?.getName() {
                n = String(format: "Mesibo %scall from %@", video ? "Video " : "", name)
            }
        } else if MESIBOCALL_NOTIFY_MISSED == type {
            subj = "Mesibo Missed Call"
            if let name = profile?.getName() {
                n = String(format: "You missed a Mesibo %scall from %@", video ? "Video " : "", name)
            }
        }
        
        if n != nil {
            Mesibo.getInstance().run(inThread: true, handler: {
                SampleAppNotify.getInstance().notify(2, subject: subj, message: n)
            })
        }
        
        return true
    }
    
}

