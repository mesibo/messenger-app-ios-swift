//
//  ViewController.h
//  ProfileView
//
//  Created by Mesibo on 06/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mesibo/mesibo.h>

@interface ProfileViewerController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *mAddMemberView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mMediaCardHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mMediaCountViewHeight;
@property (weak, nonatomic) IBOutlet UIScrollView *mContentScrollView;
@property (weak, nonatomic) IBOutlet UIButton *mBackButton;
@property (weak, nonatomic) IBOutlet UIButton *mReportUserBtn;
@property (weak, nonatomic) IBOutlet UISwitch *mMuteSwitch;
@property (weak, nonatomic) IBOutlet UIButton *mChatBtn;
@property (weak, nonatomic) IBOutlet UIButton *mCustomNotification;
@property (weak, nonatomic) IBOutlet UIView *mViewBetweenMuteAndCustom;

@property (weak, nonatomic) IBOutlet UILabel *mMediaFileCounter;

@property (weak, nonatomic) IBOutlet UILabel *mUserName;

@property (weak, nonatomic) IBOutlet UILabel *mUserActivityStatus;

@property (strong , nonatomic) MesiboProfile *mUserData;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mHideStatusViewConstrain;


@property (weak, nonatomic) IBOutlet UIView *mStatusLineView;
@end

