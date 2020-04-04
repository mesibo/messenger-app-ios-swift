//
//  SamplePushKitNotify.h
//  MesiboApplication
//
//  Created by John on 31/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PushKit/PushKit.h>

@interface SamplePushKitNotify : NSObject <PKPushRegistryDelegate>
+(SamplePushKitNotify *)getInstance;
@end
