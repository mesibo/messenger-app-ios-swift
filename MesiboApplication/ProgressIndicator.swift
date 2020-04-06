//
//  ProgressIndicator.swift
//  MesiboMessengerSwift
//
//  Copyright © 2020 Mesibo. All rights reserved.
//

import Foundation

@objcMembers public class ProgressIndicator : NSObject {
    private var mIndicator: UIActivityIndicatorView?
    private var mSystemVersion = 0
    
    static var getInstanceMyInstance: ProgressIndicator? = nil
    
    public class func getInstance() -> ProgressIndicator {
        if nil == getInstanceMyInstance {
            let lockQueue = DispatchQueue(label: "self")
            lockQueue.sync {
                if nil == getInstanceMyInstance {
                    getInstanceMyInstance = ProgressIndicator()
                    getInstanceMyInstance?.initialize()
                }
            }
        }
        return getInstanceMyInstance!
    }

    func initialize() {
        let width = UIScreen.main.bounds.size.width

        let height = UIScreen.main.bounds.size.height

        mIndicator = UIActivityIndicatorView(style: .whiteLarge)
        mIndicator?.frame = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        mIndicator?.layer.cornerRadius = 0
        mIndicator?.layer.masksToBounds = true
        mIndicator?.isOpaque = false
        mIndicator?.hidesWhenStopped = true
        mIndicator?.tag = 10000
        mIndicator?.backgroundColor = UIColor.getColor(UInt32(INDI_BACKGROUND))
        let systemVersion = UIDevice.current.systemVersion
        mSystemVersion = Int(((systemVersion as NSString).substring(to: 1))) ?? 0
    }

    func addProgress(_ view: UIView?) {
        if let mIndicator = mIndicator {
            view?.addSubview(mIndicator)
        }
        if let view = view {
            mIndicator?.bringSubviewToFront(view)
        }
        //mIndicator.center = view.center;
    }

    func showProgress() {
        mIndicator?.startAnimating()
    }

    func hideProgress() {
        if mIndicator?.isAnimating != nil {
            mIndicator?.stopAnimating()
        }
    }

    func runningVersionAnd(above version: Int) -> Bool {
        if mSystemVersion >= version {
            return true
        }
        return false
    }
}
