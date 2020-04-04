//
//  AppUIManager.m
//  TestMesiboUIHelper
//
//  Created by Mesibo on 17/01/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "AppUIManager.h"
#import "ProfileViewerController.h"
#import "CommonAppUtils.h"
#import "SettingsViewController.h"
#import "EditSelfProfileViewController.h"
#import <MesiboUI/MesiboUI.h>
#import "Includes.h"

@implementation AppUIManager


+ (void) launchProfile:(id)parent profile:(MesiboUserProfile *)profile{
    UIStoryboard *storyboard = [CommonAppUtils getMeProfileStoryBoard];
    ProfileViewerController *pvc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileViewerController"];
    if([pvc isKindOfClass:[ProfileViewerController class]]) {
        pvc.mUserData = profile;
        //[parent presentViewController:pvc animated:YES completion:nil];
        [((UIViewController *)parent).navigationController pushViewController:pvc animated:YES];
        
    }
}

+ (void) launchSettings:(id)parent {
    UIStoryboard *storyboard = [CommonAppUtils getMeSettingsStoryBoard];
    SettingsViewController  *mtvc = [storyboard instantiateViewControllerWithIdentifier:@"SettingsViewController"];
    UINavigationController *unc = [[UINavigationController alloc] initWithRootViewController:mtvc];
    [parent presentViewController:unc animated:YES completion:nil];
}


+(void) launchEditProfile:(UIViewController*) RootController withMainWindow: (UIWindow*) mainWindow {
    UIStoryboard *storybord = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    EditSelfProfileViewController *editSelfProfileController =[storybord instantiateViewControllerWithIdentifier:@"EditSelfProfileViewController"];
    [editSelfProfileController setLaunchMesiboCallback:^{
        [AppUIManager launchMesiboUI:RootController withMainWindow:mainWindow];
    }];
    RootController = editSelfProfileController;
    [mainWindow setRootViewController:RootController];
    [mainWindow makeKeyAndVisible];
}

//UINavigationController *_mNavigationController = nil;
UIViewController *_mAppParent = nil;
+(void) setDefaultParent:(UIViewController *)controller {
    _mAppParent = controller;
}

+(void) launchVC_mainThread:(UIViewController *)parent vc:(UIViewController *)vc {
    
    if(!parent)
        parent = _mAppParent;
    
    
  
        [parent presentViewController:vc animated:YES completion:nil];
    
}

+(void) launchVC:(UIViewController *)parent vc:(UIViewController *)vc {
    
    if(vc.isBeingPresented)
        return;
    
    [MesiboInstance runInThread:YES handler:^{
        [self launchVC_mainThread:parent vc:vc];
    }];
}

+(void) launchMesiboUI:(UIViewController*) rootController withMainWindow: (UIWindow*) mainWindow {
    
    MesiboUiOptions *ui = [MesiboInstance getUiOptions];
    ui.emptyUserListMessage = @"No active conversations! Invite your family and friends to try mesibo.";
    
    UIViewController *old = mainWindow.rootViewController;

    
    UIViewController *mesiboController = [MesiboUI getMesiboUIViewController];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:mesiboController];
    rootController = navigationController;
    _mAppParent = rootController;
    [mainWindow setRootViewController:rootController];
    [mainWindow makeKeyAndVisible];
    
    //if(old)
        //[old dismissViewControllerAnimated:NO completion:nil];
}

+(void) showImageFile:(ImagePicker*) im withParentController:(id)Parent withImage:(UIImage*) image withTitle:(NSString *) title{
    [im showPhotoInViewer:Parent withImage:image withTitle:title];
}

+ (void) showImagesInViewer:(ImagePicker*) im withParentController:(id)Parent withImages:(NSArray*) imagepathArray withStartIndex:(int) index withTitle:(NSString *) title{
    [im showMediaFilesInViewer:Parent withInitialIndex:index withData:imagepathArray withTitle:title];

}

+ (void)  showEntireAlbum:(ImagePicker*) im withParentController:(id)Parent withAlbum:(NSMutableArray*) album withTitle:(NSString *) title{
    [im showMediaFiles:Parent withMediaData:album withTitle:title];

}

+ (void) pickImageData:(ImagePicker*)im withParent:(id)Parent withMediaType:(int)type withBlockHandler:(void(^)(ImagePickerFile *file))handler {
    if(nil == im){
        im = [ImagePicker sharedInstance];
    }
    
    im.mParent = Parent;
    [im pickMedia:type :handler];
    
}

+ (void) launchImageEditor:(ImagePicker*)im withParent:(id)Parent withImage:(UIImage *)image hideEditControls:(BOOL)hideControls withBlock: (MesiboImageEditorBlock)handler {
    if(nil == im){
        im = [ImagePicker sharedInstance];
    }
    
    im.mParent = Parent;
    [im getImageEditor:image title:@"Edit Picture" hideEditControl:hideControls showCaption:NO showCropOverlay:YES squareCrop:YES maxDimension:600 withBlock:handler];
    
}

+(UIImage *) getDefaultImage:(BOOL) group {
    return [MesiboUI getDefaultImage:group];
}

@end
