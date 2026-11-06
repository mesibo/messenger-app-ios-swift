//
//  SampleAPI.swift
//  MesiboMessengerSwift
//
//  The app's backend (the messenger server, MessengerApiUrl in Info.plist): login and logout,
//  and starting mesibo with the user's token. Also keeps the app's settings.
//

import UIKit
import mesibo

class SampleAPI {

    static let shared = SampleAPI()

    // results of the API calls
    static let resultOk = 0
    static let resultFail = 1
    static let resultAuthFail = 2

    typealias ResponseHandler = (_ result: Int, _ response: [String: Any]?) -> Void
    typealias LogoutHandler = (_ parent: Any?) -> Void

    // keys of values saved with mesibo (Mesibo.setKey / readKey)
    private let inviteKey = "inivte"
    private let uploadUrlKey = "upload"
    private let downloadUrlKey = "download"
    private let syncedContactsKey = "syncedcontacts"

    // notification settings: empty (default) = enabled, "0" = disabled; same keys as Android
    private let notifyMessagesKey = "notifymessages"
    private let notifyGroupsKey = "notifygroups"

    private let defaults = UserDefaults.standard
    private let apiUrl: String?
    private let deviceId: String
    private let deviceType: String

    private var token: String?
    private var phone: String?
    private var invite: String?
    private var uploadUrl: String?
    private var downloadUrl: String?
    private var notice: String?
    private var noticeTitle: String?
    private var resetSyncedContacts = false
    private var syncStarted = false
    private var onLogout: LogoutHandler?


    private init() {
        apiUrl = Bundle.main.object(forInfoDictionaryKey: "MessengerApiUrl") as? String
        if !SampleAPI.isValidUrl(apiUrl) {
            NSLog("************* INVALID URL - set a valid URL in MessengerApiUrl field in Info.plist *************")
        }

        deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        deviceType = String(Mesibo.getInstance().getDeviceType())
        token = defaults.string(forKey: "token")

        // signed in before: start mesibo right away
        if !SampleAPI.isEmpty(token) {
            startMesibo()
        }
    }


    // MARK: - mesibo

    private func startMesibo() {
        // listeners first: they also do reverse lookups while mesibo starts
        _ = SampleAppListeners.shared

        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last ?? ""
        Mesibo.getInstance().setPath(documents)
        Mesibo.getInstance().setAccessToken(getToken())
        Mesibo.getInstance().setDatabase("mesiboapp.db")

        Mesibo.getInstance().e2ee().enable(true)
        Mesibo.getInstance().start()

        let locationConfig = MesiboLocationConfig()
        locationConfig.backgroundRefresh = false
        MesiboLocationManager.getInstance().start(locationConfig)
    }

    /** finds which phone contacts use the app (once per start) */
    func startContactSync() {
        let start: Bool = {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            if syncStarted { return false }
            syncStarted = true
            return true
        }()
        if !start {
            return
        }

        // a new login: sync all contacts again
        if resetSyncedContacts {
            Mesibo.getInstance().getPhoneContactsManager().reset()
        }
        Mesibo.getInstance().getPhoneContactsManager().start()
    }


    // MARK: - values

    func setOnLogout(_ handler: @escaping LogoutHandler) {
        onLogout = handler
    }

    func getToken() -> String? {
        return SampleAPI.isEmpty(token) ? nil : token
    }

    func getPhone() -> String? {
        if phone == nil {
            phone = Mesibo.getInstance().getAddress()
        }
        return phone
    }

    func getInvite() -> String? {
        if let invite = invite, invite.count > 6 {
            return invite
        }
        invite = savedValue(nil, key: inviteKey)
        return invite
    }

    func getUploadUrl() -> String? {
        if let url = uploadUrl, url.count > 6 {
            return url
        }
        uploadUrl = savedValue(nil, key: uploadUrlKey)
        return uploadUrl
    }

    func getNotice() -> String? {
        return notice
    }

    func getNoticeTitle() -> String? {
        return noticeTitle
    }

    /** saves value with mesibo when given, else returns the saved one */
    private func savedValue(_ value: String?, key: String) -> String? {
        if let value = value {
            Mesibo.getInstance().setKey(key, value: value)
            return value
        }
        return Mesibo.getInstance().readKey(key)
    }

    private func save() {
        defaults.set(token, forKey: "token")
    }


    // MARK: - notification settings

    func getMessageNotification() -> Bool {
        return Mesibo.getInstance().readKey(notifyMessagesKey) != "0"
    }

