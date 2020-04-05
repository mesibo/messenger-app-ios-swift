//
//  EditProfileViewController.m
//  MesiboUIHelper
//
//  Created by Mesibo on 03/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "EditSelfProfileViewController.h"

#import "Includes.h"
#import "AppAlert.h"
#import <MesiboUI/MesiboUI.h>
#import "SampleAPI.h"
#import "CommonAppUtils.h"
#import "UIManager.h"
#import <mesibo/mesibo.h>
#import "UIColors.h"
#import "MesiboMessenger-Swift.h"


#define TEXTVIEW_PLACEHOLDER @"Type status"
@interface EditSelfProfileViewController ()<UITextFieldDelegate, UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *mPhoneNumber;
@property (weak, nonatomic) IBOutlet UIImageView *mProfilePicture;
@property (weak, nonatomic) IBOutlet UIButton *mPictureEditBtn;
@property (weak, nonatomic) IBOutlet UILabel *mNameCharCounter;
@property (weak, nonatomic) IBOutlet UITextField *mNameTextField;
@property (weak, nonatomic) IBOutlet UITextView *mStatusTextView;
@property (weak, nonatomic) IBOutlet UIButton *mStatusCharCounter;
@property (weak, nonatomic) IBOutlet UIScrollView *mProfileScroller;
@property (weak, nonatomic) IBOutlet UIButton *mSaveBtn;

@end

#define MAX_NAME_CHAR_LIMIT     30
#define MIN_NAME_CHAR_LIMIT     3
#define MAX_STATUS_CHAR_LIMIT   150
#define MIN_STATUS_CHAR_LIMIT   3


@implementation EditSelfProfileViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view layoutIfNeeded];
    
    _mPictureEditBtn.layer.cornerRadius = _mPictureEditBtn.layer.frame.size.width/2;
    _mPictureEditBtn.layer.masksToBounds = YES;
    
    _mNameCharCounter.layer.cornerRadius = _mNameCharCounter.layer.frame.size.width/2;
    _mNameCharCounter.layer.masksToBounds = YES;
    
    _mNameTextField.delegate = self;
    _mStatusTextView.delegate = self;
    _mNameCharCounter.text = [NSString stringWithFormat:@"%d", MAX_NAME_CHAR_LIMIT];
    [_mStatusCharCounter setTitle:[NSString stringWithFormat:@"%d", MAX_STATUS_CHAR_LIMIT] forState:UIControlStateNormal];
    _mStatusTextView.text = TEXTVIEW_PLACEHOLDER;
    _mStatusTextView.textColor = [UIColor grayColor];
    
    _mStatusTextView.layer.borderColor = [UIColor grayColor].CGColor;
    _mStatusTextView.layer.borderWidth = 0.5;
    
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[CommonAppUtils imageNamed:@"ic_arrow_back_white.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backButtonPressed)forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, 24, 24)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = barButton;

    self.title = @"Edit Profile";
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPictureClicked)];
    singleTap.numberOfTapsRequired = 1;
    [_mProfilePicture setUserInteractionEnabled:YES];
    [_mProfilePicture addGestureRecognizer:singleTap];
    
    [self setProfilePicture];

    MesiboUserProfile *up = [MesiboInstance getSelfProfile];
    _mNameTextField.text = up.name;
    _mStatusTextView.text = up.status;
    _mPhoneNumber.text = up.address;
    
    _mSaveBtn.backgroundColor = [UIColor getColor:PRIMARY_COLOR];
    
    [[UIManager getInstance] addProgress:self.view];
    
}


- (void) backButtonPressed {
    [self.navigationController popViewControllerAnimated:YES ];
    
}

-(void)onPictureClicked{
    MesiboUserProfile *sp = [MesiboInstance getSelfProfile];
    if(!sp)
        return;
    
    NSString *picturePath = [MesiboInstance getProfilePicture:sp type:MESIBO_FILETYPE_AUTO];
    
    if(picturePath) {
        UIImage *image = [UIImage imageWithContentsOfFile:picturePath];
        ImagePicker *im = [ImagePicker sharedInstance];
        im.mParent = self;
        [MesiboUIManager showImageFile:im parent:self image:image title:sp.name];
    }
}

