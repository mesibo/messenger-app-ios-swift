//
//  NSDictionary+NilObject.m
//  MesiboDevel
//
//  Created by Mesibo on 12/03/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "NSDictionary+NilObject.h"

@implementation NSDictionary (NilObject)

-(id) objectForKeyOrNil:(id)aKey {
    id object = [self objectForKey:aKey];
    if (object == [NSNull null]) {
        return nil;
    }
    return object;
}
@end

