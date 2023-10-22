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
