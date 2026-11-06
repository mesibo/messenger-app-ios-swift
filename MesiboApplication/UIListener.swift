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

    func MesiboUI_onInitScreen(screen: MesiboScreen) -> Bool {
        if Int32(screen.type) == MESIBO_SCREEN_USERLIST {
            // only the chat list, not the contact pickers
            if let userList = screen as? MesiboUserListScreen, Int32(userList.mode) == MESIBO_MODE_MESSAGES {
                initUserListScreen(userList)
                updateCallButtons(screen: screen)
            }
        } else if Int32(screen.type) == MESIBO_SCREEN_MESSAGES {
            initMessageScreen(screen)
        }
        return false
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
        addMenuItem(screen, title: "End-to-End Encryption", icon: "lock", identifier: "e2ee") { parent in
            MesiboUI.showEnd(toEndEncryptionInfo: parent, profile: nil)
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
        addMenuItem(screen, title: "Settings", icon: "gearshape", identifier: "settings") { parent in
            UIManager.shared.launchSettings(parent)
        }
    }

    /** the chat's "more" menu: encryption of this chat (Encryption on Android), and the call buttons */
    private func initMessageScreen(_ screen: MesiboScreen) {
        addMenuItem(screen, title: "Encryption", icon: "lock.shield", identifier: "e2ee") { [weak screen] parent in
            if let profile = screen?.profile {
                MesiboUI.showEnd(toEndEncryptionInfo: parent, profile: profile)
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
            MesiboCall.getInstance().show(inProgress: parent)
            return
        }

        guard let profile = screen.profile else { return }
        MesiboCall.getInstance().callUi(parent, profile: profile, video: sender.tag == callButtonVideo)
    }
}
