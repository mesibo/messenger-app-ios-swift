//
//  MesiboUIManager.swift
//  MesiboMessengerSwift
//
//  Copyright © 2020 Mesibo. All rights reserved.
//

import Foundation
import AVFoundation
import CoreServices
import mediapicker
import MesiboUI
import mesibo

var mAppParent: UIViewController? = nil

let MESIBO_UI_BUNDLE = ""
let PROFILE_STORYBOARD = "profile"
let PROFILE_BUNDLE = "MesiboUIResource"
let SETTINGS_STORYBOARD = "settings"

var mDefaultUserProfilePath: String?
var mDefaultGroupProfilePath: String?
var shareInProgress: Bool = false


@objcMembers public class MesiboUIManager: NSObject {
    class func getMeProfileStoryBoard() -> UIStoryboard? {

        let bundle = MesiboUIManager.getBundle()
        return UIStoryboard(name: PROFILE_STORYBOARD, bundle: bundle)

    }

    class func getMeMesiboStoryBoard() -> UIStoryboard? {
        let bundle = MesiboUIManager.getBundle()
        let sb = UIStoryboard(name: "Mesibo", bundle: bundle)
        return sb

    }
    
    class func getMeSettingsStoryBoard() -> UIStoryboard? {
        let bundle = Bundle.main
        return UIStoryboard(name: SETTINGS_STORYBOARD, bundle: bundle)
    }

    class func getBundle() -> Bundle {
        let bundle = Bundle.main
        return bundle

    }
    
    public class func launchProfile(_ parent: Any?, profile: MesiboProfile?) {
        let storyboard = MesiboUIManager.getMeProfileStoryBoard()
        let pvc = storyboard?.instantiateViewController(withIdentifier: "ProfileViewerController") as? ProfileViewerController
        if (pvc is ProfileViewerController) {
            pvc?.mUserData = profile
            if let pvc = pvc {
                ((parent as? UIViewController)?.navigationController)?.pushViewController(pvc, animated: true)
            }
        }
    }
    
    class func launchSettings(_ parent: UIViewController) {
        let storyboard = MesiboUIManager.getMeSettingsStoryBoard()
        let mtvc = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
        var unc: UINavigationController? = nil
        if let mtvc = mtvc {
            unc = UINavigationController(rootViewController: mtvc)
        }
        if let unc = unc {
            parent.present(unc, animated: true)
        }
    }
    
    class func launchEditProfile(_ RootController: UIViewController?, withMainWindow mainWindow: UIWindow?) {
        var RootController = RootController
        let storybord = UIStoryboard(name: "Main", bundle: Bundle.main)
        let editSelfProfileController = storybord.instantiateViewController(withIdentifier: "EditSelfProfileViewController") as? EditProfileController
        editSelfProfileController?.setLaunchMesiboCallback({
            MesiboUIManager.launchMesiboUI(RootController, withMainWindow: mainWindow)
        })
        RootController = editSelfProfileController
        mainWindow?.rootViewController = RootController
        mainWindow?.makeKeyAndVisible()
    }
    
    class func setDefaultParent(_ controller: UIViewController?) {
        mAppParent = controller
    }
    
    class func launchVC_mainThread(_ parent: UIViewController?, vc: UIViewController?) {
        var parent = parent
        
        if parent == nil {
            parent = mAppParent
        }
    
        if let vc = vc {
            parent?.present(vc, animated: true)
        }
        
    }
    
    class func launchVC(_ parent: UIViewController?, vc: UIViewController?) {
        
        if vc?.isBeingPresented != nil {
            return
        }
        
        Mesibo.getInstance()!.run(inThread: true, handler: {
            self.launchVC_mainThread(parent, vc: vc)
        })
    }
    
    class func launchMesiboUI(_ rootController: UIViewController?, withMainWindow mainWindow: UIWindow?) {
        var rootController = rootController
        
        let ui = MesiboUI.getOptions()
        ui?.emptyUserListMessage = "No active conversations! Click on the message icon to send a message."
        
        let old = mainWindow?.rootViewController
        
        
        let mesiboController = MesiboUI.getViewController()
        var navigationController: UINavigationController? = nil
        if let mesiboController = mesiboController {
            navigationController = UINavigationController(rootViewController: mesiboController)
        }
        rootController = navigationController
        mAppParent = rootController
        mainWindow?.rootViewController = rootController
        mainWindow?.makeKeyAndVisible()
        
        //if(old)
        //[old dismissViewControllerAnimated:NO completion:nil];
    }
    
    class func showImageFile(_ im: ImagePicker?, parent: UIViewController, image: UIImage?,  title: String?) {
        im?.showPhoto(inViewer: parent, with: image, withTitle: title)
    }
    
