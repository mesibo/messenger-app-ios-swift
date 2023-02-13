//
//  MesiboCommonUtils.h
//  ProfileView
//
//  Created by Mesibo on 09/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface CommonAppUtils : NSObject



+ (UIImage*) getBitmapFromFile:(NSString*) checkFile;
+ (BOOL) isImageFile:(NSString*) filePath ;
+ (UIImage *) profileThumbnailImageFromURL:(NSURL *)videoURL;
+ (UIStoryboard *)getMeProfileStoryBoard ;
+ (UIStoryboard *) getMeMesiboStoryBoard ;
+ (NSBundle *)getBundle ;


+ (UIImage *)imageNamed:(NSString *)imageName;
+ (NSString*) getDefaultGroupProfilePath ;
+ (NSString*) getDefaultProfilePath;
+ (UIStoryboard *)getMeSettingsStoryBoard ;
+(void)shareText:(NSString *)textToShare parent:(UIViewController *)parent;

+ (void)styleLight:(UIView *)view;
@end
