//
//  SettingsUtils.m
//  MesiboUI
//
//  Created by Mesibo on 28/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SettingsUtils.h"
#import <UIKit/UIKit.h>

@implementation SettingsUtils

+(UIStoryboard *)getMeSettingsStoryBoard {
    NSBundle *bundle = [NSBundle mainBundle];
    return [UIStoryboard storyboardWithName:SETTINGS_STORYBOARD bundle:bundle];
    
    
    
}
+(NSBundle *)getBundle {
    NSBundle *bundle = [NSBundle mainBundle];
    return bundle;
}

+ (UIImage *)imageNamed:(NSString *)imageName {
    NSBundle *  SettingsBundle = [SettingsUtils getBundle];
    return [UIImage imageNamed:imageName inBundle:SettingsBundle compatibleWithTraitCollection:nil];
}




@end
