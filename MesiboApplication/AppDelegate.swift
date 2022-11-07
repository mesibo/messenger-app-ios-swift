//
//  AppDelegate.swift
//  MesiboMessengerSwift
//
//  Copyright © 2020 Mesibo. All rights reserved.
//

import Foundation
import contactutils
import Intents
import mesibo
import MesiboUI
import MesiboCall
import MesiboUIHelper
import UIKit

@UIApplicationMain
@objc public class AppDelegate: UIResponder, UIApplicationDelegate, MesiboDelegate, MesiboUIDelegate {
    
    private var mMesiboUIHelper: MesiboUIHelper?
    private var mAppLaunchData: MesiboUiHelperConfig?
    private var imagesArraytest: [AnyHashable]?
    private var labelsArraytest: [AnyHashable]?
    private var imagesArray: [AnyHashable]?
    private var tempName: String?
    private var tempgroupid = 0
    private var temppath: String?
    private var tempstatus: String?
    private var mMUILauncher: MesiboUI?
    private var mesiboCall: MesiboCall?
    private var pushNotify: SamplePushKitNotify?
    private var thiz: AppDelegate?
    public var window: UIWindow?
    public var fileTranserHandler: SampleAppFileTransferHandler?
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        thiz = self
        
        application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        application.registerForRemoteNotifications()
        
        
        application.applicationIconBadgeNumber = 0
        
        Mesibo.getInstance().addListener(self)
        fileTranserHandler = SampleAppFileTransferHandler()
        fileTranserHandler!.initialize()
        
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        UINavigationBar.appearance().barTintColor = UIColor.getColor(PRIMARY_COLOR)
        UINavigationBar.appearance().isTranslucent = false
        
        
        var attributes: [NSAttributedString.Key : NSNumber]? = nil
        /*
        if let font = UIFont(name: "HelveticaNeue-Bold", size: 17) {
            attributes = [
                NSAttributedString.Key.underlineStyle: NSNumber(value: 1),
                NSAttributedString.Key.foregroundColor: UIColor.getColor(TITLE_TXT_COLOR),
                NSAttributedString.Key.font: font
            ]
        }*/
        
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        mMesiboUIHelper = MesiboUIHelper()
        mAppLaunchData = MesiboUiHelperConfig()
        
        
        Mesibo.getInstance().addListener(self);
        MesiboUI.setListener(self)
        
        // just to intitialize
        
        SampleAPI.getInstance().setOnLogout({ parent in
            DispatchQueue.main.async(execute: {
                if parent != nil {
                    (parent as? UIViewController)?.dismiss(animated: false)
                }
                self.launchLoginUI()
            })
        })
        
        
        // If token is not nil, BackendAPI will start Mesibo as well
        if nil != SampleAPI.getInstance().getToken() {
            launchMainUI()
        } else {
            
            // we check without handler so that welcome controller can be launched in parallel
            doLaunchWelcomeController()
        }
        
