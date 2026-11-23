//
//  UIListener.swift
//  MesiboMessengerSwift
//
//  Customizes the messaging screens: the chat list menu (conference, encryption, call logs,
//  backup & restore, invite, settings) and the call buttons of a chat. Same as UIListener on
//  Android.
//

import UIKit
import mesibo
import MesiboUI
import MesiboCall

// tags of the call buttons we add, to find and replace them
private let callButtonInProgress = 9001
private let callButtonVideo = 9002
private let callButtonVoice = 9003

class UIListener: NSObject, MesiboUIListener {

    // the screen each call button belongs to, for its action
    private let buttonScreens = NSMapTable<UIBarButtonItem, MesiboScreen>.weakToWeakObjects()

    override init() {
        super.init()
        MesiboUI.setListener(self)
    }


    // MARK: - MesiboUIListener

    /** each new configuration of the messaging UI (a theme applied): the app's own settings */
    func MesiboUI_onConfig(config: MesiboUiConfig, dark: Bool) {
        config.userList.emptyMessage = "No messages! Click on the message icon below to start messaging!"
        config.profileViewer.showAddress = true
    }

    func MesiboUI_onInitScreen(screen: MesiboScreen) -> Bool {
        if Int32(screen.type) == MESIBO_SCREEN_USERLIST {
            // only the chat list, not the contact pickers
            if let userList = screen as? MesiboUserListScreen, Int32(userList.mode) == MESIBO_MODE_MESSAGES {
                initUserListScreen(userList)
                updateCallButtons(screen: screen)
            }
        } else if Int32(screen.type) == MESIBO_SCREEN_MESSAGES {
            initMessageScreen(screen)
        } else if Int32(screen.type) == MESIBO_SCREEN_PROFILE, let profileScreen = screen as? MesiboProfileScreen {
            // the buttons under the name
            profileScreen.actions.addObjects(from: callItems(screen: screen))
        } else if Int32(screen.type) == MESIBO_SCREEN_PROFILE_POPUP {
            // the popup's buttons, between Message and Info
            screen.menu.addObjects(from: callItems(screen: screen))
        }

        // true: this screen's other callbacks too (MesiboUI_onUpdateScreen for the call buttons)
        return true
    }

    /**
     * Voice and video call buttons, for the profile screen and the profile popup (none for a group
     * the user left). During a call, they bring it back.
     */
    private func callItems(screen: MesiboScreen) -> [MesiboMenuItem] {
        guard let profile = screen.profile, !(profile.isGroup() && !profile.isActive()) else {
            return []
        }

        return [false, true].map { video in
            MesiboMenuItem(title: video ? "Video" : "Voice", image: UIImage(systemName: video ? "video.fill" : "phone.fill"),
                           identifier: video ? "videocall" : "voicecall") { [weak screen] _ in
                guard let parent = screen?.parent, let profile = screen?.profile else {
                    return
                }

                // during a call: back to it
                if MesiboCall.getInstance().isAnyCallInProgress() {
                    MesiboCall.getInstance().showCallInProgress(parent)
                    return
                }
                MesiboCall.getInstance().callUi(parent, profile: profile, video: video)
            }
        }
    }

    /** a call started or ended (CallListeners -> MesiboUI.updateScreens()) */
    func MesiboUI_onUpdateScreen(screen: MesiboScreen) {
        updateCallButtons(screen: screen)
    }


    // MARK: - screens

    /** the chat list's "more" menu */
    private func initUserListScreen(_ screen: MesiboUserListScreen) {
        addMenuItem(screen, title: "Conference", icon: "person.3", identifier: "conf") { parent in
            MesiboCall.getInstance().groupCallJoinRoomUi(parent, title: "Mesibo Conferencing Demo")
        }
        addMenuItem(screen, title: "End-to-end encryption", icon: "lock", identifier: "e2ee") { parent in
            MesiboUI.showEndToEndEncryptionConfiguration(parent)
        }
        addMenuItem(screen, title: "Call Logs", icon: "phone.arrow.up.right", identifier: "calllogs") { parent in
            MesiboCall.getInstance().launchLogs(parent)
        }
        addMenuItem(screen, title: "Backup & Restore", icon: "externaldrive", identifier: "backup") { parent in
            BackupRestore.show(parent)
        }
        addMenuItem(screen, title: "Invite", icon: "square.and.arrow.up", identifier: "share") { parent in
            UIManager.shareText(SampleAPI.shared.getInvite() ?? "", parent: parent)
        }
        addMenuItem(screen, title: "Customize", icon: "paintpalette", identifier: "customize") { parent in
            UIManager.shared.launchCustomize(parent)
        }
        addMenuItem(screen, title: "Settings", icon: "gearshape", identifier: "settings") { parent in
            UIManager.shared.launchSettings(parent)
        }
    }

