//
//  UIManager.h
//  Mesibo
//
//  Created by John on 23/10/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define UIManagerInstance [UIManager getInstance]

@interface UIManager : NSObject


+(UIManager *)getInstance;


-(void) addProgress:(UIView *)view;
-(void) showProgress;
-(void) hideProgress;

-(BOOL) runningVersionAndAbove:(int)version;
@end
