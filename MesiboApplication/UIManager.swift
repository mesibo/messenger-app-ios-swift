//
//  UIManager.swift
//  MesiboMessengerSwift
//
//  The app's screens and navigation: welcome and login (MesiboUIHelper), the new user's profile,
//  the chat list (MesiboUI), settings; the theme setting and alerts. Same as UIManager on
//  Android.
//

import UIKit
import mesibo
import MesiboUI
import MesiboUIHelper

class UIManager: NSObject, MesiboLoginUiHelperListener, MesiboEditProfileListener {

    static let shared = UIManager()

    private let brandColor: UInt32 = 0xff00868b
    private static let themeKey = "theme"

    private var window: UIWindow?
    private var uiListener: UIListener?


    /** the first screen: the chat list when signed in, else the welcome screen */
    func start(window: UIWindow) {
        self.window = window
        UIManager.applyTheme()

        SampleAPI.shared.setOnLogout { [weak self] _ in
            DispatchQueue.main.async { self?.launchLogin() }
        }

        if SampleAPI.isEmpty(SampleAPI.shared.getToken()) {
            launchWelcome()
        } else {
            launchMain()
        }
    }

    private func setRoot(_ viewController: UIViewController) {
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }


    // MARK: - welcome and login

    private func welcomeOptions() -> MesiboWelcomeOptions {
        let options = MesiboWelcomeOptions()
        options.logo = UIImage(named: "mesibo_logo_white")
        options.title = "Messaging & Calls in your apps"
        options.descriptionText = "Add messaging, video and voice calls & conferencing in your apps in no time."
        options.githubUrl = "https://github.com/mesibo"
        options.buttonText = "Get Started"
        // colors: MesiboUIHelper defaults (black background, white text and button)
        return options
    }

    private func loginOptions() -> MesiboLoginOptions {
        let options = MesiboLoginOptions()
        let country = Mesibo.getInstance().getPhoneContactsManager().getCountryCode()
        options.defaultCountryCode = country.countryPhoneCode > 0 ? country.countryPhoneCode : 1

        // we do not send verification codes; testers generate them from the mesibo console
        options.note = "This demo app will NOT send verification code. You can generate yourself from the mesibo console https://console.mesibo.com"
        options.noteIcon = UIImage(systemName: "hand.tap")
        options.noteColor = 0xffb45309
        options.noteBorderColor = 0x55ffb900
        options.noteBackgroundColor = 0x14ffb900
        options.codeMessage = "Enter the verification code for %PHONE% generated from the mesibo console"

        options.backgroundColor = 0xffffffff
        options.titleColor = 0xff172727
        options.messageColor = 0xff666666
        options.inputColor = 0xff172727
        options.accentColor = brandColor
        options.buttonColor = brandColor
        options.buttonTextColor = 0xffffffff
        return options
    }

    func launchWelcome() {
        setRoot(MesiboUIHelper.getWelcomeViewController(welcomeOptions(), login: loginOptions(), listener: self))
    }

    /** after logout */
    func launchLogin() {
        setRoot(MesiboUIHelper.getLoginViewController(loginOptions(), listener: self))
    }

    func MesiboLoginUiHelper_onLogin(parent: UIViewController, phone: String, code: String?,
                                     result: @escaping MesiboLoginResultBlock) -> Bool {
        SampleAPI.shared.login(phone: phone, code: code) { apiResult, response in
            let ok = apiResult == SampleAPI.resultOk

            DispatchQueue.main.async {
                result(ok)

                // signed in: a new user sets a name and picture first
                if ok && code != nil && !SampleAPI.isEmpty(SampleAPI.shared.getToken()) {
                    if SampleAPI.isNewUser(response) {
                        self.launchEditProfile(parent: nil, newUser: true)
                    } else {
                        self.launchMain()
                    }
                }
            }
        }
        return true
    }


    // MARK: - main

