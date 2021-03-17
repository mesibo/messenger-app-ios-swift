//
//  BackendAPI.swift
//  MesiboMessengerSwift
//
//  Copyright © 2020 Mesibo. All rights reserved.
//

import Foundation
import contactutils

import mesibo

let APNTOKEN_KEY = "apntoken"
let GOOGLE_KEY = "googlekey"
let UPLOADURL_KEY = "upload"
let DOWNLOADURL_KEY = "download"
let INVITE_KEY = "inivte"
let CC_KEY = "cc"

@objcMembers public class BackendAPI: NSObject {
    //private var mUserDefaults: UserDefaults?
    private var mToken: String?
    private var mPhone: String?
    private var mInvite: String?
    private var mCc: String?
    private var mContactTimestamp: UInt64 = 0
    private var mLogoutBlock: SampleAPI_LogoutBlock?
    private var mSyncPending = false
    private var mResetSyncedContacts = false
    private var mAutoDownload = false
    private var mDeviceType: String?
    private var mApnToken: String?
    private var mApiUrl: String?
    private var mUploadUrl: String?
    private var mDownloadUrl: String?
    private var mApnTokenType = 0
    private var mGoogleKey: String?
    private var mApnTokenSent = false
    private var mSyncStarted = false
    private var mInitPhonebook = false
    private var mAPNCompletionHandler: ((UIBackgroundFetchResult) -> Void)?
    
    static var getInstanceMyInstance: BackendAPI? = nil
    
