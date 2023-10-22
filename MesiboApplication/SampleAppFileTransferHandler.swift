/******************************************************************************
* By accessing or copying this work, you agree to comply with the following   *
* terms:                                                                      *
*                                                                             *
* Copyright (c) 2019-2023 mesibo                                              *
* https://mesibo.com                                                          *
* All rights reserved.                                                        *
*                                                                             *
* Redistribution is not permitted. Use of this software is subject to the     *
* conditions specified at https://mesibo.com . When using the source code,    *
* maintain the copyright notice, conditions, disclaimer, and  links to mesibo * 
* website, documentation and the source code repository.                      *
*                                                                             *
* Do not use the name of mesibo or its contributors to endorse products from  *
* this software without prior written permission.                             *
*                                                                             *
* This software is provided "as is" without warranties. mesibo and its        *
* contributors are not liable for any damages arising from its use.           *
*                                                                             *
* Documentation: https://mesibo.com/documentation/                            *
*                                                                             *
* Source Code Repository: https://github.com/mesibo/                          *
*******************************************************************************/

import Foundation
import Photos

@objcMembers public class SampleAppFileTransferHandler: NSObject, MesiboDelegate {
    
    func initialize() {
        Mesibo.getInstance().addListener(self)
    }
    
    func mesibo_(onStartUpload file: MesiboFileTransfer) -> Bool {
               
        var post: [AnyHashable : Any] = [:]
        
        post["op"] = "upload"
        post["auth"] = SampleAPI.getInstance().getToken()
        post["mid"] = String(file.mid)
        post["profile"] = "0"
        
        let handler = { (http: MesiboHttp, state: Int32, httpprogress: Int32) -> Bool in
            
            var progress: Int32 = httpprogress
                       
            if 100 == progress && MESIBO_HTTPSTATE_DOWNLOAD == state {
                var jsonerror: Error? = nil
                
                let data = http.getDataString()?.data(using: .utf8)
                var jsonObject: Any? = nil
                do {
                    if let data = data {
                        jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    }
                } catch let jsonerror {
                }
                let returnedDict = jsonObject as? [AnyHashable : Any]
                let fileUrl = returnedDict?["url"] as? String
                
                if fileUrl != nil {
                    file.setResult(true, url: fileUrl)
                } else {
                    file.setResult(false, url: nil)
                }
                return true;
            }
            
            if (progress < 0 ) {
                file.setResult(false, url: nil)
                return true;
            }
            
            file.progress = progress;
            return true;
            
            } as Mesibo_onHTTPProgress
        
        let http = MesiboHttp()
        http.url = SampleAPI.getInstance().getUploadUrl()
        http.uploadPhAsset = file.getPHAsset()
        http.uploadLocalIdentifier = file.getLocalIdentifier()
        http.uploadFile = file.getPath()
        http.postBundle = post
        http.uploadFileField = "photo"
        http.listener = handler
        
        file.setFileTransferContext(obj: http);
        
        return http.execute()
        
       
    }
    
    func mesibo_(onStartDownload file: MesiboFileTransfer) -> Bool {
   
        if MESIBO_ORIGIN_REALTIME != file.origin && file.priority == 0 {
            return false
        }
        
        var url = file.getUrl()
        
        let handler = { (http: MesiboHttp, state: Int32, progress: Int32) -> Bool in
            
            if(100 == progress) {
                file.setResult(false, url: nil)
                return true;
            }
            
            if (progress < 0 ) {
                file.setResult(false, url: nil)
                return true;
            }
            
            file.progress = progress;
            return true;
            
            } as Mesibo_onHTTPProgress
        
        let http = MesiboHttp()
        http.url = url
        http.downloadFile = file.getPath()
        http.resume = true
        http.listener = handler
        
        file.setFileTransferContext(obj: http);
        
        return http.execute()
        
    }
    
    public func Mesibo_onStartFileTransfer(ft: MesiboFileTransfer) -> Bool {
        
        if (!ft.upload) {
            return mesibo_(onStartDownload: ft)
        }
        
        return mesibo_(onStartUpload: ft)
        
    }
    
    public func Mesibo_onStopFileTransfer(ft: MesiboFileTransfer) -> Bool {
        let http = ft.getFileTransferContext() as? MesiboHttp
        if http != nil {
            http!.cancel()
        }
        return true
    }
}
