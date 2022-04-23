//
//  SampleAPI.swift
//  MesiboMessengerSwift
//
//  Copyright © 2021 Mesibo. All rights reserved.
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


@objcMembers public class SampleAPI: NSObject {
    //private var mUserDefaults: UserDefaults?
    private var mToken: String?
    private var mPhone: String?
    private var mInvite: String?
    private var mContactTimestamp: UInt64 = 0
    private var mLogoutBlock: SampleAPI_LogoutBlock?
    private var mResetSyncedContacts = false
    private var mAutoDownload = false
    private var mDeviceType: String?
    private var mApnToken: String?
    private var mApiUrl: String?
    private var mUploadUrl: String?
    private var mDownloadUrl: String?
    private var mApnTokenType = 0
    private var mApnTokenSent = false
    private var mSyncStarted = false
    private var mInitPhonebook = false
    private var mAPNCompletionHandler: ((UIBackgroundFetchResult) -> Void)?
    
    static var getInstanceMyInstance: SampleAPI? = nil
    
    @objc public class func getInstance() -> SampleAPI {
        if nil == getInstanceMyInstance {
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if nil == getInstanceMyInstance {
                    getInstanceMyInstance = SampleAPI()
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
        mInvite = nil
        
        mApiUrl = Bundle.main.infoDictionary?["MessengerApiUrl"] as? String
        
        if nil == mApiUrl || !isValidUrl(url: mApiUrl) {
            print("************* INVALID URL - set a valid URL in MessengerApiUrl field in Info.plist ************* ")
        }
        
        
        //mUserDefaults = UserDefaults.standard
        mContactTimestamp = 0
        mToken = UserDefaults.standard.string(forKey: "token")
        //mToken = nil 
        mPhone = nil
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
        
        initAutoDownload()
        
        Mesibo.getInstance().setSecureConnection(true)
        // Uncomment to enable end-to-end encryption
        //Mesibo.getInstance()?.e2ee()?.enable(true)
        Mesibo.getInstance().start()
        
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
        
        if mResetSyncedContacts {
            ContactUtils.getInstance().reset()
            Mesibo.getInstance().setKey(SYNCEDCONTACTS_KEY, value: "")
        }
        
        let phone = getPhone()
        let cc = Mesibo.getInstance()?.getCountryCode(fromPhone: phone)
        ContactUtils.getInstance()?.setCountryCode(cc!)
        
        //TBD, we need to fix contact utils to run in this thread
        // We must run in UI thread else contact change is not triggered
        Mesibo.getInstance().run(inThread: true, handler: {
            var mContacts: [String] = []
            var mDeletedContacts: [String] = []
            
            ContactUtils.getInstance().sync({ c, type in
                if c == nil {
                    return false
                }
                
                if CONTACTUTILS_SYNCTYPE_DELETE == type {
                    if(c?.phoneNumber == nil) { return true }
                    let profile = Mesibo.getInstance().getProfile(c?.phoneNumber, groupid: 0)
                    if profile != nil {
                        profile?.setContact(false, visiblity: 0)
                        profile?.save()
                    }
                    
                    if let phoneNumber = c?.phoneNumber {
                        mDeletedContacts.append(phoneNumber)
                    }
                    return true
                }
                //NSLog(@"Contact: %@", c);
                
                let selfPhone = SampleAPI.getInstance().getPhone()
                if selfPhone != nil && c?.phoneNumber != nil && (selfPhone == c?.phoneNumber) {
                    let selfarray = [c?.phoneNumber]
                    return true
                }
                
                if c?.phoneNumber != nil {
                    if let phoneNumber = c?.phoneNumber {
                        mContacts.append(phoneNumber)
                    }
                }
                
                if mContacts.count >= 100 || (nil == c?.phoneNumber && mContacts.count > 0) {
                    
                    if mContacts.count > 0 {
                        Mesibo.getInstance()?.syncContacts(mContacts, addContact: true, subscribe: true, visibility: 0, syncNow: false)
                        self.saveSyncedContacts(contacts: mContacts)
                        mContacts.removeAll()
                    }
                    
                }
                
                if nil == c?.phoneNumber {
                    if mDeletedContacts.count > 0 {
                        Mesibo.getInstance()?.syncContacts(mDeletedContacts, addContact: false, subscribe: true, visibility: 0, syncNow: false)
                        ContactUtils.getInstance().synced(mDeletedContacts, type: CONTACTUTILS_SYNCTYPE_DELETE)
                        mDeletedContacts.removeAll()
                    }
                    
                    Mesibo.getInstance()?.syncContacts()
                    self.mSyncStarted = false
                }
                
                return true
            })
        })
    }
    
    public func getPhone() -> String? {
        if nil != mPhone {
            return mPhone
        }
        
        mPhone = Mesibo.getInstance()?.getAddress()
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
        if SampleAPI.isEmpty(mToken) {
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
        
        //let serverts: Int64 = returnedDict!["ts"] as? Int64 ?? 0
        
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
            
            if !SampleAPI.isEmpty(mToken) {
                mContactTimestamp = 0
                save()
                
                mResetSyncedContacts = true
                mSyncStarted = false
                ContactUtils.getInstance().reset()
                Mesibo.getInstance().reset()
                
                startMesibo(resetProfiles: true)
                
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
                SampleAPI.getInstance().parseResponse(response: http!.getDataString(), request: post, handler: handler)
            }
            
            if progress < 0 {
                print("invokeAPI failed")
                // 100 % progress will be handled by parseResponse
                if nil != handler {
                    handler!(SAMPLEAPP_RESULT_FAIL, nil)
                }
            }
            
            
            return true
            
        } as Mesibo_onHTTPProgress
        
        let http = MesiboHttp()
        let json : Data
        do {
         json = try JSONSerialization.data(withJSONObject: post)
        } catch {
            return
        }
        
        http.url = getUrl()
        http.post = json
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
                    SampleAPI.getInstance().logout(true, parent: parent)
                }
            })
            return
        }
        
        Mesibo.getInstance().setKey(APNTOKEN_KEY, value: "")
        Mesibo.getInstance().stop()
        mApnTokenSent = false
        mToken = ""
        mPhone = nil
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
            post["otp"] = code
        }
        
        let packageName = Bundle.main.bundleIdentifier
        post["appid"] = packageName
        
        invokeApi(post: post, filePath: nil, handler: handler)
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
            SampleAPI.getInstance().executeAPNCompletion(delayInSeconds: 0)
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
    
    @objc public func getMediaAutoDownload() -> Bool {
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