    public class func getInstance() -> BackendAPI {
        if nil == getInstanceMyInstance {
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if nil == getInstanceMyInstance {
                    getInstanceMyInstance = BackendAPI()
                    getInstanceMyInstance?.initialize()
                }
            }
        }
        return getInstanceMyInstance!
    }
    
    /*
    public static let sharedInstance: BackendAPI = {
        let instance = BackendAPI()
        instance.initialize()
        // setup code
        return instance
    }()
 */
    
    public func isValidUrl(url: String?) -> Bool {
        return url?.hasPrefix("http://") ?? false || url?.hasPrefix("https://") ?? false
    }
    
    public func initialize() {
        
        mApnToken = nil
        mApnTokenType = 0
        mApnTokenSent = false
        mGoogleKey = nil
        mInvite = nil
        
        mApiUrl = Bundle.main.infoDictionary?["MessengerApiUrl"] as? String
        
        if nil == mApiUrl || !isValidUrl(url: mApiUrl) {
            print("************* INVALID URL - set a valid URL in MessengerApiUrl field in Info.plist ************* ")
        }
        
        
        mGoogleKey = Bundle.main.infoDictionary?["GoogleMapKey"] as?String
        
        if nil == mGoogleKey || mGoogleKey!.count < 32 {
            print("************* INVALID GOOGLE MAP KEY - set a valid Key in GoogleMapKey field in Info.plist ************* ")
        }
        
        //mUserDefaults = UserDefaults.standard
        mContactTimestamp = 0
        mToken = UserDefaults.standard.string(forKey: "token")
        //mToken = nil 
        mPhone = nil
        mCc = nil
        mSyncPending = true
        mResetSyncedContacts = false
        mSyncStarted = false
        mInitPhonebook = false
        
        mDeviceType = "\(Mesibo.getInstance().getDeviceType())"
        
        if nil != mToken && mToken!.count > 0 {
            mContactTimestamp = UInt64(UserDefaults.standard.integer(forKey: "ts"))
            startMesibo(resetProfiles: false)
        }
    }
    
    public func setOnLogout(_ logOutBlock: SampleAPI_LogoutBlock?) {
        mLogoutBlock = logOutBlock
    }
    
    public func getSavedValue(_ value: String?, key: String?) -> String? {
        if value != nil {
            Mesibo.getInstance().setKey(value, value: key)
            return value
        }
        
        return Mesibo.getInstance().readKey(key)
    }
    
    let SYNCEDCONTACTS_KEY = "syncedcontacts"
    
    public func startMesibo(resetProfiles: Bool) {
        
        
        SampleAppListeners.getInstance() // will initiallize and register listener
        // early initialize for reverse lookup
        
        let appdir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        Mesibo.getInstance().setPath(appdir)
        
        Mesibo.getInstance().setAccessToken(getToken())
        Mesibo.getInstance().setDatabase("mesibo.db", resetTables: (__uint32_t)(resetProfiles ? MESIBO_DBTABLE_PROFILES : 0)) //TBD, change this after testing
        
        if resetProfiles {
            ContactUtils.getInstance().reset()
            Mesibo.getInstance().setKey(SYNCEDCONTACTS_KEY, value: "")
        }
        
        initAutoDownload()
        
        mCc = getSavedValue(mCc, key: CC_KEY)
        
        if nil != mCc && Int(mCc! as String)! > 0 {
            ContactUtils.getInstance().setCountryCode(Int32(mCc! as String)!)
        }
        
        Mesibo.getInstance().setSecureConnection(true)
        Mesibo.getInstance().start()
        
    }
    
    public func startSync() {
        
        let lockQueue = DispatchQueue(label: "self")
        lockQueue.sync {
            if !mSyncPending {
                return
            }
            
            mSyncPending = false
        }
        
        if mResetSyncedContacts {
            ContactUtils.getInstance().reset()
            Mesibo.getInstance().setKey(SYNCEDCONTACTS_KEY, value: "")
        }
        
        getContacts(contacts: nil, hidden: false, handler: { result, response in
            //update entire table after all groups added since UI doesn't add group messages unless profile present
            if(nil != response) {
            let contacts = response!["contacts"] as? [String]
            
            if (nil != contacts && contacts!.count > 0) {
                DispatchQueue.main.async(execute: {
                    Mesibo.getInstance().setProfile(nil, refresh: true)
                })
            }
            }
            
            BackendAPI.getInstance().startContactSync()
        })
    }
    
    public func onContactsChanged() {
        mSyncPending = true
        startSync()
    }
    
    public func getSyncedContacts() -> String? {
        return Mesibo.getInstance().readKey(SYNCEDCONTACTS_KEY)
    }
    
    public func saveSyncedContacts(contacts: [AnyHashable]?) {
        let str = ContactUtils.getInstance().synced(contacts, type: CONTACTUTILS_SYNCTYPE_SYNC)
        Mesibo.getInstance().setKey(SYNCEDCONTACTS_KEY, value: str)
    }
    
    public func startContactSync() {
        
        let lockQueue = DispatchQueue(label: "self")
        lockQueue.sync {
            if mSyncStarted {
                return
            }
            
            mSyncStarted = true
        }
        
        //TBD, we need to fix contact utils to run in this thread
        // We must run in UI thread else contact change is not triggered
        Mesibo.getInstance().run(inThread: true, handler: {
            var mContacts: [String] = []
            var mDeletedContacts: [String] = []
            
            ContactUtils.getInstance().sync({ c, type in
                if c == nil {
                    return false
                }
                
                if CONTACTUTILS_SYNCTYPE_DELETE == type && c?.phoneNumber != nil {
                    let profile = Mesibo.getInstance().getProfile(c?.phoneNumber, groupid: 0)
                    if profile != nil {
                        Mesibo.getInstance().delete(profile, refresh: false, forced: false)
                    }
                    
                    if let phoneNumber = c?.phoneNumber {
                        mDeletedContacts.append(phoneNumber)
                    }
                    return true
                }
                //NSLog(@"Contact: %@", c);
                
                let selfPhone = BackendAPI.getInstance().getPhone()
                if selfPhone != nil && c?.phoneNumber != nil && (selfPhone == c?.phoneNumber) {
                    let selfarray = [c?.phoneNumber]
                    BackendAPI.getInstance().saveSyncedContacts(contacts: selfarray)
                    return true
                }
                
                if c?.phoneNumber != nil {
                    if let phoneNumber = c?.phoneNumber {
                        mContacts.append(phoneNumber)
                    }
                }
                
                if mContacts.count >= 200 || (nil == c?.phoneNumber && mContacts.count > 0) {
                    
                    if BackendAPI.getInstance().getContacts(contacts: mContacts, hidden: false, handler: nil) {
                        //TBD. crash here
                        let lockQueue = DispatchQueue(label: "self")
                        lockQueue.sync {
                            if mContacts.count > 0 {
                                mContacts.removeAll()
                            }
                        }
                    } else {
                        return false
                    }
                }
                
                if nil == c?.phoneNumber && mDeletedContacts.count > 0 {
                    BackendAPI.getInstance().deleteContacts(mDeletedContacts)
                    mDeletedContacts.removeAll()
                }
                
                return true
            })
        })
    }
    
    public func getPhone() -> String? {
        if nil != mPhone {
            return mPhone
        }
        
        let u = Mesibo.getInstance().getSelfProfile()
        if u == nil {
            //MUST not hapen
            return nil
        }
        
        mPhone = u?.address
        return mPhone
    }
    
    public func getInvite() -> String? {
        if nil != mInvite && mInvite!.count > 6 {
            return mInvite
        }
        
        mInvite = getSavedValue(nil, key: INVITE_KEY)
        return mInvite;
    }
    
    public func getToken() -> String? {
        if BackendAPI.isEmpty(mToken) {
            return nil
        }
        
        return mToken
    }
    
    public func getUrl() -> String? {
        return mApiUrl
    }
    
    public func getUploadUrl() -> String? {
        if nil != mUploadUrl && mUploadUrl!.count > 6 {
            return mUploadUrl
        }
        
        mUploadUrl = getSavedValue(nil, key: UPLOADURL_KEY)
        return mUploadUrl
    }
    
    public func getDownloadUrl() -> String? {
        if nil != mDownloadUrl && mDownloadUrl!.count > 6 {
            return mDownloadUrl
        }
        
        mDownloadUrl = getSavedValue(nil, key: DOWNLOADURL_KEY)
        return mDownloadUrl
    }
    
    public func save() {
        UserDefaults.standard.set(mToken, forKey: "token")
        UserDefaults.standard.set(NSNumber(value: mContactTimestamp), forKey: "ts")
        UserDefaults.standard.synchronize()
    }
    
    public func checkSyncFailure(request: [AnyHashable : Any]?) {
        let op = request!["op"] as? String
        if BackendAPI.equals(op, old: "getcontacts") {
            mSyncPending = true
        }
    }
    
    public func parseResponse(response: String?, request: [AnyHashable : Any]?, handler: SampleAPI_onResponse?) -> Bool {
        var returnedDict: [AnyHashable : Any]? = nil
        var op: String? = nil
        var result = SAMPLEAPP_RESULT_FAIL
        
        
        
        //MUST not happen
        if nil == response {
            return true
        }
        
        //LOGD(@"Data %@", [NSString stringWithUTF8String:(const char *)[data bytes]]);
        let data = response?.data(using: .utf8)
        var jsonObject: Any? = nil
        var jsonerror: Error? = nil
        do {
            if let data = data {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            }
        } catch let jsonerror {
        }
        
        if jsonerror != nil {
            if nil != handler {
                handler!(result, nil)
            }
            return true
        }
        
        if (jsonObject is [AnyHashable]) {
        } else {
            returnedDict = jsonObject as? [AnyHashable : Any]
        }
        
        if nil == returnedDict {
            if nil != handler {
                handler!(result, nil)
            }
            
            checkSyncFailure(request: request)
            
            return true
        }
        
        op = returnedDict!["op"] as? String
        let res = returnedDict!["result"] as? String
        if (res == "OK") {
            result = SAMPLEAPP_RESULT_OK
        } else {
            let error = returnedDict!["error"] as? String
            if (error == "AUTHFAIL") {
                result = SAMPLEAPP_RESULT_AUTHFAIL
                logout(true, parent: nil)
                return false
            }
        }
        
        let serverts: Int64 = returnedDict!["ts"] as! Int64
        
        if SAMPLEAPP_RESULT_OK != result {
            if nil != handler {
                handler!(result, returnedDict)
            }
            return false
        }
        
        let temp = returnedDict!["invite"] as? String
        if temp != nil && (temp?.count ?? 0) > 0 {
            mInvite = getSavedValue(temp, key: INVITE_KEY)
        }
        
        let urls = returnedDict!["urls"] as? [AnyHashable : Any]
        if urls != nil {
            mUploadUrl = getSavedValue(urls!["upload"] as? String, key: UPLOADURL_KEY)
            mDownloadUrl = getSavedValue(urls!["download"] as? String, key: DOWNLOADURL_KEY)
        }
        
        if (op == "login") {
            mToken = returnedDict!["token"] as? String
            mPhone = returnedDict!["phone"] as? String
            mCc = returnedDict!["cc"] as? String
            
            if !BackendAPI.isEmpty(mToken) {
                mContactTimestamp = 0
                save()
                
                mResetSyncedContacts = true
                mSyncPending = true
                ContactUtils.getInstance().setCountryCode(Int32(mCc! as String)!)
                ContactUtils.getInstance().reset()
                Mesibo.getInstance().reset()
                
                startMesibo(resetProfiles: true)
                
                createContact(returnedDict, serverts: serverts, selfProfile: true, refresh: false, visibility: Int(VISIBILITY_VISIBLE))
            }
	} else if (op == "getcontacts") {
                let contacts = returnedDict!["contacts"] as? [AnyHashable]
                
                var visibility = VISIBILITY_VISIBLE
                let h = request?["hidden"] as? String
                if h != nil && (h == "1") {
                    visibility = VISIBILITY_HIDE
                }
                
                for i in 0..<(contacts?.count ?? 0) {
                    let userDictionary = contacts?[i] as? [AnyHashable : Any]
                    
                    createContact(userDictionary, serverts: serverts, selfProfile: false, refresh: true, visibility: Int(visibility))
                }
                
                if (contacts?.count ?? 0) > 0 {
                    save()
                }
                mResetSyncedContacts = false
            }
            else if (op == "getgroup") || (op == "setgroup") {
            createContact(returnedDict, serverts: serverts, selfProfile: false, refresh: false, visibility: Int(VISIBILITY_VISIBLE))
            } else if (op == "editmembers") || (op == "setadmin") {
                let groupid = UInt32(returnedDict!["gid"] as! String)
                if groupid! > UInt32(0) {
                    let u = Mesibo.getInstance().getGroupProfile(groupid!)
                    if u != nil {
                        u?.groupMembers = returnedDict!["members"] as? String
                        u?.status = groupStatus(fromMembers: u?.groupMembers)
                        Mesibo.getInstance().setProfile(u, refresh: false)
                    }
                }
            } else if (op == "delgroup") {
                let groupid = UInt32(returnedDict!["gid"] as! String)
                updateDeletedGroup(groupid!)
            } else if (op == "upload") {
                let profile = Int(returnedDict!["profile"] as! String)
                if profile != 0 {
                    createContact(returnedDict, serverts: serverts, selfProfile: true, refresh: false, visibility: Int(VISIBILITY_VISIBLE))
                }
            }
            
            if handler != nil {
                handler!(result, returnedDict!)
            }
            
            return true
        }
        //
        
        func invokeApi(post: [AnyHashable : Any]?, filePath: String?, handler: SampleAPI_onResponse?) {
            var post = post
            
            if post != nil {
                post?["dt"] = mDeviceType
            }
            
            let progressHandler = { (http: MesiboHttp?, state: Int32, progress: Int32) -> Bool in
                
                if 100 == progress && state == MESIBO_HTTPSTATE_DOWNLOAD {
                    BackendAPI.getInstance().parseResponse(response: http!.getDataString(), request: post, handler: handler)
                }
                
                if progress < 0 {
                    print("invokeAPI failed")
                    BackendAPI.getInstance().checkSyncFailure(request: post)
                    // 100 % progress will be handled by parseResponse
                    if nil != handler {
                        handler!(SAMPLEAPP_RESULT_FAIL, nil)
                    }
                }
                
                
                return true
                
                } as Mesibo_onHTTPProgress
            
            let http = MesiboHttp()
            http.url = getUrl()
            http.postBundle = post
            http.uploadFile = filePath
            http.uploadFileField = "photo"
            http.listener = progressHandler
            
            if !http.execute() {
            }
            
        }
        
        public class func equals(_ s: String?, old: String?) -> Bool {
            let sempty = s?.count ?? 0
            let dempty = old?.count ?? 0
            if sempty != dempty {
                return false
            }
            if sempty == 0 {
                return true
            }
            
            return s?.caseInsensitiveCompare(old ?? "") == .orderedSame
        }
        
        public class func isEmpty(_ string: String?) -> Bool {
            if nil == string || 0 == (string?.count ?? 0) {
                return true
            }
            return false
        }
        
        public func phoneBookLookup(_ phone: String?) -> String? {
            let c = ContactUtils.getInstance().lookup(phone, returnCopy: false)
            if c == nil {
                return nil
            }
            
            return c?.name
        }
        
        public func updateDeletedGroup(_ groupid: UInt32) {
            if groupid == 0 {
                return
            }
            
            let u = Mesibo.getInstance().getGroupProfile(groupid)
            if u == nil {
                return
            }
            u?.flag |= UInt32(MESIBO_USERFLAG_DELETED)
            u?.status = "Not a group member"
            Mesibo.getInstance().setProfile(u, refresh: false)
        }
        
        //TBD, this should be generated dynamically
        func groupStatus(fromMembers members: String?) -> String? {
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
            
            var status = ""
            
            for i in 0...users.count-1 {
                if !BackendAPI.isEmpty(status) {
                    status = status + (", ")
                }
                
                let p = getPhone()
                if p != "" && (p == users[i]) {
                    status = status + ("You")
                } else {
                    let u = Mesibo.getInstance().getUserProfile(users[i])
                    if u != nil {
                        Mesibo.getInstance().lookupProfile(u, source: 2)
                    }
                    
                    if u != nil && u?.name != nil {
                        status = status + (u?.name ?? "")
                    } else {
                        status = status + (users[i] )
                    }
                }
                
                if status.count > 32 {
                    break
                }
            }
            
            return status
        }
        
        public func createContact(_ response: [AnyHashable : Any]?, serverts: Int64, selfProfile: Bool, refresh: Bool, visibility: Int) {
            let name = response!["name"] as! String
            var phone = response!["phone"] as! String?
            let status = response!["status"] as! String?
            var photo = response!["photo"] as! String?
            let members = response!["members"] as! String?
            
            if photo == nil {
                photo = ""
            }
            
            var groupid: UInt32 = 0
            if !selfProfile {
                groupid = UInt32(response!["gid"] as! String)!
                if groupid != 0 {
                    phone = ""
                }
            }
            
            if BackendAPI.isEmpty(phone) && 0 == groupid {
                return
            }
            
            var timestamp: Int64 = 0;
            let t = response!["ts"] {
                timestamp = response!["ts"] as! Int64
            }
            if !selfProfile && timestamp > mContactTimestamp {
                mContactTimestamp = UInt64(timestamp)
            }
            
            
            let tn: String? = response!["tn"] as? String
            
            createContact(name, phone: phone, groupid: groupid, status: status, members: members, photo: photo, tnbase64: tn, ts: UInt64(timestamp), when: serverts - timestamp, selfProfile: selfProfile, refresh: refresh, visibility: visibility)
        }
        
        public func createContact(_ name: String?, phone: String?, groupid: UInt32, status: String?, members: String?, photo: String?, tnbase64: String?, ts: UInt64, when: Int64, selfProfile: Bool, refresh: Bool, visibility: Int) {
            var groupid = groupid
            
            let u = MesiboUserProfile()
            u.address = phone
            u.groupid = groupid
            if selfProfile {
                u.groupid = 0
                groupid = 0
            }
            
            if !selfProfile && 0 == u.groupid {
                u.name = phoneBookLookup(phone)
            }
            
            if BackendAPI.isEmpty(u.name) {
                u.name = name
            }
            
            if BackendAPI.isEmpty(u.name) {
                u.name = phone
                if BackendAPI.isEmpty(u.name) {
                    u.name = "Group-\(groupid)"
                }
            }
            
            if 0 == u.groupid && !BackendAPI.isEmpty(phone) && (phone == "0") {
                //debug
                u.name = "Hello - debug"
                return
            }
            u.status = status
            if u.groupid > 0 {
                u.groupMembers = members
                let phone = getPhone()
                if phone == nil {
                    return
                }
                if !(members?.contains(phone ?? "") ?? false) {
                    updateDeletedGroup(groupid)
                    return
                }
                u.status = groupStatus(fromMembers: members)
            }
            
            if nil == u.status {
                u.status = ""
            }
            
            u.picturePath = photo
            u.timestamp = ts
            if !selfProfile && ts > 0 && u.timestamp > mContactTimestamp {
                mContactTimestamp = u.timestamp
            }
            
            if when >= 0 {
                u.lastActiveTime = Mesibo.getInstance().getTimestamp() - UInt64(when * 100)
            }
            
            if (tnbase64?.count ?? 0) > 3 {
                let tnData = Data(base64Encoded: tnbase64 ?? "", options: [])
                if tnData != nil && (tnData?.count ?? 0) > 100 {
                    let imagePath = Mesibo.getInstance().getFilePath(MESIBO_FILETYPE_PROFILETHUMBNAIL)
                    if Mesibo.getInstance().createFile(imagePath, fileName: u.picturePath, data: tnData, overwrite: true) {
                    }
                }
            }
            
            if VISIBILITY_HIDE == visibility {
                u.flag |= UInt32(MESIBO_USERFLAG_HIDDEN)
            } else if VISIBILITY_UNCHANGED == visibility {
                let tp = Mesibo.getInstance().getProfile(u.address, groupid: u.groupid)
                if let flag = tp?.flag {
                    if tp != nil && (flag & UInt32(MESIBO_USERFLAG_HIDDEN)) != 0 {
                        u.flag |= UInt32(MESIBO_USERFLAG_HIDDEN)
                    }
                }
            }
            if selfProfile {
                mPhone = u.address
                Mesibo.getInstance().setSelfProfile(u)
            } else {
                Mesibo.getInstance().setProfile(u, refresh: refresh)
            }
            
        }
        
        func startLogout(_ handler: SampleAPI_onResponse?) {
            if nil == mToken {
                return
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "logout"
            
            post["token"] = mToken
            
            invokeApi(post: post, filePath: nil, handler: handler)
            return
        }
        
        func logout(_ forced: Bool, parent: Any?) {
            if !forced {
                startLogout({ result, response in
                    if MESIBO_RESULT_OK == result {
                        BackendAPI.getInstance().logout(true, parent: parent)
                    }
                })
                return
            }
            
            Mesibo.getInstance().setKey(APNTOKEN_KEY, value: "")
            Mesibo.getInstance().stop()
            mApnTokenSent = false
            mToken = ""
            mPhone = nil
            mCc = nil
            mContactTimestamp = 0
            save()
            Mesibo.getInstance().reset()
            
            if nil != mLogoutBlock {
                mLogoutBlock!(parent!)
            }
            
        }
        
        func login(_ phone: String?, code: String?, handler: SampleAPI_onResponse?) {
            var post: [AnyHashable : Any] = [:]
            post["op"] = "login"
            post["phone"] = phone
            if nil != code {
                post["code"] = code
            }
            
            let packageName = Bundle.main.bundleIdentifier
            post["appid"] = packageName
            
            invokeApi(post: post, filePath: nil, handler: handler)
        }
        
        func setProfile(_ name: String?, status: String?, groupid: UInt32, handler: SampleAPI_onResponse?) -> Bool {
            if nil == mToken || mToken!.count == 0 {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "profile"
            post["token"] = mToken
            post["name"] = name
            post["status"] = status
            post["gid"] = NSNumber(value: groupid).stringValue
            
            invokeApi(post: post, filePath: nil, handler: handler)
            return true
        }
        
        public func setProfilePicture(_ filePath: String?, groupid: UInt32, handler: SampleAPI_onResponse?) -> Bool {
            var filePath = filePath
            if nil == mToken || mToken!.count == 0 {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "upload"
            post["token"] = mToken
            post["mid"] = NSNumber(value: 0).stringValue
            post["profile"] = NSNumber(value: 1).stringValue
            post["gid"] = NSNumber(value: groupid).stringValue
            
            if BackendAPI.isEmpty(filePath) {
                filePath = nil
                post["delete"] = NSNumber(value: 1).stringValue
            }
            
            invokeApi(post: post, filePath: filePath, handler: handler)
            return true
        }
        
        func fetch(_ post: [AnyHashable : Any]?, filePath: String?) -> String? {
            let http = MesiboHttp()
            http.url = getUrl()
            http.postBundle = post
            http.uploadFile = filePath
            http.uploadFileField = "photo"
            
            if http.executeAndWait() {
                return http.getDataString()
            }
            
            return nil
        }
        
        public func getContacts(contacts: [String]?, hidden: Bool, handler:  SampleAPI_onResponse?) -> Bool {
            var post: [AnyHashable : Any] = [:]
            post["op"] = "getcontacts"
            post["token"] = mToken
            
            if hidden && (contacts == nil || contacts?.count == 0) {
                return false
            }
            
            post["hidden"] = hidden ? "1" : "0"
            
            if !hidden && mResetSyncedContacts {
                post["reset"] = "1"
                mContactTimestamp = 0
            }
            
            post["ts"] = NSNumber(value: mContactTimestamp)
            if contacts != nil && (contacts?.count ?? 0) > 0 {
                let string = contacts?.joined(separator: ",")
                post["phones"] = string
            }
            if handler != nil {
                invokeApi(post: post, filePath: nil, handler: handler)
            } else {
                let response = fetch(post, filePath: nil)
                if response == nil {
                    //TBD, if response nil due to network error, we must retry later
                    return false
                }
                
                let rv = parseResponse(response: response, request: post, handler: handler)
                if contacts != nil && rv {
                    saveSyncedContacts(contacts: contacts)
                }
                
                return rv
            }
            return true
        }
        
        public func deleteContacts(_ contacts: [String]?) -> Bool {
            var post: [AnyHashable : Any] = [:]
            post["op"] = "delcontacts"
            post["token"] = mToken
            
            if contacts != nil && (contacts?.count ?? 0) > 0 {
                let string = contacts?.joined(separator: ",")
                post["phones"] = string
            }
            
            let response = fetch(post, filePath: nil)
            if response == "" {
                return false
            }
            
            let rv = parseResponse(response: response, request: post, handler: nil)
            if contacts != nil && rv {
                
                ContactUtils.getInstance().synced(contacts, type: CONTACTUTILS_SYNCTYPE_DELETE)
            }
            
            return rv
        }
        
        public func setGroup(_ profile: MesiboUserProfile?, members: [String]?, handler: SampleAPI_onResponse?) -> Bool {
            if nil == mToken {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "setgroup"
            post["token"] = mToken
            
            if profile?.groupid != nil {
                post["gid"] = String(describing: profile?.groupid)
            }
            
            if profile?.name != nil {
                post["name"] = profile?.name
            }
            if profile?.status != nil {
                post["status"] = profile?.status
            }
            
            if members != nil && (members?.count ?? 0) > 0 {
                let string = members?.joined(separator: ",")
                post["m"] = string
            }
            
            invokeApi(post: post, filePath: profile?.picturePath, handler: handler)
            
            return true
        }
        
        public func deleteGroup(_ groupid: UInt32, handler: SampleAPI_onResponse?) -> Bool {
            if nil == mToken || 0 == groupid {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "delgroup"
            post["token"] = mToken
            post["gid"] = NSNumber(value: groupid).stringValue
            
            invokeApi(post: post, filePath: nil, handler: handler)
            return true
        }
        
        public func getGroup(_ groupid: UInt32, handler: SampleAPI_onResponse?) -> Bool {
            if nil == mToken || 0 == groupid {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "getgroup"
            post["token"] = mToken
            post["gid"] = NSNumber(value: groupid).stringValue
            
            invokeApi(post: post, filePath: nil, handler: handler)
            return true
        }
        
        public func editMemebers(_ groupid: UInt32, removegroup remove: Bool, members: [String]?, handler: SampleAPI_onResponse?) -> Bool {
            if nil == mToken || 0 == groupid || nil == members {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "editmembers"
            post["token"] = mToken
            post["gid"] = NSNumber(value: groupid).stringValue
            post["delete"] = NSNumber(value: remove ? 1 : 0).stringValue
            
            if (members?.count ?? 0) > 0 {
                let string = members?.joined(separator: ",")
                post["m"] = string
            }
            
            invokeApi(post: post, filePath: nil, handler: handler)
            
            return true
        }
        
        public func setAdmin(_ groupid: UInt32, members: String?, admin: Bool, handler: SampleAPI_onResponse?) -> Bool {
            if nil == mToken || 0 == groupid || nil == members {
                return false
            }
            
            var post: [AnyHashable : Any] = [:]
            post["op"] = "setadmin"
            post["token"] = mToken
            post["gid"] = NSNumber(value: groupid).stringValue
            post["admin"] = NSNumber(value: admin ? 1 : 0).stringValue
            post["m"] = members
            
            invokeApi(post: post, filePath: nil, handler: handler)
            
            return true
        }
        
        func sendAPNToken() {
            //first check in non-synronized stage. If this is called in response to sendAPNToken request itself, mApnTokenSent will be set and it will return so it can't go recursive
            if nil == mApnToken || mApnTokenSent {
                return
            }
            
            if nil == mToken || mToken!.count == 0 {
                return
            }
            
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if mApnTokenSent {
                    return
                }
                mApnTokenSent = true // so that next time it will not be called
            }
            
            Mesibo.getInstance()?.setPushToken(mApnToken, voip: false)
        }
        
        public func addContacts(_ profiles: [AnyHashable]?, hidden: Bool) {
            var addresses: [String] = []
            
            for i in 0..<(profiles?.count ?? 0) {
                let profile = profiles?[i] as? MesiboUserProfile
                if let flag = profile?.flag {
                    if profile?.address != nil && (flag & UInt32(MESIBO_USERFLAG_TEMPORARY)) != 0 && (flag & UInt32(MESIBO_USERFLAG_PROFILEREQUESTED)) == 0 {
                        profile?.flag |= UInt32(MESIBO_USERFLAG_PROFILEREQUESTED)
                        if let address = profile?.address {
                            addresses.append(address)
                        }
                    }
                }
            }
            
            if addresses.count == 0 {
                return
            }
            
            getContacts(contacts: addresses, hidden: hidden, handler: { result, response in
                
            })
            
        }
        
        public func autoAddContact(_ params: MesiboParams?) {
            if MESIBO_MSGSTATUS_OUTBOX == params?.status {
                return
            }
            
            if let flag = params?.profile.flag {
                if 0 == (flag & UInt32(MESIBO_USERFLAG_TEMPORARY)) || (flag & UInt32(MESIBO_USERFLAG_PROFILEREQUESTED)) != 0 {
                    return
                }
            }
            
            let profile = params?.profile
            var profiles: [AnyHashable] = []
            if let profile = profile {
                profiles.append(profile)
            }
            addContacts(profiles, hidden: true)
        }
        
        public func setAPNToken(_ token: String?) {
            return // We are disabling sending APN token, instead we sending Push token
                // TBD. later send both
                
                mApnToken = token
            mApnTokenType = 0
            sendAPNToken()
        }
        
        public func setPushToken(_ token: String?) {
            mApnToken = token
            mApnTokenType = 1
            sendAPNToken()
        }
        
        func executeAPNCompletion(delayInSeconds: Double) {
            if mAPNCompletionHandler == nil {
                return
            }
            
            if delayInSeconds < 0.01 {
                let lockQueue = DispatchQueue(label: "self")
                lockQueue.sync {
                    if nil != mAPNCompletionHandler! {
                        mAPNCompletionHandler!(UIBackgroundFetchResult.newData)
                    }
                    mAPNCompletionHandler = nil
                }
                return
            }
            
            let popTime = DispatchTime.now() + Double(delayInSeconds * Double(NSEC_PER_SEC))
            DispatchQueue.main.asyncAfter(deadline: popTime, execute: {
                BackendAPI.getInstance().executeAPNCompletion(delayInSeconds: 0)
            })
            
        }
        
        func setAPNCompletionHandler(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
            executeAPNCompletion(delayInSeconds: 0)
            
            mAPNCompletionHandler = completionHandler
            Mesibo.getInstance().setAppInForeground(nil, screenId: -1, foreground: true)
            executeAPNCompletion(delayInSeconds: 10.0)
            return true
        }
        
        func startOnlineAction() {
            sendAPNToken()
            executeAPNCompletion(delayInSeconds: 3.0)
        }
        
        func resetDB() {
            Mesibo.getInstance().resetDatabase(UInt32(MESIBO_DBTABLE_MESSAGES|MESIBO_DBTABLE_PROFILES|MESIBO_DBTABLE_KEYS))
        }
        
        let AUTODOWNLOAD_KEY = "autodownload"
        
        public func initAutoDownload() {
            let autodownload = Mesibo.getInstance().readKey(AUTODOWNLOAD_KEY)
            mAutoDownload = autodownload == "" || (autodownload == "1")
        }
        
        public func setMediaAutoDownload(_ autoDownload: Bool) {
            mAutoDownload = autoDownload
            Mesibo.getInstance().setKey(AUTODOWNLOAD_KEY, value: mAutoDownload ? "1" : "0")
        }
        
        public func getMediaAutoDownload() -> Bool {
            return mAutoDownload
        }
        
        public func isAppStoreBuild() -> Bool {
            #if TARGET_OS_SIMULATOR
            return false
            #endif
            
            // MobilePovision profiles are a clear indicator for Ad-Hoc distribution
            if localVerson() {
                return false
            }
            
            return isAppStoreVersion()
        }
        
        public func isAppStoreVersion() -> Bool {
            #if TARGET_OS_SIMULATOR
            return false
            #endif
            
            //let appStoreReceiptURL = Bundle.main.appStoreReceiptURL
            guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
                return false
            }
            let appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent
            let isSandboxReceipt = appStoreReceiptLastComponent == "sandboxReceipt"
            
            if isSandboxReceipt {
                return false
            }
            
            return true
            
        }
        
        public func localVerson() -> Bool {
            let profilePath: String? = Bundle.main.path(forResource: "embedded",
            ofType: "mobileprovision")
            
            return (nil != profilePath && profilePath!.count > 0)
        }
}




