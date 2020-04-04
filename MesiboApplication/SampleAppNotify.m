//
//  SampleAppNotify.m
//  TestMesiboUI
//
//  Created by John on 24/03/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SampleAppNotify.h"

@implementation SampleAppNotify 

+(SampleAppNotify *)getInstance {
    static SampleAppNotify *myInstance = nil;
    if(nil == myInstance) {
        @synchronized(self) {
            if (nil == myInstance) {
                myInstance = [[self alloc] init];
                [myInstance initialize];
            }
        }
    }
    return myInstance;
}

-(void) initialize {
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              // Enable or disable features based on authorization.
                              NSLog(@"on Auth");
                          }];
    
}

-(void) notify_pre10:(int)type subject:(NSString *)subject message:(NSString *)message {
    if (YES /*|| application.applicationState == UIApplicationStateActive*/ ) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.userInfo = nil;
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.alertTitle = subject;
        localNotification.alertBody = message;
        localNotification.fireDate = nil; //[NSDate date];
        localNotification.applicationIconBadgeNumber = 1; // count
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

//https://developer.apple.com/reference/usernotifications/unusernotificationcenter?language=objc
//http://stackoverflow.com/questions/41845576/ios-10-how-to-show-incoming-voip-call-notification-when-app-is-in-background
-(void) notify:(int)type subject:(NSString *)subject message:(NSString *)message {
    if(![message length]) return;
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = subject;
    content.body = message;
    content.sound = [UNNotificationSound defaultSound];
    //Set Badge Number
    content.badge = @([[UIApplication sharedApplication] applicationIconBadgeNumber] + 1);
    content.categoryIdentifier = [NSString stringWithFormat:@"%d", type];

    
    // Deliver the notification in five seconds.
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"LocalNotification" content:content trigger:trigger];
    
    // Schedule the notification.
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"Notification Completed: %@", error);
    }];
    
}

-(void) notifyMessage:(MesiboParams *)params message:(NSString *)message {
    if(MESIBO_ORIGIN_REALTIME != params.origin || MESIBO_MSGSTATUS_OUTBOX == params.status)
        return;
    
    NSString *name = params.peer;
    if(params.profile) {
        if([params.profile isMuted])
            return;
            
        name = params.profile.name;
        
    }
    
    if(nil == name)
        return;
    
    if(params.groupProfile) {
        if([params.groupProfile isMuted])
            return;
        
        name = [NSString stringWithFormat:@"%@ @ %@", name, params.groupProfile.name];
    }
    
    
    [self notify:SAMPLEAPP_NOTIFYTYPE_MESSAGE subject:name message:message];
    return;

}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler{
    NSLog(@"User Info : %@",notification.request.content.userInfo);
    if([notification.request.content.categoryIdentifier isEqualToString:@"2"]) {
        completionHandler(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge);
    } else {
        completionHandler(0); // no foreground notifications
    }
    
}

//Called to let your app know which action was selected by the user for a given notification.
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler{
    NSLog(@"User Info : %@",response.notification.request.content.userInfo);
    completionHandler();
}


-(void) clear {
    
}

@end
