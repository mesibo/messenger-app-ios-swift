//
//  SettingsUtils.h
//  MesiboUI
//
//  Created by Mesibo on 28/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SETTINGS_STORYBOARD @"settings"

@interface SettingsUtils : NSObject

+(UIStoryboard *) getMeSettingsStoryBoard ;
+(NSBundle *)getBundle ;
+ (UIImage *)imageNamed:(NSString *)imageName;


@end