    func setMessageNotification(_ enable: Bool) {
        Mesibo.getInstance().setKey(notifyMessagesKey, value: enable ? "" : "0")
    }

    func getGroupMessageNotification() -> Bool {
        return Mesibo.getInstance().readKey(notifyGroupsKey) != "0"
    }

    func setGroupMessageNotification(_ enable: Bool) {
        Mesibo.getInstance().setKey(notifyGroupsKey, value: enable ? "" : "0")
    }


    // MARK: - login and logout

    /** without code: asks for a code; with code: signs in */
    func login(phone: String, code: String?, handler: @escaping ResponseHandler) {
        var post: [String: Any] = [
            "op": "login",
            "appid": Bundle.main.bundleIdentifier ?? "",
            "phone": phone,
        ]
        if let code = code {
            post["otp"] = code
            post["device"] = deviceId
        }
        invokeApi(post, handler: handler)
    }

    /** forced: sign out here only, without telling the server */
    func logout(forced: Bool, parent: Any?) {
        Mesibo.getInstance().stop()

        if !forced {
            startLogout { _, _ in
                self.logout(forced: true, parent: parent)
            }
            return
        }

        token = ""
        phone = nil
        save()
        Mesibo.getInstance().reset()

        onLogout?(parent)
    }

    private func startLogout(handler: @escaping ResponseHandler) {
        guard let token = token else { return }

        // even if the token is wrong, logout happens through AUTHFAIL
        invokeApi(["op": "logout", "token": token], handler: handler)
    }


    // MARK: - API calls

    private func invokeApi(_ request: [String: Any], handler: @escaping ResponseHandler) {
        var post = request
        post["dt"] = deviceType

        guard let body = try? JSONSerialization.data(withJSONObject: post) else {
            handler(SampleAPI.resultFail, nil)
            return
        }

        let http = MesiboHttp()
        http.url = apiUrl
        http.contentType = "application/json"
        http.post = body
        http.listener = { http, state, progress in
            if progress == 100 && state == MESIBO_HTTPSTATE_DOWNLOAD {
                self.parseResponse(http.getDataString(), handler: handler)
            }

            if progress < 0 {
                NSLog("invokeApi failed")
                handler(SampleAPI.resultFail, nil)
            }
            return true
        }
        http.execute()
    }

    private func parseResponse(_ responseText: String?, handler: @escaping ResponseHandler) {
        guard let data = responseText?.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed),
              let response = json as? [String: Any] else {
            handler(SampleAPI.resultFail, nil)
            return
        }

        // failed: sign out on AUTHFAIL, else show the server's message
        if response["result"] as? String != "OK" {
            if response["error"] as? String == "AUTHFAIL" {
                logout(forced: true, parent: nil)
                return
            }

            if let message = response["errmsg"] as? String {
                UIManager.alert(title: response["errtitle"] as? String ?? "Failed", message: message)
            }
            handler(SampleAPI.resultFail, response)
            return
        }

        // values the server may send with any response
        if let inviteText = response["invite"] as? String, !inviteText.isEmpty {
            invite = savedValue(inviteText, key: inviteKey)
        }

        if let urls = response["urls"] as? [String: Any] {
            uploadUrl = savedValue(urls["upload"] as? String, key: uploadUrlKey)
            downloadUrl = savedValue(urls["download"] as? String, key: downloadUrlKey)
        }

        if let noticeInfo = response["notice"] as? [String: Any] {
            noticeTitle = noticeInfo["title"] as? String
            notice = noticeInfo["desc"] as? String
        }

        // signed in: save the token and start mesibo for this user
        if response["op"] as? String == "login" {
            token = response["token"] as? String
            phone = response["phone"] as? String

            if !SampleAPI.isEmpty(token) {
                save()
                resetSyncedContacts = true
                syncStarted = false
                Mesibo.getInstance().reset()
                startMesibo()
            }
        }

        handler(SampleAPI.resultOk, response)
    }


    // MARK: - helpers

    /** new_user in the login response: a user without a profile yet; may come as true, 1 or "1" */
    static func isNewUser(_ response: [String: Any]?) -> Bool {
        let value = response?["new_user"]
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let text = value as? String {
            return text == "1" || text.caseInsensitiveCompare("true") == .orderedSame
        }
        return false
    }

    static func isEmpty(_ string: String?) -> Bool {
        return string?.isEmpty ?? true
    }

    private static func isValidUrl(_ url: String?) -> Bool {
        guard let url = url else { return false }
        return url.hasPrefix("http://") || url.hasPrefix("https://")
    }
}
