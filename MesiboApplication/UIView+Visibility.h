//
//  UIView+Visibility.h
//  UIView+Visibility
//
//  Created by neevek on 8/8/17.
//  Copyright (c) 2015 neevek. All rights reserved.
//

//#import "AppDelegate.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, UIViewVisibility) {
    UIViewVisibilityVisible,
    UIViewVisibilityInvisible,
    UIViewVisibilityGone
};

typedef NS_OPTIONS(NSUInteger, UIViewMarginDirection) {
    UIViewMarginDirectionNone       = 0,
    UIViewMarginDirectionTop        = 1 << 0,
    UIViewMarginDirectionLeft       = 1 << 1,
    UIViewMarginDirectionBottom     = 1 << 2,
    UIViewMarginDirectionRight      = 1 << 3,
    UIViewMarginDirectionAll        = UIViewMarginDirectionTop|UIViewMarginDirectionLeft|UIViewMarginDirectionBottom|UIViewMarginDirectionRight
};

@interface UIView(Visibility)

-(void)setVisibility:(UIViewVisibility)visibility;
-(void)setVisibility:(UIViewVisibility)visibility affectedMarginDirections:(UIViewMarginDirection)affectedMarginDirections;

@end
