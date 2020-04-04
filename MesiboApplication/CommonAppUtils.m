//
//  MesiboCommonUtils.m
//  ProfileView
//
//  Created by Mesibo on 09/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "CommonAppUtils.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "Includes.h"

#define MESIBO_UI_BUNDLE @""
#define PROFILE_STORYBOARD @"profile"
#define PROFILE_BUNDLE @"MesiboUIResource"
#define SETTINGS_STORYBOARD @"settings"


@implementation CommonAppUtils

static NSString *mDefaultUserProfilePath ;
static NSString *mDefaultGroupProfilePath ;


+(UIStoryboard *)getMeProfileStoryBoard {
    
    NSBundle *bundle =[CommonAppUtils getBundle];
    return [UIStoryboard storyboardWithName:PROFILE_STORYBOARD bundle:bundle];
    
}

+(UIStoryboard *)getMeMesiboStoryBoard {
    NSBundle *bundle =[CommonAppUtils getBundle];
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Mesibo" bundle:bundle];
    return sb;
    
}
+(NSBundle *)getBundle {
    NSBundle *bundle = [NSBundle mainBundle];
    return bundle;
    
}


+ (UIImage*) getBitmapFromFile:(NSString*) checkFile {
    UIImage *image = nil;
    BOOL fileExist = [MesiboInstance fileExists:checkFile];
    if(fileExist) {
        if([self isImageFile:checkFile]) {
            image =  [UIImage imageWithContentsOfFile:checkFile];
        } else {
            NSURL *videoUrl = [NSURL fileURLWithPath:checkFile];
            image =[CommonAppUtils profileThumbnailImageFromURL:videoUrl];
        }
    }
    
    return image;
    
}

+ (BOOL) isImageFile:(NSString*) filePath {
    
    BOOL isimage = NO;
    CFStringRef fileExtension = (__bridge CFStringRef) [filePath pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    
    if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
        isimage = YES;
    }
    CFRelease(fileUTI);
    return isimage;
}

+ (UIImage *) profileThumbnailImageFromURL:(NSURL *)videoURL {
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL: videoURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    NSError *err = nil;
    CMTime requestedTime = CMTimeMake(1, 60);     // To create thumbnail image
    CGImageRef imgRef = [generator copyCGImageAtTime:requestedTime actualTime:NULL error:&err];
    NSLog(@"err = %@, imageRef = %@", err, imgRef);
    UIImage *thumbnailImage = [[UIImage alloc] initWithCGImage:imgRef];
    CGImageRelease(imgRef);    // MUST release explicitly to avoid memory leak
    
    return thumbnailImage;
}


+ (UIImage *)imageNamed:(NSString *)imageName {
    NSBundle *  SettingsBundle = [CommonAppUtils getBundle];
    return [UIImage imageNamed:imageName inBundle:SettingsBundle compatibleWithTraitCollection:nil];
}



+ (NSString*) getDefaultGroupProfilePath {
    if(nil == mDefaultGroupProfilePath) {
        mDefaultGroupProfilePath = [[CommonAppUtils getBundle] pathForResource :[NSString stringWithFormat:@"group"] ofType:@"png"];
        /*
        UIImage *imageToSave = [CommonAppUtils imageNamed:@"group"];
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSData * binaryImageData = UIImagePNGRepresentation(imageToSave);
        mDefaultGroupProfilePath = [basePath stringByAppendingPathComponent:@"DefaultGroupImage.png"];
        [binaryImageData writeToFile:mDefaultGroupProfilePath atomically:YES];*/
        
    }
    return mDefaultGroupProfilePath;
}
+ (NSString*) getDefaultProfilePath {
    if(nil == mDefaultUserProfilePath) {
        mDefaultUserProfilePath = [[CommonAppUtils getBundle] pathForResource :[NSString stringWithFormat:@"blank_profile"] ofType:@"png"];
        /*
        UIImage *imageToSave = [CommonAppUtils imageNamed:@"blank_profile"];
        NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString * basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSData * binaryImageData = UIImagePNGRepresentation(imageToSave);
        mDefaultUserProfilePath = [basePath stringByAppendingPathComponent:@"DefaultUserImage.png"];
        [binaryImageData writeToFile:mDefaultUserProfilePath atomically:YES];*/
        
    }
    return mDefaultUserProfilePath;
    
}


+(UIStoryboard *)getMeSettingsStoryBoard {
    NSBundle *bundle = [NSBundle mainBundle];
    return [UIStoryboard storyboardWithName:SETTINGS_STORYBOARD bundle:bundle];
    

}

BOOL shareInProgress = NO;
+(void)shareText:(NSString *)textToShare parent:(UIViewController *)parent {
    //NSArray *objectsToShare = @[textToShare, urlToShare];
    //NSArray *objectsToShare = @[textToShare];
    //NSArray *objectsToShare = [NSArray arrayWithObjects:textToShare, shareImage, urlToShare, nil];
    if(shareInProgress)
        return;
    
    shareInProgress = YES;
    NSArray *objectsToShare = [NSArray arrayWithObjects:textToShare, nil];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];
    
    activityVC.excludedActivityTypes = @[UIActivityTypePrint,  UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll]; //Exclude whichever aren't relevant
    
    // dispatch async is done to introduce some delay other wise it is giving following warning
    //http://stackoverflow.com/questions/25213152/warning-attempt-to-present-modaltableviewcontroller-on-maintableviewcontroller
    
    //dispatch_async(dispatch_get_main_queue(), ^ {
    [parent presentViewController:activityVC animated:YES completion:^ {
        shareInProgress = NO;
    }];
    //});
    
    //[parent presentViewController:activityVC animated:YES completion:nil];
}




@end
