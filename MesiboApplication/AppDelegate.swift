//
//  AppDelegate.swift
//  MesiboMessengerSwift
//
//  App start (UIManager routes to welcome / login or the chat list), push notifications and the
//  app's foreground state.
//

import UIKit
import UserNotifications
import mesibo
import MesiboCall

// reference: your own file transfer server (SampleAppFileTransferHandler), not used by default

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /** the window of the app's scene, set by SceneDelegate; the app and libraries look for it here */
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // push notifications (message wake-ups); VoIP pushes for calls are handled by MesiboCall
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        application.applicationIconBadgeNumber = 0

        // starts mesibo when signed in
        _ = SampleAPI.shared

        // the window and the first screen: SceneDelegate
        return true
    }


    // MARK: - push

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02X", $0) }.joined()
        Mesibo.getInstance().setPushToken(token, voip: false)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Push registration failed: %@", error.localizedDescription)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Mesibo.getInstance().didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}


/**
 * The window of the app's scene (UIScene lifecycle, Info.plist UIApplicationSceneManifest). It is
 * also set as the app delegate's window, where the app and libraries look for it.
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        (UIApplication.shared.delegate as? AppDelegate)?.window = window

        UIManager.shared.start(window: window)

        // a call from the Phone app's recents that launched the app
        for activity in connectionOptions.userActivities {
            self.scene(scene, continue: activity)
        }
    }


    // MARK: foreground state

    func sceneDidEnterBackground(_ scene: UIScene) {
        Mesibo.getInstance().setAppInForeground(self, screenId: 0, foreground: false)
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        Mesibo.getInstance().setAppInForeground(self, screenId: 0, foreground: true)
    }


    // MARK: calls

    /** a call from the Phone app's recents (CallKit): show the call in progress */
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let top = UIManager.shared.topController() {
            MesiboCall.getInstance().callUi(forExistingCall: top)
        }
    }
}
