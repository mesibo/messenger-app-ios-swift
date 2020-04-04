//
//  EditProfileViewController.h
//  MesiboUIHelper
//
//  Created by Mesibo on 03/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LaunchMesiboBlock)();

@interface EditSelfProfileViewController : UIViewController <UIGestureRecognizerDelegate>


- (void) setStatusLabel:(NSString *)mStatusText;
- (void) setSelfUserName:(NSString *)mSelfUserNameText;

@property (strong, nonatomic) LaunchMesiboBlock mLaunchMesibo ;

- (void) setLaunchMesiboCallback:(LaunchMesiboBlock) handler;
@end
