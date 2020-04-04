//
//  NSLayoutConstraint+Visibiltiy.m
//  UIView+Visibility
//
//  Created by neevek on 8/8/17.
//  Copyright (c) 2015 neevek. All rights reserved.
//

#import "NSLayoutConstraint+Visibiltiy.h"
#import <objc/runtime.h>

static const void *key = &key;

@implementation NSLayoutConstraint(Visibiltiy)

-(void)clear {
    if (self.constant != 0) {
        NSNumber *oldConstant = @(self.constant);
        self.constant = 0;
        objc_setAssociatedObject(self, &key, oldConstant, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

-(void)restore {
    NSNumber *oldConstant = objc_getAssociatedObject(self, &key);
    if (oldConstant) {
        self.constant = oldConstant.floatValue;
        objc_setAssociatedObject(self, &key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
