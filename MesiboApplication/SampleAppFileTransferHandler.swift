//
//  SampleAppFileTransferHandler.swift
//  MesiboMessengerSwift
//
//  Reference only, not used by default: uploads and downloads files through your own server
//  instead of mesibo's. To use it, create one and call initialize() after starting mesibo.
//

import Foundation
import mesibo

class SampleAppFileTransferHandler: NSObject, MesiboDelegate {

    func initialize() {
        Mesibo.getInstance().addListener(self)
    }

    func Mesibo_onStartFileTransfer(ft: MesiboFileTransfer) -> Bool {
        return ft.upload ? startUpload(ft) : startDownload(ft)
    }

    func Mesibo_onStopFileTransfer(ft: MesiboFileTransfer) -> Bool {
        (ft.getFileTransferContext() as? MesiboHttp)?.cancel()
        return true
    }


    // MARK: - upload

    private func startUpload(_ file: MesiboFileTransfer) -> Bool {
        let post: [String: String] = [
            "op": "upload",
            "mid": String(file.mid),
            "uid": String(Mesibo.getInstance().getUid()),
            "source": String(file.source),
        ]

        let http = MesiboHttp()
        http.url = SampleAPI.shared.getUploadUrl()
        http.uploadPhAsset = file.getPHAsset()
        http.uploadLocalIdentifier = file.getLocalIdentifier()
        http.uploadFile = file.getPath()
        http.postBundle = post
        http.uploadFileField = "photo"
        http.listener = { http, state, progress in
            // done: the server answers {"result": true, "url": "..."}
            if progress == 100 && state == MESIBO_HTTPSTATE_DOWNLOAD {
                let data = http.getDataString()?.data(using: .utf8) ?? Data()
                let response = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let url = response?["url"] as? String ?? ""
                let ok = (response?["result"] as? Bool) ?? false

                if url.isEmpty || !ok {
                    file.setResult(false, url: nil)
                } else {
                    file.setResult(true, url: url)
                }
                return true
            }

            if progress < 0 {
                file.setResult(false, url: nil)
                return true
            }

            file.progress = progress
            return true
        }

        file.setFileTransferContext(obj: http)
        return http.execute()
    }


    // MARK: - download

    private func startDownload(_ file: MesiboFileTransfer) -> Bool {
        // only real-time messages, or files the user asked for
        if file.origin != MESIBO_ORIGIN_REALTIME && file.priority == 0 {
            return false
        }

        guard let url = file.getUrl(), url.hasPrefix("http://") || url.hasPrefix("https://") else {
            return false
        }

        let http = MesiboHttp()
        http.url = url
        http.downloadFile = file.getPath()
        http.resume = true
        http.maxRetries = 10
        http.listener = { _, state, progress in
            if progress == 100 && state == MESIBO_HTTPSTATE_DOWNLOAD {
                file.setResult(true, url: nil)
                return true
            }

            if progress < 0 {
                file.setResult(false, url: nil)
                return true
            }

            file.progress = progress
            return true
        }

        file.setFileTransferContext(obj: http)
        return http.execute()
    }
}
