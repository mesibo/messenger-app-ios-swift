//
//  UIAlerts.m
//  Mesibo
//
//  Created by rkb on 10/15/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "AppAlert.h"

@implementation AppAlert


+ (UIViewController*) topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

+ (void)showDialogue:(NSString*)message withTitle:(NSString *)title handler:(void (^) (void)) handler {
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction
                                    actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        
                                        [alert removeFromParentViewController];
                                        if(handler)
                                            handler();
                                        
                                    }];
    
    [alert addAction:defaultAction];
    
    
    UIViewController *vc = [AppAlert topMostController];
    
    if(vc) {
        [vc presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Delay 5 seconds
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *vc = [AppAlert topMostController];
        [vc presentViewController:alert animated:YES completion:nil];
    });
    
    
}

+ (void)showDialogue:(NSString*)message withTitle:(NSString *)title {
    [AppAlert showDialogue:message withTitle:title handler:nil];
}

@end
