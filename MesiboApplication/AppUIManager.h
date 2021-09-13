//
//  AppUIManager.h
//  TestMesiboUIHelper
//
//  Created by John Motiwala on 17/01/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <mesibo/mesibo.h>
#import <UIKit/UIKit.h>
#import <mesibouihelper/mesibouihelper.h>
#import "Includes.h"

@interface AppUIManager : NSObject

+(void)launchProfile:(id)parent profile:(MesiboProfile *)profile ;
+(void) launchSettings:(id)parent;
+(void) showImageFile:(ImagePicker*) im withParentController:(id)Parent withImage:(UIImage*) image withTitle:(NSString *) title;
+(void)  showImagesInViewer:(ImagePicker*) im withParentController:(id)Parent withImages:(NSArray*) imagepathArray withStartIndex:(int) index withTitle:(NSString *) title;
+(void)  showEntireAlbum:(ImagePicker*) im withParentController:(id)Parent withAlbum:(NSMutableArray*) imagepathArray withTitle:(NSString *) title;
+(void) pickImageData:(ImagePicker*)im withParent:(id)Parent withMediaType:(int)type withBlockHandler:(void(^)(ImagePickerFile *file))handler;
+(void) launchImageEditor:(ImagePicker*)im withParent:(id)Parent withImage:(UIImage *)image hideEditControls:(BOOL)hideControls withBlock: (MesiboImageEditorBlock)handler;
+(UIImage *) getDefaultImage:(BOOL) group;
+(void) setDefaultParent:(UIViewController *)controller;

@end
