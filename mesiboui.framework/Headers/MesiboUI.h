//
//  MesiboUI.h
//  MesiboUI
//
//  Copyright © 2018 Mesibo. All rights reserved.
//
#ifndef __MESIBOUI_H
#define __MESIBOUI_H
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Mesibo/Mesibo.h"
//#import "UITableViewWithReloadCallback.h"

@interface MesiboCell : UITableViewCell {
    
}
@end

@protocol MesiboMessageViewDelegate <NSObject>
@required
- (UITableView *) getMesiboTableView;
- (CGFloat)MesiboTableView:(UITableView *)tableView heightForMessage:(MesiboMessage *)message;
- (MesiboCell *)MesiboTableView:(UITableView *)tableView cellForMessage:(MesiboMessage *)message;
- (MesiboCell *)MesiboTableView:(UITableView *)tableView show:(MesiboMessage *)message;
@optional
@end

@interface MesiboUiOptions : NSObject
@property (nonatomic) UIImage *contactPlaceHolder;
@property (nonatomic) UIImage *messagingBackground;

@property (nonatomic) BOOL useLetterTitleImage;

@property (nonatomic) BOOL enableVoiceCall;
@property (nonatomic) BOOL enableVideoCall;
@property (nonatomic) BOOL enableForward;
@property (nonatomic) BOOL enableReply;
@property (nonatomic) BOOL enableSearch;
@property (nonatomic) BOOL enableBackButton;
@property (nonatomic) BOOL enableMessageButton;
@property (nonatomic) BOOL hidesBottomBarWhenPushed;

@property (nonatomic) BOOL e2eIndicator;


@property (copy, nonatomic) NSString *messageListTitle;
@property (copy, nonatomic) NSString *userListTitle;
@property (copy, nonatomic) NSString *createGroupTitle;
@property (copy, nonatomic) NSString *selectContactTitle;
@property (copy, nonatomic) NSString *selectGroupContactsTitle;
@property (copy, nonatomic) NSString *forwardTitle;

@property (copy, nonatomic) NSString *userOnlineIndicationTitle;
@property (copy, nonatomic) NSString *onlineIndicationTitle;
@property (copy, nonatomic) NSString *offlineIndicationTitle;
@property (copy, nonatomic) NSString *connectingIndicationTitle;
@property (copy, nonatomic) NSString *noNetworkIndicationTitle;
@property (copy, nonatomic) NSString *suspendedIndicationTitle;

@property (copy, nonatomic) NSString *groupDeletedTitle;
@property (copy, nonatomic) NSString *groupNotMemberTitle;


@property (copy, nonatomic) NSString *emptyUserListMessage;
@property (copy, nonatomic) UIFont *emptyUserListMessageFont;
@property (assign, nonatomic) int emptyUserListMessageColor;

@property (nonatomic) BOOL showRecentInForward;
@property (nonatomic) BOOL mConvertSmilyToEmoji;

@property (assign, nonatomic) int *mLetterTitleColors;
@property (assign, nonatomic) uint32_t mToolbarColor;
@property (assign, nonatomic) uint32_t mStatusBarColor;
@property (assign, nonatomic) uint32_t mToolbarTextColor;
@property (assign, nonatomic) uint32_t mUserListTypingIndicationColor;
@property (assign, nonatomic) uint32_t mUserListStatusColor;
@property (assign, nonatomic) uint32_t messageBackgroundColorForMe;
@property (assign, nonatomic) uint32_t messageBackgroundColorForPeer;
@property (assign, nonatomic) uint32_t messagingBackgroundColor;
@property (assign, nonatomic) uint32_t messageInputBackgroundColor;

@property (assign, nonatomic) int mediaButtonPosition;
@property (assign, nonatomic) int locationButtonPosition;
@property (assign, nonatomic) int docButtonPosition;
@property (assign, nonatomic) int audioButtonPosition;


@property (assign, nonatomic) uint64_t mMaxImageFileSize;
@property (assign, nonatomic) uint64_t mMaxVideoFileSize;

@property (assign, nonatomic) BOOL mEnableNotificationBadge;


@end


@interface MesiboUI : NSObject

+(void) launchEditGroupDetails:(id) parent groupid:(uint32_t) groupid;

+(UIViewController *) getMesiboUIViewController ;
+ (UIViewController *) getMesiboUIViewController:(id)uidelegate;

+(UIImage *) getDefaultImage:(BOOL) group;

+(void) launchMessageViewController:(UIViewController *) parent profile:(MesiboProfile*)profile ;

+(MesiboUiOptions *) getUiOptions;
+(void) setUiOptions:(MesiboUiOptions *)options;

+(void) launchMessageViewController:(UIViewController *) parent profile:(MesiboProfile*)profile uidelegate:(id)uidelegate;

+(void) showEndToEncEncryptionInfo:(UIViewController *) parent profile:(MesiboProfile*)profile;

+ (UIViewController *) getE2EViewController:(MesiboProfile *)profile ;

//+(void) getUITableViewInstance:(UITableViewWithReloadCallback *) table;

@end


#endif
