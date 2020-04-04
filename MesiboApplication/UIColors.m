//
//  MesiboColors.m
//  LogSup
//
//  Created by rkb on 9/19/17.
//  Copyright (c) 2015 _dinworx_. All rights reserved.
//

#import "UIColors.h"


@implementation UIColor (Extensions)


+ (UIColor *) titleColor0 {
    return hex2Rgb(TITLE_COLOR_0);
}
+ (UIColor *) titleColor1 {
    return hex2Rgb(TITLE_COLOR_1);
}
+ (UIColor *) titleColor2 {
    return hex2Rgb(TITLE_COLOR_2);
}
+ (UIColor *) titleColor3 {
    return hex2Rgb(TITLE_COLOR_3);
}
+ (UIColor *) titleColor4 {
    return hex2Rgb(TITLE_COLOR_4);
}
+ (UIColor *) titleColor5 {
    return hex2Rgb(TITLE_COLOR_5);
}
+ (UIColor *) titleColor6 {
    return hex2Rgb(TITLE_COLOR_6);
}
+ (UIColor *) titleColor7 {
    return hex2Rgb(TITLE_COLOR_7);
}

+(UIColor *) toastColor {
    return hex2Rgb(TOAST_COLOR);
}

+(UIColor *) pullRefreshColor {
    return hex2Rgb(PULLREFRESH_COLOR);
}


+(UIColor *) getColorView:(UInt32) color {
    if(USE_ALL_DEFAULT_COLOR)
        return [ UIColor whiteColor];
    if(color == USE_DEFAULT_COLOR)
        return [ UIColor whiteColor];
    
    
    return hex2Rgb(color);
}

+(UIColor *) getColorNavTtl:(UInt32) color {
    if(USE_ALL_DEFAULT_COLOR)
        return [ UIColor blackColor];
    if(color == USE_DEFAULT_COLOR)
        return [ UIColor blackColor];
    
    
    return hex2Rgb(color);
}
+(UIColor *) getColor:(UInt32) color {
    
    if(USE_ALL_DEFAULT_COLOR)
        return nil;
    if(color == USE_DEFAULT_COLOR)
        return nil;
    
    
    return [UIColor colorWithRed:((float)((color>>16)&0xFF))/255.0 green:((float)((color>>8)&0xFF))/255.0 blue:((float)((color)&0xFF))/255.0 alpha:((float)((color>>24)&0xFF))/255.0];
}


+ (UIColor *) toolBarColor {
    return [UIColor getColor:TOOLBAR_COLOR];
}



@end