    class func showImages(inViewer im: ImagePicker?, parent: UIViewController, images: [AnyHashable]?, index: Int, title: String?) {
        im?.showMediaFiles(inViewer: parent, withInitialIndex: Int32(index), withData: images, withTitle: title)
        
    }
    
    class func showEntireAlbum(_ im: ImagePicker?, parent: UIViewController, album:  [AnyHashable], title: String?) {
        im?.showMediaFiles(parent, withMediaData: album, withTitle: title)
        
    }
    
    class func pickImageData(_ im: ImagePicker?, withParent Parent: UIViewController, withMediaType type: Int, withBlockHandler handler: @escaping (_ file: ImagePickerFile?) -> Void) {
        var im = im
        if nil == im {
            im = ImagePicker.sharedInstance()
        }
        
        im?.mParent = Parent
        im?.pickMedia(Int32(type), handler)
        
    }
    
    class func launchImageEditor(_ im: ImagePicker?, parent: UIViewController, image: UIImage?, hideEditControls hideControls: Bool, handler: MesiboImageEditorBlock?) {
        var im = im
        if nil == im {
            im = ImagePicker.sharedInstance()
        }
        
        im?.mParent = parent
        im?.getImageEditor(image, title: "Edit Picture", hideEditControl: hideControls, showCaption: false, showCropOverlay: true, squareCrop: true, maxDimension: 600, with: handler)
        
    }
    
    class func getDefaultImage(_ group: Bool) -> UIImage? {
        return MesiboUI.getDefaultImage(group)
    }
    
    class func getBitmapFromFile(_ checkFile: String?) -> UIImage? {
        var image: UIImage? = nil
        let fileExist = Mesibo.getInstance().fileExists(checkFile)
        if fileExist {
            if self.isImageFile(checkFile) {
                image = UIImage(contentsOfFile: checkFile ?? "")
            } else {
                let videoUrl = URL(fileURLWithPath: checkFile ?? "")
                image = MesiboUIManager.profileThumbnailImage(from: videoUrl)
            }
        }

        return image

    }

    class func isImageFile(_ filePath: String?) -> Bool {

        var isimage = false
        let fileExtension = URL(fileURLWithPath: filePath!).pathExtension as CFString?
        var fileUTI: CFString? = nil
        if let fileExtension = fileExtension {
            fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, nil) as! CFString
        }

        if let fileUTI = fileUTI {
            if UTTypeConformsTo(fileUTI, kUTTypeImage) {
                isimage = true
            }
        }
        return isimage
    }
    
    

    class func profileThumbnailImage(from videoURL: URL?) -> UIImage? {

        var asset: AVURLAsset? = nil
        if let videoURL = videoURL {
            asset = AVURLAsset(url: videoURL, options: nil)
        }
        var generator: AVAssetImageGenerator? = nil
        if let asset = asset {
            generator = AVAssetImageGenerator(asset: asset)
        }
        var err: Error? = nil
        let requestedTime = CMTimeMake(value: 1, timescale: 60) // To create thumbnail image
        var imgRef: CGImage? = nil
        do {
            imgRef = try generator?.copyCGImage(at: requestedTime, actualTime: nil)
        } catch let err {
        }
        if let err = err, let imgRef = imgRef {
            print("err = \(err), imageRef = \(imgRef)")
        }
        var thumbnailImage: UIImage? = nil
        if let imgRef = imgRef {
            thumbnailImage = UIImage(cgImage: imgRef)
        }
        //CGImageRelease(imgRef!) // MUST release explicitly to avoid memory leak

        return thumbnailImage
    }

    class func imageNamed(_ imageName: String?) -> UIImage? {
        let SettingsBundle = MesiboUIManager.getBundle()
        return UIImage(named: imageName ?? "", in: SettingsBundle, compatibleWith: nil)
    }

    class func getDefaultGroupProfilePath() -> String? {
        if nil == mDefaultGroupProfilePath {
            mDefaultGroupProfilePath = MesiboUIManager.getBundle().path(forResource: "group", ofType: "png")
        }
        return mDefaultGroupProfilePath
    }
    
    class func getDefaultProfilePath() -> String? {
        if nil == mDefaultUserProfilePath {
            mDefaultUserProfilePath = MesiboUIManager.getBundle().path(forResource: "blank_profile", ofType: "png")
        }
        return mDefaultUserProfilePath
    }

    class func shareText(_ textToShare: String?, parent: UIViewController?) {
        if shareInProgress {
            return
        }

        shareInProgress = true
        let objectsToShare = [textToShare]

        let activityVC = UIActivityViewController(activityItems: objectsToShare.compactMap { $0 }, applicationActivities: nil)

        activityVC.excludedActivityTypes = [
        .print,
        .assignToContact,
        .saveToCameraRoll
        ] //Exclude whichever aren't relevant

        parent?.present(activityVC, animated: true) {
            shareInProgress = false
        }
    }
}
