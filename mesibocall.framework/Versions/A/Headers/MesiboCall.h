//
//  MesiboCall.h
//  MesiboCall
//
//  Copyright © 2018 Mesibo. All rights reserved.
//
#pragma once

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Mesibo/Mesibo.h"

#define MESIBOCALL_NOTIFY_INCOMING  0
#define MESIBOCALL_NOTIFY_MISSED    4

#define MESIBOCALL_VIDEO_FIT_ZOOM        0
#define MESIBOCALL_VIDEO_FIT_LETTERBOX   1

#define MESIBOCALL_UI_STATE_SHOWINCOMING         1
#define MESIBOCALL_UI_STATE_SHOWINPROGRESS       2
#define MESIBOCALL_UI_STATE_SHOWCONTROLS         3

#define MESIBOCALL_HANGUP_REASON_USER       1
#define MESIBOCALL_HANGUP_REASON_REMOTE     2
#define MESIBOCALL_HANGUP_REASON_ERROR      3
#define MESIBOCALL_HANGUP_REASON_BACKGROUND      4

#define MESIBOCALL_CODEC_VP8           1
#define MESIBOCALL_CODEC_VP9           2
#define MESIBOCALL_CODEC_H264          4
#define MESIBOCALL_CODEC_H265          8
#define MESIBOCALL_CODEC_OPUS       0x100

#define MESIBOCALL_VIDEOSOURCE_CAMERADEFAULT        0
#define MESIBOCALL_VIDEOSOURCE_CAMERAFRONT          1
#define MESIBOCALL_VIDEOSOURCE_CAMERAREAR           2
#define MESIBOCALL_VIDEOSOURCE_SCREEN               4


@interface MesiboCallNotification : NSObject
@property (nonatomic) NSString * _Nullable title;
@property (nonatomic) NSString * _Nullable message;
@property (nonatomic) NSString * _Nullable answer;
@property (nonatomic) NSString * _Nullable hangup;
@property (nonatomic) BOOL vibrate;
@property (nonatomic) BOOL sound;
@property (nonatomic) int color;
@property (nonatomic) int duration;
@property (nonatomic) NSURL * _Nullable soundFileUrl;
- (id _Nonnull)initWith:(BOOL)video;
@end

@interface MesiboVideoProperties : NSObject
@property (nonatomic) BOOL enabled;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int fps;
@property (nonatomic) int bitrate; //kbps
@property (nonatomic) int quality;
@property (nonatomic) int codec;
@property (nonatomic) int source;
@property (nonatomic) float zoom;
@property (nonatomic) BOOL fitZoom;
@property (nonatomic) BOOL hardwareAcceleration;
@property (nonatomic) NSString * _Nullable fileName;
@end

@interface MesiboAudioProperties : NSObject
@property (nonatomic) BOOL enabled;
@property (nonatomic) int bitrate; //kbps
@property (nonatomic) int quality;
@property (nonatomic) int codec;
@property (nonatomic) BOOL speaker;
@property (nonatomic) BOOL disableEarpiece;
@end

@interface MesiboCallUiProperties : NSObject
@property (nonatomic) NSString * _Nullable title;
@property (nonatomic) UIImage * _Nullable userImage;
@property (nonatomic) UIImage * _Nullable userImageSmall;
@property (nonatomic) BOOL showScreenSharing;
@end

@interface MesiboCallProperties : NSObject

@property (nonatomic, weak) id _Nullable parent;
@property (nonatomic, weak) id _Nullable controller;
@property (nonatomic) MesiboUserProfile * _Nullable user;



@property (nonatomic) MesiboVideoProperties * _Nullable video;
@property (nonatomic) MesiboAudioProperties * _Nullable audio;
@property (nonatomic) MesiboVideoProperties * _Nullable record;

@property (nonatomic) MesiboCallUiProperties * _Nullable ui;
@property (nonatomic) MesiboCallNotification * _Nullable notify;
@property (nonatomic) id _Nullable other;

@property (nonatomic) int batteryLowThreshold; // 0 to disable


@property (nonatomic) BOOL autoAnswer;
@property (nonatomic) BOOL autoDetectAppState;
@property (nonatomic) BOOL disableSpeakerOnProximity;
@property (nonatomic) BOOL hideOnProximity;
@property (nonatomic) BOOL runInBackground;
@property (nonatomic) BOOL stopVideoInBackground;
@property (nonatomic) BOOL holdOnCellularIncoming;
@property (nonatomic) BOOL checkNetworkConnection;