- (IBAction)saveSelfProfile:(id)sender {
    
    NSString *name = _mNameTextField.text;
    NSString *status = _mStatusTextView.text;
    
    MesiboUserProfile *sp = [MesiboInstance getSelfProfile];
    if(nil == sp) {
        [SampleAPIInstance logout:YES parent:nil];
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    if([SampleAPI equals:name old:sp.name] && [SampleAPI equals:status old:sp.status]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    
    if([name length] < MIN_NAME_CHAR_LIMIT) {
        [AppAlert showDialogue:@"Name should not be less than 3 charecters" withTitle:@"Change Name"];
        return;
    }
    
    /*
    if(_mStatusTextView.text.length < MIN_STATUS_CHAR_LIMIT || [_mStatusTextView.text isEqualToString:TEXTVIEW_PLACEHOLDER]) {
        [AppAlert showDialogue:@"Status should not be less than 3 charecters" withTitle:@"Change Status"];
        return;
    }
     */
    
    
    [[UIManager getInstance] showProgress];
    [SampleAPIInstance setProfile:name status:status groupid:0 handler:^(int result, NSDictionary *response) {
        
        [[UIManager getInstance] hideProgress];
        
        if(result==SAMPLEAPP_RESULT_OK && [[response objectForKey:@"result"] isEqualToString:@"OK"]) {
            
            sp.name = name;
            sp.status = status;
            [MesiboInstance setSelfProfile:sp];
            
            if(_mLaunchMesibo) {
                _mLaunchMesibo();
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
            
        } else {
            [AppAlert showDialogue:@"Unable to save. Check your internet connection and try again later!" withTitle:@"Failed "];

        }
    
    }];
    
}

-(void) setProfilePicture {
    
    MesiboUserProfile *up = [MesiboInstance getSelfProfile];
    
    NSString *path = [MesiboInstance getProfilePicture:up type:MESIBO_FILETYPE_AUTO];
    if(path)
        _mProfilePicture.image = [UIImage imageWithContentsOfFile:path];
    else
        _mProfilePicture.image = [MesiboUIManager getDefaultImage:NO];
    
    
    [_mProfilePicture layoutIfNeeded];
    //[_mProfilePicture setContentMode:UIViewContentModeScaleAspectFit];
    
    _mProfilePicture.layer.cornerRadius = _mProfilePicture.layer.frame.size.width/2;
    _mProfilePicture.layer.masksToBounds = YES;
    [_mProfilePicture layoutIfNeeded];
}

- (IBAction)changeProfilePicture:(id)sender {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Profile picture" message:@"Change your profile picture" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self pickMediaWithFiletype:PICK_CAMERA_IMAGE];
    }];
    
    UIAlertAction *galleryAction = [UIAlertAction actionWithTitle:@"Photo Albums" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self pickMediaWithFiletype:PICK_IMAGE_GALLERY];
        
    }];
    
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:@"Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [SampleAPIInstance setProfilePicture:nil groupid:0 handler:^(int result, NSDictionary *response) {
            [self setProfilePicture];
        }];
        
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        NSLog(@"You pressed button cancel");
        [alert removeFromParentViewController];
        
    }];
    
    [alert addAction:cameraAction];
    [alert addAction:galleryAction];
    [alert addAction:removeAction];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
    
    
    
}
- (void) pickMediaWithFiletype :(int)filetype{
    ImagePicker *im = [ImagePicker sharedInstance];
    im.mParent = self;
    
    [MesiboUIManager pickImageData:im withParent:self withMediaType:filetype withBlockHandler:^(ImagePickerFile *picker) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Returned data %@", [picker description]);
            [MesiboUIManager launchImageEditor:im parent:self image:picker.image hideEditControls:NO handler:^BOOL(UIImage *image, NSString *caption) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Your UI code //
                    //_mProfilePicture.image = image;
                    NSString *filePath = [MesiboInstance getFilePath:MESIBO_FILETYPE_IMAGE];
                    NSString *fileName = [NSString stringWithFormat:@"profile.jpg"];
                    NSString *path = [filePath stringByAppendingPathComponent:fileName];
                    //NSData *imageData = UIImagePNGRepresentation(image);
                    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
                    [imageData writeToFile:path atomically:YES];
                    
                    [[UIManager getInstance] showProgress];
                    
                    [SampleAPIInstance setProfilePicture:path groupid:0 handler:^(int result, NSDictionary *response) {
                        [[UIManager getInstance] hideProgress];
                        if(SAMPLEAPP_RESULT_OK == result) {
                            NSString *photo = [response valueForKey:@"photo"];
                            NSString *profilePath = [[MesiboInstance getFilePath:MESIBO_FILETYPE_PROFILEIMAGE] stringByAppendingPathComponent:photo];
                            [MesiboInstance renameFile:path destFile:profilePath forced:YES];
                            [self setProfilePicture];
                        }
                        
                    }];
                    
                });
                NSLog(@"message data %@",caption);
                return YES;
                
            }];
        });
        
    }];
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if(newText.length>MAX_NAME_CHAR_LIMIT) {
        return NO;
    }
    [_mNameCharCounter setText:[NSString stringWithFormat:@"%u", (uint32_t)(MAX_NAME_CHAR_LIMIT-newText.length)]];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if(newText.length>MAX_STATUS_CHAR_LIMIT) {
        return NO;
    }
    [_mStatusCharCounter setTitle:[NSString stringWithFormat:@"%u", (uint32_t) (MAX_STATUS_CHAR_LIMIT-newText.length)] forState:UIControlStateNormal];
    return YES;
}


- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIWindow *window = [[[UIApplication sharedApplication] windows]objectAtIndex:0];
    UIView *mainSubviewOfWindow = window.rootViewController.view;
    CGRect keyboardFrameConverted = [mainSubviewOfWindow convertRect:keyboardFrame fromView:window];
    
    
    CGFloat mKBHeight =keyboardFrameConverted.size.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, mKBHeight, 0.0);
    _mProfileScroller.contentInset = contentInsets;
    _mProfileScroller.scrollIndicatorInsets = contentInsets;

    if(_mStatusTextView.isFirstResponder) {
        CGRect aRect = self.view.frame;
        aRect.size.height -= mKBHeight;
        if (!CGRectContainsPoint(aRect, CGPointMake(0, CGRectGetMaxY(_mStatusTextView.frame)))) {
            [_mProfileScroller scrollRectToVisible:_mStatusTextView.frame animated:NO];
        }
    }
    if(_mNameTextField.isFirstResponder) {
                CGRect aRect = self.view.frame;
        aRect.size.height -= mKBHeight;
        if (!CGRectContainsPoint(aRect, CGPointMake(0, CGRectGetMaxY(_mNameTextField.frame)))) {
            [_mProfileScroller scrollRectToVisible:_mNameTextField.frame animated:NO];
        }
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:TEXTVIEW_PLACEHOLDER]) {
        textView.text = @"";
        textView.textColor = [UIColor darkGrayColor]; //optional
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = TEXTVIEW_PLACEHOLDER;
        textView.textColor = [UIColor grayColor]; //optional
    }
    [textView resignFirstResponder];
}

-(void)keyboardWillHide:(NSNotification *)notificatio {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _mProfileScroller.contentInset = contentInsets;
    _mProfileScroller.scrollIndicatorInsets = contentInsets;
}

- (BOOL)dismissKeyboard {
    
    if([_mStatusTextView isFirstResponder])
        [_mStatusTextView resignFirstResponder];
    if([_mNameTextField isFirstResponder])
        [_mNameTextField resignFirstResponder];
    
    return YES;
}


-(void) setLaunchMesiboCallback:(LaunchMesiboBlock)handler {
    _mLaunchMesibo = handler;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
