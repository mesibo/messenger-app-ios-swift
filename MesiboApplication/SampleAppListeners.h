//
//  SampleAppListeners.h
//  TestMesiboUI
//
//  Created by John on 23/03/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mesibo/Mesibo.h"
#import "MesiboCall/MesiboCall.h"

#define SampleAppListenersInstance [SampleAppListeners getInstance]


@interface SampleAppListeners : NSObject <MesiboDelegate, MesiboCallDelegate>

+(SampleAppListeners *) getInstance;

@end