@property (nonatomic) BOOL enableCallKit; // requires CallKit to be enabled first

@property (nonatomic) BOOL incoming;

-(void) reset:(BOOL)video;
-(id _Nonnull )initWith:(BOOL)video;
@end

@interface MesiboVideoView : UIView

-(void) setup;
-(void) enableHardwareScaler:(BOOL) enable;
-(void) enableOverlay:(BOOL) enable;
-(void) enablePip:(BOOL) enable;
-(void) enableMirror:(BOOL) enable;
-(void) scaleToFit:(BOOL) enable;
-(void) scaleToFill:(BOOL) enable;
-(void) zoom:(float)zoom;
-(BOOL) fitLetterBox:(CGRect)bounds;
-(BOOL) fitZoom:(CGRect)bounds;
-(BOOL) position:(int)size xpadding:(int)xpadding ypadding:(int)ypadding bounds:(CGRect)bounds;

//Private method - not for external use
-(void) setVideo:(nullable id)video;

@end

//

@class MesiboCallApi;
@class MesiboCallInProgressListener;
@class MesiboCallIncomingListener;

@protocol MesiboCallIncomingListener
-(MesiboCallProperties *_Nullable) MesiboCall_OnIncoming:(MesiboUserProfile *_Nonnull)profile video:(BOOL)video;
-(BOOL) MesiboCall_OnShowUserInterface:(id _Nullable )call properties:(MesiboCallProperties *_Nullable)cp;
-(BOOL) MesiboCall_OnNotify:(int)type profile:(MesiboUserProfile *_Nonnull)profile video:(BOOL)video;
-(void) MesiboCall_OnError:(MesiboCallProperties*_Nonnull)cp error:(int) error;
@end

@interface MesiboCallApi : NSObject

-(void)setListener:(_Nullable id)listener;
-(MesiboCallProperties *_Nullable) getCallProperties;

-(void) start:(_Nullable id) controller listner:(_Nullable id) listener;
-(void) answer:(BOOL) video;
//-(void) answer;
-(void) sendDTMF:(int) digit;
-(void) hangup;

-(void) switchCamera;
-(void) switchSource;
-(void) changeVideoFormat:(int)width height:(int)height framerate:(int)framerate;
-(void) setVideoSource:(int)source index:(int)index;
-(int) getVideoSource;

-(void) mute:(BOOL)audio video:(BOOL)video enabled:(BOOL)enabled;
-(BOOL) toggleAudioMute;
-(BOOL) toggleVideoMute;

-(void) setAudioDevice:(int) device enable:(BOOL) enable;
-(int) getActiveAudioDevice;
-(BOOL) toggleAudioDevice:(int)device;

-(void) setVideoView:(MesiboVideoView *_Nullable) v remote:(BOOL)remote;
-(MesiboVideoView *_Nullable) getVideoView:(BOOL)remote;
-(void) setVideoViewsSwapped:(BOOL)swapped;
-(BOOL) isVideoViewsSwapped;

-(uint64_t) getAnswerTime;
-(BOOL) isVideoCall;
-(BOOL) isIncoming;
-(BOOL) isCallInProgress;
-(BOOL) isLinkUp;
-(BOOL) isCallConnected;
-(BOOL) isAnswered;
-(BOOL) getMuteStatus:(BOOL)audio video:(BOOL)video remote:(BOOL)remote;

-(void) playInCallSound:(NSURL * _Nonnull)url volume:(float)volume loops:(int)loops;
-(void) stopInCallSound;

// ---------------------------------- private functions - DO NOT USE, they will be removed --------------------------------
-(void) setup:(MesiboCallProperties * _Nonnull)cp;
-(void) OnForeground;
-(void) OnBackground;
-(void) detach;
-(BOOL) isDetached;
-(id _Nonnull) getCallContext;
// --------------------------- end of private functions --------------------------------



@end


enum MesiboAudioDevice {MESIBO_AUDIODEVICE_SPEAKER, MESIBO_AUDIODEVICE_HEADSET, MESIBO_AUDIODEVICE_EARPIECE, MESIBO_AUDIODEVICE_BLUETOOTH, MESIBO_AUDIODEVICE_DEFAULT};

#define MESIBOCALL_SOUND_RINGING    0
#define MESIBOCALL_SOUND_BUSY       1

