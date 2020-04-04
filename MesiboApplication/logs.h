//
//  logs.h
//  MesiboApplication
//
//  Copyright © 2018 Mesibo. All rights reserved.

#ifndef logs_h
#define logs_h

#define __FILE_NAME__ [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String]

#ifdef DEBUG

#define Log( s, ... ) NSLog( @"MesiboLog:%s:%d %@", \
__FILE_NAME__, \
__LINE__, \
 [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#else

#define Log( s, ... )

#endif

#endif /* logs_h */