    /** the chat list (signed in) */
    func launchMain() {
        SampleAPI.shared.startContactSync()
        _ = SampleAppNotify.shared   // asks for notification permission (once)

        let defaults = MesiboUI.getUiDefaults()
        defaults.emptyUserListMessage = "No messages! Click on the message icon below to start messaging!"
        defaults.showAddressInProfileView = true

        if uiListener == nil {
            uiListener = UIListener()
        }
        CallListeners.start()

        let list = MesiboUI.getUserListViewController(MesiboUserListScreenOptions())
        setRoot(UINavigationController(rootViewController: list))

        // a notice from the server (e.g. limits of the demo)
        if let notice = SampleAPI.shared.getNotice(), !notice.isEmpty {
            DispatchQueue.main.async {
                UIManager.alert(title: SampleAPI.shared.getNoticeTitle(), message: notice)
            }
        }
    }

    /** the user's profile; newUser: the "profile info" step after the first sign in, then the chat list */
    func launchEditProfile(parent: UIViewController?, newUser: Bool) {
        MesiboUI.setEditProfileListener(self)
        Mesibo.getInstance().getSelfProfile().setSearchable(true)

        let options = MesiboEditProfileOptions()
        options.newUser = newUser

        if let parent = parent {
            MesiboUI.launchEditProfile(parent, opts: options)
            return
        }

        // first sign in: shown over an empty screen, then the chat list
        let blank = UIViewController()
        blank.view.backgroundColor = .systemBackground
        setRoot(blank)
        DispatchQueue.main.async {
            MesiboUI.launchEditProfile(blank, opts: options)
        }
    }

    func MesiboEditProfile_onSaved(parent: UIViewController, profile: MesiboProfile, newUser: Bool) {
        if newUser {
            launchMain()
        }
    }

    func launchSettings(_ parent: UIViewController) {
        let settings = SettingsViewController()

        if let navigation = parent.navigationController {
            navigation.pushViewController(settings, animated: true)
            return
        }

        let navigation = UINavigationController(rootViewController: settings)
        navigation.modalPresentationStyle = .fullScreen
        parent.present(navigation, animated: true)
    }


    // MARK: - helpers

    /** the screen on top, for alerts */
    func topController() -> UIViewController? {
        var top = window?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        if let navigation = top as? UINavigationController {
            top = navigation.topViewController ?? navigation
        }
        return top
    }

    static func alert(title: String?, message: String?) {
        DispatchQueue.main.async {
            if let top = UIManager.shared.topController() {
                MesiboDialogs.alert(top, title: title, message: message)
            }
        }
    }

    static func shareText(_ text: String, parent: UIViewController) {
        if text.isEmpty {
            return
        }
        let share = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = parent.view
        share.popoverPresentationController?.sourceRect = CGRect(x: parent.view.bounds.midX, y: parent.view.bounds.midY,
                                                                 width: 1, height: 1)
        parent.present(share, animated: true)
    }


    // MARK: - theme (Settings): applied when the app starts

    /** MESIBO_THEME_SYSTEM (default), MESIBO_THEME_LIGHT or MESIBO_THEME_DARK */
    static func theme() -> Int32 {
        return Int32(UserDefaults.standard.integer(forKey: themeKey))   // 0: MESIBO_THEME_SYSTEM
    }

    static func themeName() -> String {
        switch theme() {
        case MESIBO_THEME_LIGHT: return "Light"
        case MESIBO_THEME_DARK: return "Dark"
        default: return "System default"
        }
    }

    static func applyTheme() {
        MesiboUI.setTheme(theme())
    }

    /** System default / Light / Dark; saved, applied the next time the app starts */
    static func chooseTheme(_ parent: UIViewController, changed: (() -> Void)?) {
        let options = MesiboDialogOptions()
        options.title = "Theme"
        options.items = ["System default", "Light", "Dark"]
        options.sheet = true
        options.onSelect = { which in
            let theme: Int32 = which == 1 ? MESIBO_THEME_LIGHT : (which == 2 ? MESIBO_THEME_DARK : MESIBO_THEME_SYSTEM)
            if theme == UIManager.theme() {
                return
            }
            UserDefaults.standard.set(Int(theme), forKey: themeKey)
            changed?()
            MesiboDialogs.alert(parent, title: "Theme", message: "The new theme will be applied when you restart the app.")
        }
        MesiboDialogs.show(parent, options: options)
    }
}