    /**
     * the chat's "more" menu: end-to-end encryption of this chat (only while it is on; when off,
     * the screen would only say the chat isn't end-to-end encrypted; not for groups), and the
     * call buttons
     */
    private func initMessageScreen(_ screen: MesiboScreen) {
        if Mesibo.getInstance().e2ee().isEnabled() && !(screen.profile?.isGroup() ?? false) {
            addMenuItem(screen, title: "End-to-end encryption", icon: "lock.shield", identifier: "e2ee") { [weak screen] parent in
                if let profile = screen?.profile {
                    MesiboUI.showEndToEndEncryptionInfo(parent, profile: profile)
                }
            }
        }

        // disappearing messages of this chat: how long the messages this user sends live
        addMenuItem(screen, title: "Disappearing messages", icon: "timer", identifier: "disappearing") { [weak screen] parent in
            if let profile = screen?.profile {
                MesiboUI.launchDisappearingMessages(parent, profile: profile)
            }
        }
        updateCallButtons(screen: screen)
    }

    /** a "more" menu item; action gets the screen's view controller */
    private func addMenuItem(_ screen: MesiboScreen, title: String, icon: String, identifier: String,
                             action: @escaping (UIViewController) -> Void) {
        let item = MesiboMenuItem(title: title, image: UIImage(systemName: icon), identifier: identifier) { [weak screen] _ in
            if let parent = screen?.parent {
                action(parent)
            }
        }
        screen.menu.add(item)
    }


    // MARK: - call buttons

    private func callButton(symbol: String, tag: Int, label: String, screen: MesiboScreen) -> UIBarButtonItem {
        let button = UIBarButtonItem(image: UIImage(systemName: symbol), style: .plain,
                                     target: self, action: #selector(onCallButton(_:)))
        button.tag = tag
        button.accessibilityLabel = label
        buttonScreens.setObject(screen, forKey: button)
        return button
    }

    /** during a call: the call in progress button instead of the voice / video call buttons */
    private func updateCallButtons(screen: MesiboScreen) {
        // remove the buttons we added before
        let ours = screen.buttons.indexesOfObjects { item, _, _ in
            guard let button = item as? UIBarButtonItem else { return false }
            return button.tag >= callButtonInProgress && button.tag <= callButtonVoice
        }
        screen.buttons.removeObjects(at: ours)

        if MesiboCall.getInstance().isAnyCallInProgress() {
            let button = callButton(symbol: "phone.connection", tag: callButtonInProgress,
                                    label: "Call in progress", screen: screen)
            button.tintColor = .systemGreen
            screen.buttons.insert(button, at: 0)
            return
        }

        // voice and video call buttons in chats (not for groups the user left)
        if Int32(screen.type) != MESIBO_SCREEN_MESSAGES {
            return
        }
        guard let profile = screen.profile else { return }
        if profile.isGroup() && !profile.isActive() {
            return
        }

        // group calls: the same icons with a "+" badge; shown left to right in the order added
        let group = profile.isGroup()
        screen.buttons.add(callButton(symbol: group ? "video.badge.plus" : "video", tag: callButtonVideo,
                                      label: group ? "Group video call" : "Video call", screen: screen))
        screen.buttons.add(callButton(symbol: group ? "phone.badge.plus" : "phone", tag: callButtonVoice,
                                      label: group ? "Group voice call" : "Voice call", screen: screen))
    }

    /** during a call, callUi brings back the call in progress instead */
    @objc private func onCallButton(_ sender: UIBarButtonItem) {
        guard let screen = buttonScreens.object(forKey: sender), let parent = screen.parent else { return }

        if sender.tag == callButtonInProgress {
            MesiboCall.getInstance().showCallInProgress(parent)
            return
        }

        guard let profile = screen.profile else { return }
        MesiboCall.getInstance().callUi(parent, profile: profile, video: sender.tag == callButtonVideo)
    }
}
