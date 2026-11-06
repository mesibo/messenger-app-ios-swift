//
//  BackupRestore.swift
//  MesiboMessengerSwift
//
//  Message backups: kept in the app (Application Support/Backups) with an option to save a copy
//  to Files; restore from those or from a file picked in Files. Same as BackupRestore on Android.
//

import UIKit
import mesibo
import MesiboUI

enum BackupRestore {

    private static let prefix = "mesibo-backup-"
    private static let suffix = ".db"

    /** Back up now / Restore */
    static func show(_ parent: UIViewController) {
        let options = MesiboDialogOptions()
        options.title = "Backup & Restore"
        options.items = ["Back up now", "Restore"]
        options.sheet = true
        options.onSelect = { [weak parent] which in
            guard let parent = parent else { return }
            if which == 0 {
                backup(parent)
            } else {
                chooseRestore(parent)
            }
        }
        MesiboDialogs.show(parent, options: options)
    }

    /** Application Support/Backups (not visible in Files; the database is in Documents) */
    private static func backupDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }


    // MARK: - backup

    static func backup(_ parent: UIViewController) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = backupDir().appendingPathComponent(prefix + formatter.string(from: Date()) + suffix)

        DispatchQueue.global(qos: .userInitiated).async { [weak parent] in
            Mesibo.getInstance().backupDatabase(url.path)
            let ok = FileManager.default.fileExists(atPath: url.path)

            DispatchQueue.main.async {
                guard let parent = parent else { return }
                if !ok {
                    MesiboDialogs.alert(parent, title: "Backup failed", message: nil)
                    return
                }

                // a copy outside the app survives deleting the app
                let options = MesiboDialogOptions()
                options.title = "Messages backed up"
                options.message = "Save a copy to Files to keep it if the app is deleted or to move it to another phone."
                options.positiveLabel = "Save to Files"
                options.negativeLabel = "Done"
                options.onPositive = { [weak parent] in
                    if let parent = parent {
                        exportFile(url, parent: parent)
                    }
                }
                MesiboDialogs.show(parent, options: options)
            }
        }
    }

    private static func exportFile(_ url: URL, parent: UIViewController) {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        parent.present(picker, animated: true)
    }


    // MARK: - restore

    /** backups in the app, newest first */
    private static func backups() -> [URL] {
        let keys: [URLResourceKey] = [.contentModificationDateKey, .fileSizeKey]
        let files = (try? FileManager.default.contentsOfDirectory(at: backupDir(), includingPropertiesForKeys: keys,
                                                                  options: .skipsHiddenFiles)) ?? []

        let list = files.filter { $0.lastPathComponent.hasPrefix(prefix) && $0.lastPathComponent.hasSuffix(suffix) }
        return list.sorted { modified($0) > modified($1) }
    }

    private static func modified(_ url: URL) -> Date {
        return (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
    }

    /** "date · size" for the restore list */
    private static func describe(_ url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])

        var when = url.lastPathComponent
        if let date = values?.contentModificationDate {
            when = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .short)
        }
        let size = ByteCountFormatter.string(fromByteCount: Int64(values?.fileSize ?? 0), countStyle: .file)
        return "\(when)  ·  \(size)"
    }

    /** backups in the app, and Choose file... */
    private static func chooseRestore(_ parent: UIViewController) {
        let found = backups()

        let options = MesiboDialogOptions()
        options.title = found.isEmpty ? "No backups found on this phone" : "Restore from"
        options.items = found.map(describe) + ["Choose file..."]
        options.sheet = true
        options.onSelect = { [weak parent] which in
            guard let parent = parent else { return }
            if which < found.count {
                confirmRestore(found[which].path, parent: parent)
            } else {
                pickFile(parent)
            }
        }
        MesiboDialogs.show(parent, options: options)
    }

    private static func pickFile(_ parent: UIViewController) {
        // callbacks run on the main thread
        MesiboUI.pickFile(parent, extensions: ["db"], picked: { [weak parent] path in
            // nil: cancelled
            if let path = path, let parent = parent {
                confirmRestore(path, parent: parent)
            }
        }, rejected: { [weak parent] name in
            if let parent = parent {
                MesiboDialogs.alert(parent, title: "Not a backup", message: "\(name) is not a mesibo backup (.db) file")
            }
        })
    }

    private static func confirmRestore(_ path: String, parent: UIViewController) {
        let options = MesiboDialogOptions()
        options.title = "Restore messages?"
        options.message = "Your current messages will be replaced by the backup. mesibo will close after restoring; open it again to see them."
        options.positiveLabel = "Restore"
        options.negativeLabel = MesiboUI.getUiDefaults().cancel
        options.destructive = true
        options.onPositive = { [weak parent] in
            if let parent = parent {
                restore(path, parent: parent)
            }
        }
        MesiboDialogs.show(parent, options: options)
    }

    private static func restore(_ path: String, parent: UIViewController) {
        let result = Mesibo.getInstance().restoreDatabase(path)
        if result != 0 {
            MesiboDialogs.alert(parent, title: "Restore failed", message: "The file is not a valid mesibo backup (\(result))")
            return
        }

        // messages and profiles are loaded in memory: the app starts again with the restored database
        let options = MesiboDialogOptions()
        options.title = "Messages restored"
        options.message = "mesibo will close now. Open it again to see the restored messages."
        options.onPositive = { exit(0) }
        MesiboDialogs.show(parent, options: options)
    }
}
