//
//  SampleAppListeners.swift
//  MesiboMessengerSwift

//  Copyright © 2020 Mesibo. All rights reserved.
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
        Mesibo.getInstance()!.addListener(self)
        //setup listener if you need to customize mesibo call
        //MesiboCall.sharedInstance()!.setListener(self)
    }
    
    public func mesibo_(onMessage params: MesiboParams?, data: Data?) {
        
        if Mesibo.getInstance().isReading(params) {
            return
        }
        
        if data!.count == 0 {
            return
        }
        
        if params!.isCall() {
            return
        }
        
        var message: String? = nil
        if let data = data {
            message = String(data: data, encoding: .utf8)
        }
        SampleAppNotify.getInstance().notifyMessage(params, message: message)
    }
    
    public func mesibo_(onFile params: MesiboParams?, file: MesiboFileInfo?) {
       
        if Mesibo.getInstance().isReading(params) {
            return
        }
        
        SampleAppNotify.getInstance().notifyMessage(params, message: "Attachment")
        
    }
    
    public func mesibo_(onLocation params: MesiboParams?, location: MesiboLocation?) {
        
        if Mesibo.getInstance().isReading(params) {
            return
        }
        
        SampleAppNotify.getInstance().notifyMessage(params, message: "Location")
    }
    
    public func mesibo_(onActivity params: MesiboParams?, activity: Int32) {
    }
    
    public func mesibo_(onConnectionStatus status: Int32) {
        
        if MESIBO_STATUS_SIGNOUT == status {
            //TBD, inform user
            AppAlert.showDialogue("You have been loggeed out from this device since you loggedin from another device.", withTitle: "Logged out")
            
            SampleAPI.getInstance().logout(true, parent: nil)
        } else if MESIBO_STATUS_AUTHFAIL == status {
            SampleAPI.getInstance().logout(true, parent: nil)
        }
        
        if MESIBO_STATUS_ONLINE == status {
            SampleAPI.getInstance().startOnlineAction()
        }
    }
    
    public func mesibo_(onGetProfile profile: MesiboProfile?) -> Bool {
        
        if(nil == profile) { return true }
                if profile!.getGroupId() != 0 {
                    profile!.setLookedup(true)
                    return true
                }

        let addr = profile?.getAddress()
        
        if(nil == addr) { return false }
        

            let c = ContactUtils.getInstance().lookup(addr, returnCopy: false)
            if c == nil || c?.name == nil {
                return false
            }
            
            
            profile?.setOverrideName(c?.name)
            return true
    }
    
    public func mesibo_(onShowProfile parent: Any?, profile: MesiboProfile?) {
        MesiboUIManager.launchProfile(parent, profile: profile)
    }
    
    
    
    
    public func mesibo_(onForeground parent: Any!, screenId: Int32, foreground: Bool) {
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

