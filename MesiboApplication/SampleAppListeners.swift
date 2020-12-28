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
        SampleAPI.getInstance().autoAddContact(params)
        
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
        SampleAPI.getInstance().autoAddContact(params)
        
        if Mesibo.getInstance().isReading(params) {
            return
        }
        
        SampleAppNotify.getInstance().notifyMessage(params, message: "Attachment")
        
    }
    
    public func mesibo_(onLocation params: MesiboParams?, location: MesiboLocation?) {
        SampleAPI.getInstance().autoAddContact(params)
        
        if Mesibo.getInstance().isReading(params) {
            return
        }
        
        SampleAppNotify.getInstance().notifyMessage(params, message: "Location")
    }
    
    public func mesibo_(onActivity params: MesiboParams?, activity: Int32) {
        SampleAPI.getInstance().autoAddContact(params)
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
    
    public func mesibo_(onUpdateUserProfiles profile: MesiboUserProfile?) -> Bool {
        
        if let flag = profile?.flag {
            if flag & UInt32(MESIBO_USERFLAG_DELETED) != 0 {
                
                if profile!.groupid != 0 {
                    profile!.lookedup = true
                    SampleAPI.getInstance().updateDeletedGroup(profile!.groupid)
                }
                
                return true
            }
        }
        
        if profile != nil && profile!.groupid > 0 {
            profile?.status = SampleAPI.getInstance().groupStatus(fromMembers: profile?.groupMembers)
            return true
        }
        
        if !BackendAPI.isEmpty(profile!.address) {
            let c = ContactUtils.getInstance().lookup(profile?.address, returnCopy: false)
            if c == nil || c?.name == nil {
                return false
            }
            
            if BackendAPI.equals(c?.name, old: profile?.name) {
                return false
            }
            
            profile?.name = c?.name
            return true
        }
        
        return false //group
    }
    
    public func mesibo_(onShowProfile parent: Any?, profile: MesiboUserProfile?) {
        MesiboUIManager.launchProfile(parent, profile: profile)
    }
    
    public func mesibo_(onSetGroup parent: Any!, profile: MesiboUserProfile!, type: Int32, members: [Any]!, handler: Mesibo_onSetGroupHandler!) {
        
        ProgressIndicator.getInstance().addProgress(((parent) as? UIViewController)?.view)
        ProgressIndicator.getInstance().showProgress()
        SampleAPI.getInstance().setGroup(profile, members: members, handler: { result, response in
            ProgressIndicator.getInstance().hideProgress()
            let groupid = (response?["gid"] as? NSNumber)?.uint32Value ?? 0
            handler!(groupid)
        })
    }
    
    public func mesibo_(onGetGroup parent: Any?, groupid: UInt32, handler: Mesibo_onSetGroupHandler) {
        
    }
    
    func getGroupMembers(_ members: String?) -> [AnyHashable]? {
        if BackendAPI.isEmpty(members) {
            return nil
        }
        
        let s = members!.components(separatedBy: ":") as [String]?
        if s == nil || s!.count < 2 {
            return nil
        }
        
        let users = s![1].components(separatedBy: ",") as [String]
        if users == nil || users.count == 0 {
            return nil
        }
        
        var m: [AnyHashable] = []
        
        for i in 0...users.count-1 {
            let u = Mesibo.getInstance()!.getUserProfile(users[i])
            if u == nil {
                Mesibo.getInstance()!.createProfile(users[i], groupid: 0, name: nil)
            }
            
            if let u = u {
                m.append(u)
            }
        }
        
        return m
    }
    
    public func mesibo_(onGetGroupMembers parent: Any!, groupid: UInt32) -> [Any]! {
    
        let profile = Mesibo.getInstance().getProfile(nil, groupid: groupid)
        if profile == nil {
            return nil
        }
        
        return getGroupMembers(profile?.groupMembers)
    }
    
    public func mesibo_(onMessageFilter params: MesiboParams!, direction: Int32, data: Data!) -> Bool {
        if 1 == direction {
            return true
        }
        
        // using it for notifications
        if 1 != params!.type {
            return true
        }
        
        if data!.count == 0 {
            return false
        }
        
        var jsonerror: Error? = nil
        var returnedDict: [AnyHashable : Any]? = nil
        var jsonObject: Any? = nil
        do {
            if let data = data {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            }
        } catch let jsonerror {
        }
        
        if jsonerror != nil {
            return false
        }
        
        if !(jsonObject is [AnyHashable]) {
            returnedDict = jsonObject as? [AnyHashable : Any]
        }
        
        if returnedDict == nil {
            return false
        }
        
        var subject = returnedDict!["subject"] as? String
        let phone = returnedDict!["phone"] as? String
        
        if subject != nil {
            var name = returnedDict!["name"] as? String
            var msg = returnedDict!["msg"] as? String
            if phone != nil {
                let c = ContactUtils.getInstance().lookup(phone, returnCopy: false)
                if c != nil && c!.name.count > 0 {
                    name = c!.name
                }
            }
            
            if name == nil {
                name = phone
            }
            
            if name != nil {
                subject = subject?.replacingOccurrences(of: "%NAME%", with: name ?? "")
                
                if msg != nil {
                    msg = msg?.replacingOccurrences(of: "%NAME%", with: name ?? "")
                }
            }
            
            SampleAppNotify.getInstance().notify(Int(1), subject: subject, message: msg)
        }
        
        SampleAPI.getInstance().createContact(returnedDict, serverts: Int64((Mesibo.getInstance().getTimestamp() - params!.ts) / 1000),
            selfProfile: false, refresh: true, visibility: VISIBILITY_UNCHANGED)
        
        return false
        
    }
    
    public func mesibo_(onForeground parent: Any!, screenId: Int32, foreground: Bool) {
        if foreground && 0 == screenId {
            SampleAppNotify.getInstance().clear()
        }
    }
    
    public func mesiboCall_(onNotifyIncoming type: Int32, profile: MesiboUserProfile?, video: Bool) -> Bool {
        
        var n: String? = nil
        var subj: String? = nil
        if MESIBOCALL_NOTIFY_INCOMING == type {
            subj = "Mesibo Incoming Call"
            if let name = profile?.name {
                n = String(format: "Mesibo %scall from %@", video ? "Video " : "", name)
            }
        } else if MESIBOCALL_NOTIFY_MISSED == type {
            subj = "Mesibo Missed Call"
            if let name = profile?.name {
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