        pushNotify = SamplePushKitNotify.getInstance()
        return true
    }
    
    public func applicationWillResignActive(_ application: UIApplication) {
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
        Mesibo.getInstance().setAppInForeground(self, screenId: 0, foreground: false)
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        Mesibo.getInstance().setAppInForeground(self, screenId: 0, foreground: true)
        //[MesiboCallInstance showCallInProgress];
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
    }
    
    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // NSLog(@"My token is: %@", deviceToken);
        let deviceTokenString = deviceToken.description.replacingOccurrences(of: "<", with: "").replacingOccurrences(of: ">", with: "").replacingOccurrences(of: " ", with: "")
        //Log("the generated device token string is : %@", deviceTokenString)
        SampleAPI.getInstance().setAPNToken(deviceTokenString)
    }
    
    public func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }
    
    public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Mesibo.getInstance().didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        
    }
    
    public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //Log("Failed to get token, error: %@", error)
    }
    
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        
        let interaction = userActivity.interaction
        let startAudioCallIntent = interaction?.intent as? INStartAudioCallIntent
        let contact = startAudioCallIntent?.contacts?[0]
        let personHandle = contact?.personHandle
        let phoneNum = personHandle?.value
        //[CallManager sharedInstance].delegate = self;
        //[[CallManager sharedInstance] startCallWithPhoneNumber:phoneNum];
        //MesiboCall.getInstance().callUi(forExistingCall: nil)
        return true
    }
    
    
    func setRootController(_ controller: UIViewController?) {
        window!.rootViewController = controller
        window!.rootViewController = controller
        window!.makeKeyAndVisible()
        //[[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
    }
    
    func onLogin(_ phone: String?, code: String?, akToken: String?, caller: Any?, handler resultHandler: @escaping PhoneVerificationResultBlock) {
        
        ProgressIndicator.getInstance().addProgress(((caller) as? UIViewController)?.view)
        ProgressIndicator.getInstance().showProgress()
        let handler:SampleAPI_onResponse = { (result:Int32, response:Dictionary<AnyHashable, Any>?) -> () in
            ProgressIndicator.getInstance().hideProgress()
            
                print("\(response)")
            
            let op = response!["op"] as? String
            let resultz = response!["result"] as? String
            if (op == "login") {
                if nil != SampleAPI.getInstance().getToken() && (resultz == "OK") {
                    self.dismissAndlaunchMainUI(caller as? UIViewController)
                }
                
                if (nil != resultHandler) {
                    DispatchQueue.main.async(execute: {
                        resultHandler((resultz == "OK"))
                    })
                }
            }
        }
        
        SampleAPI.getInstance().login(phone, code: code, handler: handler)
    }
    
    func launchMesiboUI() {
        let ui = MesiboUI.getOptions()
        ui?.emptyUserListMessage = "No active conversations! Invite your family and friends to try mesibo."
        
        let mesiboController = MesiboUI.getViewController()
        var navigationController: UINavigationController? = nil
        if let mesiboController = mesiboController {
            navigationController = UINavigationController(rootViewController: mesiboController)
        }
        setRootController(navigationController)
        
        
        MesiboUIManager.setDefaultParent(navigationController)
        MesiboCall.start(with: nil, name: "mesibo", icon: nil, callKit: true)
    }
    
    func launchMainUI() {
        
        let sp = Mesibo.getInstance().getSelfProfile()
        if SampleAPI.isEmpty(sp.getName()) {
            Mesibo.getInstance().run(inThread: true, handler: {
                self.launchEditProfile()
            })
            return
        }
        
        Mesibo.getInstance().run(inThread: true, handler: {
            self.launchMesiboUI()
        })
        
        let syncedContacts = SampleAPI.getInstance().getSyncedContacts()
        
        ContactUtils.getInstance().initPhonebook(syncedContacts, onPermission: { result in
            if !result {
                //permission denied
                AppAlert.showDialogue("You have not granted contact permission. Mesibo requires contact permission so that you can communicate with your contacts. Go to phone Settings -> Mesibo to grant the necessary permissions to continue! Alternatively, you can reinstall, restart, and then grant permissions.", withTitle: "Permission Required", handler: {
                    
                    // change to something more useful depening on your requirements
                    exit(0);
                })
                return
            }
            

            
        }, onChange: {
            SampleAPI.getInstance().startContactSync()
        })
    }
    
    func dismissAndlaunchMainUI(_ previousController: UIViewController?) {
        if previousController == nil {
            launchMainUI()
            return
        }
        
        previousController?.dismiss(animated: false) {
            self.launchMainUI()
        }
        
    }
    
    func launchLoginUIAfterLoginUiCheck() {
        var loginController: UIViewController?
        
        loginController = MesiboUIHelper.startMobileVerification({ caller, phone, code, resultBlock in
            DispatchQueue.main.async(execute: {
                (caller as? UIViewController)?.resignFirstResponder()
            })
            self.onLogin(phone, code: code, akToken: nil, caller: caller, handler: resultBlock!)
        })
        
        setRootController(loginController)
        mAppLaunchData!.mBanners = nil
        
    }
    
    func launchLoginUI() {
        DispatchQueue.main.async(execute: {
            self.launchLoginUIAfterLoginUiCheck()
        })
        
    }
    
    func doLaunchWelcomeController() {
        
        var countryCode = ContactUtils.getInstance().getCountryCode()
        if countryCode < 1 {
            countryCode = 1
        }
        
        //query_mesibo_webrtc();
        
        mAppLaunchData!.mCountryCode = "\(countryCode)"
        mAppLaunchData!.mAppName = "Mesibo"
        mAppLaunchData!.mAppTag = "Messaging and Beyond"
        mAppLaunchData!.mAppUrl = "https://www.mesibo.com"
        mAppLaunchData!.mAppWriteUp = ""
        
        mAppLaunchData!.mLoginTitle = "welcome To mesibo";
        mAppLaunchData!.mLoginDesc = "Enter a valid phone number to begin";
        mAppLaunchData!.mLoginBottomDesc = "IMPORTANT: We will NOT send OTP.  Instead, you can generate OTP from the mesibo console. Sign up at https://mesibo.com/console";
        mAppLaunchData!.mOtpTitle = "Enter OTP";
        mAppLaunchData!.mOtpDesc = "Enter OTP for %@";
        mAppLaunchData!.mOtpBottomDesc = mAppLaunchData!.mLoginBottomDesc;
        
        mAppLaunchData!.mLoginTitleColor = 0xFF00868b;
        mAppLaunchData!.mLoginDescColor = 0xFF444444;
        mAppLaunchData!.mLoginBottomDescColor = 0xAAFF0000;
        
        mAppLaunchData!.mTextColor = 0xff172727
        mAppLaunchData!.mBackgroundColor = 0xffffffff
        mAppLaunchData!.mButtonBackgroundColor = 0xff00868b
        mAppLaunchData!.mButtonTextColor = 0xffffffff
        mAppLaunchData!.mSecondaryTextColor = 0xff666666
        mAppLaunchData!.mBannerTitleColor = 0xffffffff
        mAppLaunchData!.mBannerDescColor = 0xeeffffff
        
        var banners: [AnyHashable] = []
        
        var banner: WelcomeBanner? = nil
        
        banner = WelcomeBanner()
        banner?.mTitle = "Messaging in your apps"
        banner?.mDescription = "Over 79% of all apps require some form of communications. Mesibo is built from ground-up to power this!"
        banner?.mImage = UIImage(contentsOfFile: Bundle.main.path(forResource: "welcome", ofType: "png") ?? "")
        banner?.mColor = 0xff00868b //0xff0f9d58;
        if let banner = banner {
            banners.append(banner)
        }
        
        banner = WelcomeBanner()
        banner?.mTitle = "Messaging, Voice, & Video"
        banner?.mDescription = "Complete infrastructure with powerful APIs to get you started, rightaway!"
        banner?.mImage = UIImage(contentsOfFile: Bundle.main.path(forResource: "plug_play", ofType: "png") ?? "")
        banner?.mColor = 0xff0f9d58 //0xff00bcd4; //0xfff4b400;
        if let banner = banner {
            banners.append(banner)
        }
        
        mAppLaunchData!.mBanners = banners
        
        MesiboUIHelper.setUiConfig(mAppLaunchData)
        
        let welcomeController = MesiboUIHelper.getWelcomeViewController({ parent, result in
            
            self.launchLoginUI()
            parent?.dismiss(animated: false)
        })
        
        setRootController(welcomeController)
    }
    
    func launchEditProfile() {
        let storybord = UIStoryboard(name: "Main", bundle: Bundle.main)
        let editSelfProfileController = storybord.instantiateViewController(withIdentifier: "EditSelfProfileViewController") as? EditProfileController
        
        editSelfProfileController?.setLaunchMesiboCallback({
            self.launchMainUI() //don't launch mesibo ui directly
        })
        
        setRootController(editSelfProfileController)
    }
    
    public func MesiboUI_onGetMenu(parent: Any, type: Int32, profile: MesiboProfile?) -> [Any]? {
        
        var btns: [AnyHashable]? = nil
        
        if type == 0 {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "ic_message_white"), for: .normal)
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            button.tag = 0
            
            let button1 = UIButton(type: .custom)
            button1.setImage(UIImage(named: "ic_more_vert_white"), for: .normal)
            button1.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            button1.tag = 1
            
            btns = [button, button1]
        } else {
            if profile != nil && profile?.getGroupId() == 0 {
                let button = UIButton(type: .custom)
                button.setImage(UIImage(named: "ic_call_white"), for: .normal)
                button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                button.tag = 0
                
                let vbutton = UIButton(type: .custom)
                vbutton.setImage(UIImage(named: "ic_videocam_white"), for: .normal)
                vbutton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
                vbutton.tag = 1
                
                btns = [vbutton, button]
            }
        }
        
        return btns
        
    }
    
    public func MesiboUI_onMenuItemSelected(parent: Any, type: Int32, profile: MesiboProfile?, item: Int32) -> Bool {
        
        // userlist menu are active
        if type == 0 {
            // USERLIST
            if item == 1 {
                //item == 0 is reserved
                MesiboUIManager.launchSettings(parent as! UIViewController)
            }
        } else {
            // MESSAGEBOX
            if item == 0 {
                print("Menu btn from messagebox pressed")
                MesiboCall.getInstance().callUi(parent, profile: profile!, video: false)
            } else if item == 1 {
                DispatchQueue.main.async(execute: {
                    MesiboCall.getInstance().callUi(parent, profile: profile!, video: true)
                    
                })
            }
        }
        return true
    }
    
    public func MesiboUI_onShowProfile(parent: Any, profile: MesiboProfile) {
        MesiboUIManager.launchProfile(parent, profile: profile)
    }
    
    @objc func logout(fromApplication sender: UIViewController?) {
        launchLoginUI()
    }
    
}