#define MESIBOCALL_ERROR_BUSY 1
#define MESIBOCALL_ERROR_NETWORK 2

#define MESIBOCALL_HANGUP_REASON_USER      1
#define MESIBOCALL_HANGUP_REASON_REMOTE    2
#define MESIBOCALL_HANGUP_REASON_ERROR     3

#define MESIBOCALL_UI_STATE_SHOWINCOMING        1
#define MESIBOCALL_UI_STATE_SHOWINPROGRESS      2
#define MESIBOCALL_UI_STATE_SHOWCONTROLS        3
#define MESIBOCALL_UI_STATE_ANSWERED            4


@protocol MesiboCallInProgressListener

@required
-(void) MesiboCall_OnSetCall:(id _Nonnull )controller call:(id _Nullable )call;
-(void) MesiboCall_OnMute:(MesiboCallProperties * _Nonnull)cp audio:(BOOL)audio video:(BOOL) video remote:(BOOL)remote;
-(BOOL) MesiboCall_OnPlayInCallSound:(MesiboCallProperties * _Nonnull)cp type:(int)type play:(BOOL) play;
-(void) MesiboCall_OnHangup:(MesiboCallProperties * _Nonnull)cp reason:(int)reason;
-(void) MesiboCall_OnStatus:(MesiboCallProperties * _Nonnull)cp status:(int) status video:(BOOL) video;
-(void) MesiboCall_OnAudioDeviceChanged:(MesiboCallProperties * _Nonnull)cp active:(int)active inactive:(int)inactive;
-(void) MesiboCall_OnVideoSourceChanged:(int)source index:(int) index;
-(void) MesiboCall_OnVideo:(MesiboCallProperties * _Nonnull)cp video:(MesiboVideoProperties * _Nonnull)video remote:(BOOL)remote;
-(void) MesiboCall_OnUpdateUserInterface:(MesiboCallProperties * _Nonnull)cp state:(int)state video:(BOOL)video enable:(BOOL)enable;
-(void) MesiboCall_OnOrientationChanged:(BOOL)landscape remote:(BOOL)remote;
-(void) MesiboCall_OnBatteryStatus:(BOOL)low remote:(BOOL)remote;
-(void) MesiboCall_OnDTMF:(MesiboCallProperties * _Nonnull)cp digit:(int)digit;
@optional

@end

#define MesiboCallInstance [MesiboCall getInstance]

typedef void (^MesiboPermissionBlock)(BOOL granted);

@interface MesiboCall : NSObject

+ (MesiboCall* _Nonnull) getInstance;
+ (id _Nonnull) startWith:(_Nullable id<MesiboCallIncomingListener>)listner name:(NSString * _Nonnull)appName icon:(UIImage * _Nullable)icon callKit:(BOOL)enabled;
-(MesiboCallApi *_Nullable) getActiveCall;
-(NSBundle * _Nullable) getResourceBundle;

-(void) setListener:(_Nonnull id<MesiboCallIncomingListener>) delegate;
-(void) start;
-(MesiboCallApi * _Nullable)call:(MesiboCallProperties * _Nonnull)cc;

-(BOOL) callUi:(MesiboCallProperties * _Nonnull)cc;
-(BOOL) callUi:(id _Nonnull)parent address:(NSString * _Nonnull)address video:(BOOL)video;
-(BOOL) callUiForExistingCall:(id _Nonnull)parent;

-(MesiboCallProperties * _Nonnull) createCallProperties:(BOOL)video;

-(BOOL) isAppInBackground;
-(BOOL) isCallKitAllowed; 
-(BOOL) enableCallKit:(BOOL)detectRegulatoryRestrictions icon:(UIImage *_Nonnull)icon;

+(UIImage * _Nullable) getImage:(NSBundle * _Nonnull)bundle name:(NSString * _Nonnull)name;
+(UIImage * _Nullable) getColoredImage:(NSBundle * _Nonnull)bundle name:(NSString * _Nonnull)name color:(UIColor * _Nullable)color;

+(BOOL) checkPermissions:(BOOL)video handler:(MesiboPermissionBlock _Nonnull) handler;

-(void) setDefaultUiParent:(id _Nonnull)parent;
-(void) setDefaultUiTitle:(NSString * _Nonnull)name;
-(NSString * _Nonnull) getDefaultUiTitle;

@end

