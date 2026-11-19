//
//  AboutViewController.swift
//  MesiboMessengerSwift
//
//  The app's name, version and links. Same as AboutFragment on Android.
//

import UIKit

class AboutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "About"
        view.backgroundColor = .systemGroupedBackground

        let icon = UIImageView(image: UIImage(named: "appicon"))
        icon.contentMode = .scaleAspectFit
        icon.layer.cornerRadius = 22
        icon.clipsToBounds = true
        icon.widthAnchor.constraint(equalToConstant: 96).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let info = Bundle.main.infoDictionary ?? [:]

        let name = UILabel()
        name.text = info["CFBundleDisplayName"] as? String ?? info["CFBundleName"] as? String ?? "Mesibo"
        name.font = .systemFont(ofSize: 24, weight: .bold)

        let version = UILabel()
        version.text = "Version \(info["CFBundleShortVersionString"] as? String ?? "") (\(info["CFBundleVersion"] as? String ?? ""))"
        version.font = .systemFont(ofSize: 15)
        version.textColor = .secondaryLabel

        let about = UILabel()
        about.text = "Messaging, voice and video calls, and conferencing, built with mesibo. The source code of this app is on GitHub."
        about.font = .systemFont(ofSize: 15)
        about.textColor = .secondaryLabel
        about.numberOfLines = 0
        about.textAlignment = .center

        let website = link(title: "mesibo.com", url: "https://mesibo.com")
        let github = link(title: "Source code on GitHub", url: "https://github.com/mesibo")

        // centered column under the top of the screen
        let stack = UIStackView(arrangedSubviews: [icon, name, version, about, website, github])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(16, after: icon)
        stack.setCustomSpacing(24, after: version)
        stack.setCustomSpacing(24, after: about)
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: safe.topAnchor, constant: 40),
            stack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -32),
        ])
    }

    /** a text button that opens url */
    private func link(title: String, url: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.addAction(UIAction { _ in
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }, for: .touchUpInside)
        return button
    }
}
