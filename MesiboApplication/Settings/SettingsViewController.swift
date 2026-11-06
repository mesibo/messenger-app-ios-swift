//
//  SettingsViewController.swift
//  MesiboMessengerSwift
//
//  Settings: profile, notifications, theme, privacy policy, about and logout. Same as
//  BasicSettingsFragment on Android.
//

import UIKit
import mesibo
import MesiboUI

class SettingsViewController: UITableViewController {

    private let privacyUrl = "https://mesibo.com/terms-of-use/"

    private enum Section: Int, CaseIterable {
        case profile, notifications, display, info, logout
    }

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"

        // presented on its own: a Close button
        if navigationController?.viewControllers.first === self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()   // the profile may have been edited
    }


    // MARK: - table

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .notifications, .info: return 2
        default: return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .notifications: return "Notifications"
        case .display: return "Display"
        default: return nil
        }
    }

    /** a cell with a list content configuration; value: text with a value on the right */
    private func cell(text: String, icon: String?, value: Bool = false) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        var content = value ? UIListContentConfiguration.valueCell() : UIListContentConfiguration.cell()
        content.text = text
        if let icon = icon {
            content.image = UIImage(systemName: icon)
            content.imageProperties.tintColor = .secondaryLabel
        }
        cell.contentConfiguration = content
        return cell
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {

        case .profile:
            let me = Mesibo.getInstance().getSelfProfile()
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            var content = UIListContentConfiguration.subtitleCell()
            content.text = me.getName()
            content.textProperties.font = .systemFont(ofSize: 20, weight: .semibold)
            content.secondaryText = me.getString("status", defval: "")
            content.secondaryTextProperties.color = .secondaryLabel
            let picture = me.getImage().getOrThumbnail() ?? UIImage(systemName: "person.crop.circle.fill")
            content.image = round(picture, size: 60)
            content.imageProperties.tintColor = .systemGray
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell

        case .notifications:
            let groups = indexPath.row == 1
            let cell = self.cell(text: groups ? "Group message notifications" : "Message notifications",
                                 icon: groups ? "person.2" : "bell")
            let toggle = UISwitch()
            toggle.isOn = groups ? SampleAPI.shared.getGroupMessageNotification() : SampleAPI.shared.getMessageNotification()
            toggle.addAction(UIAction { _ in
                if groups {
                    SampleAPI.shared.setGroupMessageNotification(toggle.isOn)
                } else {
                    SampleAPI.shared.setMessageNotification(toggle.isOn)
                }
            }, for: .valueChanged)
            cell.accessoryView = toggle
            cell.selectionStyle = .none
            return cell

        case .display:
            let cell = self.cell(text: "Theme", icon: "circle.lefthalf.fill", value: true)
            if var content = cell.contentConfiguration as? UIListContentConfiguration {
                content.secondaryText = UIManager.themeName()
                cell.contentConfiguration = content
            }
            cell.accessoryType = .disclosureIndicator
            return cell

        case .info:
            let about = indexPath.row == 1
            let cell = self.cell(text: about ? "About" : "Privacy Policy and User Data", icon: about ? "info.circle" : "doc.text")
            cell.accessoryType = .disclosureIndicator
            return cell

        default:
            let cell = self.cell(text: "Log out", icon: nil)
            if var content = cell.contentConfiguration as? UIListContentConfiguration {
                content.textProperties.color = .systemRed
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
            }
            return cell
        }
    }

    /** image cropped to a circle of size points */
    private func round(_ image: UIImage?, size: CGFloat) -> UIImage? {
        guard let image = image else { return nil }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            UIBezierPath(ovalIn: rect).addClip()
            image.draw(in: rect)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section) {
        case .profile:
            UIManager.shared.launchEditProfile(parent: self, newUser: false)

        case .display:
            UIManager.chooseTheme(self) { [weak self] in
                self?.tableView.reloadData()
            }

        case .info:
            if indexPath.row == 1 {
                navigationController?.pushViewController(AboutViewController(), animated: true)
            } else if let url = URL(string: privacyUrl) {
                UIApplication.shared.open(url)
            }

        case .logout:
            confirmLogout()

        default:
            break
        }
    }

    private func confirmLogout() {
        let options = MesiboDialogOptions()
        options.title = "Log out?"
        options.positiveLabel = "Log out"
        options.negativeLabel = MesiboUI.getUiDefaults().cancel
        options.destructive = true
        options.onPositive = { [weak self] in
            SampleAPI.shared.logout(forced: false, parent: self)
        }
        MesiboDialogs.show(self, options: options)
    }
}
