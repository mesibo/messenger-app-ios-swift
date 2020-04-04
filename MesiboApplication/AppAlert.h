//
//  UIAlerts.h
//  Mesibo
//
//  Created by rkb on 10/15/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppAlert :NSObject


+ (void)showDialogue:(NSString*)message withTitle :(NSString *) title;
+ (void)showDialogue:(NSString*)message withTitle:(NSString *)title handler:(void (^) (void)) handler;
@end
