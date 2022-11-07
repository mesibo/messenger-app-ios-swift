//
//  ViewController.m
//  ProfileView


#import <QuartzCore/QuartzCore.h>
#import "ProfileViewerController.h"
#import "Includes.h"
#import "CommonAppUtils.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AppAlert.h"
//#import "UIManager.h"
#import "AppUIManager.h"
//#import "UIView+Visibility.h"
//#import "AddressBookViewController.h"
#import "MesiboMessengerSwift-Bridging-Header.h"
#import "MesiboMessenger-Swift.h"



// do not change it .........................
#define MINIMUM_PROFILE_PICTURE_HEIGHT 0
#define EXTRA_SPACE_FOR_SCROLLING 60
#define EXTRA_SPACE_FOR_BOTTOMSCROLLING 2000
#define PARALLAX_SCROLLING_SPEED 0.5
#define ALPHA_CHANGE_POINT_1 0.45
#define ALPHA_CHANGE_VALUE_2 0.35
#define MAX_MEDIA_FILE_THUMBNAIL_GALLERY 35
#define THUMBNAIL_GALLERY_SIZE 85
#define THUMBNAIL_LEFT_SPACE 10
#define THUMBNAIL_RIGHT_SPACE -5


@interface ProfileViewerController ()<UIScrollViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource, MesiboDelegate,  UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UIScrollView *mBottomScrollerProfileImage;
@property (weak, nonatomic) IBOutlet UIScrollView *mTopScrollerDetailVu;
@property (weak, nonatomic) IBOutlet UIImageView *mProfileImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mProfileImageHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mDetailVuHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mDetailVuYPosition;

@property (weak, nonatomic) IBOutlet UICollectionView *mMediaGallery;

@property (weak, nonatomic) IBOutlet UIView *mMediaCardView;
@property (weak, nonatomic) IBOutlet UIView *mNotificationView;
@property (weak, nonatomic) IBOutlet UIButton *mCallBtn;

@property (weak, nonatomic) IBOutlet UIButton *mOpenChat;
@property (weak, nonatomic) IBOutlet UILabel *mUserMobile;
@property (weak, nonatomic) IBOutlet UILabel *mUserPhoneType;

@property (weak, nonatomic) IBOutlet UILabel *mUserCurrentStatus;
@property (weak, nonatomic) IBOutlet UILabel *mUserCurrentStausUpdateTime;
@property (weak, nonatomic) IBOutlet UIView *mStatusPhoneCard;
@property (weak, nonatomic) IBOutlet UIView *mOpenFullGalleryView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mTopImageProfileHeight;
@property (weak, nonatomic) IBOutlet UIView *mTopImageProfileVu;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mStatusCardHeight;
@property (weak, nonatomic) IBOutlet UIView *mGroupMembersCard;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mGroupMemberCardHeight;
@property (weak, nonatomic) IBOutlet UITableView *mMembersTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mMembersTableHeight;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mEditMemberHeight;
@property (weak, nonatomic) IBOutlet UIButton *mShowMore;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mShowMoreHeightConstrain;
@property (weak, nonatomic) IBOutlet UIView *mAddtoContactsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mAddToContactsHeightConstraint;

@property (weak, nonatomic) IBOutlet UIButton *mExitBtn;
@property (weak, nonatomic) IBOutlet UIButton *mNewContactBtn;
@property (weak, nonatomic) IBOutlet UILabel *mLabel;

@property (weak, nonatomic) IBOutlet UIButton *mAddtoExistingBtn;
@property (weak, nonatomic) IBOutlet UIButton *meditBtn;

@end




@implementation ProfileViewerController

{
    CGFloat mScreenWidth;
    //CGFloat mCellWidth;
    CGFloat mMediaCardHeightValue;
    BOOL mFirstProfileLoad ;
    NSMutableArray *mAlbumGalleryData;
    NSMutableArray *mFavMediaFiles;
    AlbumsData *mImageAlbum;
    AlbumsData *mVideoAlbum;
    AlbumsData *mDocumentAlbum;
    NSMutableArray<MesiboGroupMember *> *mProfiles ;
    BOOL mAdmin;
    int mAdminCount;
    int mHeightOFModifyGroup;
    MesiboProfile *mUserProfile ;
    BOOL mExpandMembers;
    MesiboReadSession *mReadSession;
    MesiboGroupMember *mSelfMember;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    mSelfMember = nil;
    mUserProfile = [MesiboInstance getProfile:[_mUserData getAddress] groupid:[_mUserData getGroupId]];
    mAdmin = NO;
    mAdminCount = 1;
    
    mExpandMembers = NO;
    
    //_mStatusCardHeight.active = NO;
    mFavMediaFiles = [[NSMutableArray alloc] init];
    mAlbumGalleryData = [[NSMutableArray alloc]init];
    mProfiles = [[NSMutableArray alloc] init];
    
    //Initilize for image video and image gallery
    mImageAlbum = [[AlbumsData alloc]init];
    mImageAlbum.mAlbumName = @"Images";
    mImageAlbum.mPhotoGList = [[NSMutableArray alloc]init];
    mImageAlbum.mAlbumPhotoCount = 0;
    
    mVideoAlbum = [[AlbumsData alloc]init];
    mVideoAlbum.mAlbumName = @"Videos";
    mVideoAlbum.mPhotoGList = [[NSMutableArray alloc]init];
    mVideoAlbum.mAlbumPhotoCount = 0;
    
    mDocumentAlbum = [[AlbumsData alloc]init];
    mDocumentAlbum.mAlbumName = @"Documents";
    mDocumentAlbum.mPhotoGList = [[NSMutableArray alloc]init];
    mDocumentAlbum.mAlbumPhotoCount = 0;
    
    
    [mAlbumGalleryData addObject:mImageAlbum];
    [mAlbumGalleryData addObject:mVideoAlbum];
    [mAlbumGalleryData addObject:mDocumentAlbum];
    
    
    mFirstProfileLoad = YES;
    
    mMediaCardHeightValue = _mMediaCardHeight.constant;
    _mMediaCardHeight.constant = 0;
    _mMediaCardView.alpha = 0;
    [_mContentScrollView layoutIfNeeded];
    
    mScreenWidth = [UIScreen mainScreen].bounds.size.width;
    _mTopScrollerDetailVu.delegate = self;
    _mProfileImageHeight.constant = mScreenWidth;
    _mTopImageProfileHeight.constant = mScreenWidth;
    _mDetailVuYPosition.constant = mScreenWidth;
    // constatn 100 distance from top to accomodate name and status scroller wont scroll beyond that
    _mDetailVuHeight.constant = [UIScreen mainScreen].bounds.size.height -MINIMUM_PROFILE_PICTURE_HEIGHT;
    
    
    [MesiboInstance addListener:self ];
    
    mReadSession = [mUserProfile createReadSession:self];
    [mReadSession enableFiles:YES];
    [mReadSession read:100];
    
    
    NSString *getFullPath =  [mUserProfile getImageOrThumbnailPath];
    
    UIImage *profileImage = nil;
    if(getFullPath)
        profileImage = [UIImage imageWithContentsOfFile:getFullPath];
    else
        profileImage = [AppUIManager getDefaultImage:([mUserProfile getGroupId] > 0)];
    
    [_mProfileImageView setImage:profileImage];
    _mProfileImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    /////// Media Gallery /////////////////
    
    [self.view layoutIfNeeded];
    [_mMediaGallery setDataSource:self];
    [_mMediaGallery setDelegate:self];
    //mCellWidth = (mScreenWidth - 40) / 4;
    
    UICollectionViewFlowLayout *collectionViewFlowLayout = [[UICollectionViewFlowLayout alloc] init];
    [collectionViewFlowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    _mMediaGallery.collectionViewLayout = collectionViewFlowLayout;
    
    
    _mMediaGallery.pagingEnabled = NO;
    _mContentScrollView.scrollEnabled = NO;
    
    UITapGestureRecognizer *ProfileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openProfileImage:)];
    ProfileTap.numberOfTapsRequired=1;
    [_mTopImageProfileVu addGestureRecognizer:ProfileTap];
    
    UITapGestureRecognizer *linkTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMediaGallery)];
    linkTap.numberOfTapsRequired=1;
    [_mOpenFullGalleryView addGestureRecognizer:linkTap];
    
    [self fillUserData];
    
    if(0) {
    _mNotificationView.clipsToBounds = YES;
    [_mNotificationView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_mNotificationView addConstraint:[NSLayoutConstraint constraintWithItem:_mNotificationView
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:NSLayoutAttributeNotAnAttribute
                                                                 multiplier:1
                                                                   constant:0]];
     _mNotificationView.alpha = 0.0;
        
        
    }
    
    //[self hideView:_mCustomNotification];
    //[self hideView:_mViewBetweenMuteAndCustom];
    
    //[_mCustomNotification setVisibility:UIViewVisibilityGone affectedMarginDirections:UIViewMarginDirectionTop|UIViewMarginDirectionBottom];
    //[_mViewBetweenMuteAndCustom setVisibility:UIViewVisibilityGone affectedMarginDirections:UIViewMarginDirectionTop|UIViewMarginDirectionBottom];
    
    [_mNotificationView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    //_mCustomNotification.hidden = YES;
   // _mViewBetweenMuteAndCustom.hidden = YES;
    
    [_mMuteSwitch setOn:[mUserProfile isBlocked]];
    
    if([mUserProfile getGroupId] > 0) {
        
        _mAddToContactsHeightConstraint.constant = 0;
        [_mNewContactBtn setHidden:YES];
        [_mAddtoExistingBtn setHidden:YES];
        [_mLabel setHidden:YES];
        [_meditBtn setHidden:YES];
        
        _mAddToContactsHeightConstraint.constant = 0;
        [_mNewContactBtn setHidden:YES];
        [_mAddtoExistingBtn setHidden:YES];
        [_mLabel setHidden:YES];
        
        _mStatusPhoneCard.clipsToBounds = YES;
        [_mStatusPhoneCard setTranslatesAutoresizingMaskIntoConstraints:NO];
        [_mStatusPhoneCard addConstraint:[NSLayoutConstraint constraintWithItem:_mStatusPhoneCard
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1
                                                                       constant:0]];
        //_mModifyGroup.hidden = NO;
        _mStatusPhoneCard.alpha = 0.0;
        _mMembersTable.delegate = self;
        _mMembersTable.dataSource = self;
        
        
        UITapGestureRecognizer *addMemeberTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editGroupAndMemebers)];
        linkTap.numberOfTapsRequired=1;
        [_mAddMemberView addGestureRecognizer:addMemeberTap];
        
    }else {
        
        // profile is for user so remove group functionalities
        //_mModifyGroup.hidden = YES;
        _mGroupMemberCardHeight.constant = 0;
        _mGroupMembersCard.hidden = YES;
        
        if (![[mUserProfile getName] isEqual:[mUserProfile getAddress]] && [mUserProfile getName] != nil) {
            _mAddToContactsHeightConstraint.constant = 46;
            [_mNewContactBtn setHidden:YES];
            [_mAddtoExistingBtn setHidden:YES];
            [_mLabel setHidden:YES];
            [_meditBtn setHidden:NO];
            
        }
        else
        {
            [_meditBtn setHidden:YES];
        }
    }
    
    //hide editmemeber field for non admin member of group but save the details
    mHeightOFModifyGroup = _mEditMemberHeight.constant ;
    _mEditMemberHeight.constant = 0;
    _mAddMemberView.alpha = 0;
        
}

//This hides view and sets height to 0
-(void) hideView:(UIView *)view {
    view.clipsToBounds = YES;
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1
                                                                    constant:0]];
    view.alpha = 0.0;

}

- (BOOL) prefersStatusBarHidden {
    return YES;
}

- (void) uiChangeForAdmin {
    // special ui change for group admin
    _mEditMemberHeight.constant = mHeightOFModifyGroup;
    _mAddMemberView.alpha = 1;
    [_mExitBtn setTitle:@"Delete Group" forState:UIControlStateNormal];
    
}

-(void) reloadMembersTable {
    [MesiboInstance runInThread:YES handler:^{
        [_mMembersTable reloadData];
        _mMembersTableHeight.constant = _mMembersTable.contentSize.height;
        _mGroupMemberCardHeight.constant = _mMembersTableHeight.constant+170;
    }];
}

-(void) Mesibo_onProfileUpdated:(MesiboProfile *)profile  {
    
    
}

-(void) Mesibo_onGroupMembers:(MesiboProfile *) groupProfile members:(NSArray *)members {
    [self parseGroupMembers:members];
}

-(void) Mesibo_onGroupMembersJoined:(MesiboProfile *) groupProfile members:(NSArray *)members {
    for(MesiboGroupMember *m in members) {
        int i;
        for(i=0; i < mProfiles.count; i++) {
            MesiboGroupMember *p = mProfiles[i];
            if([SampleAPI equals:[m getAddress] old:[p getAddress]]) {
                [mProfiles removeObject:p];
                break;
            }
        }
        
        [mProfiles insertObject:m atIndex:i];
    }
    
    [self reloadMembersTable];
}

-(void) Mesibo_onGroupJoined:(MesiboProfile *)groupProfile {
    
}

-(void) Mesibo_onGroupError:(MesiboProfile *)groupProfile error:(uint32_t)error {
    
}


-(void) Mesibo_OnMessage:(MesiboMessage *)message {
    
    // when we see media data then show media card
    if(_mMediaCardHeight.constant == 0) {
        _mMediaCardView.alpha = 1;
        _mMediaCardHeight.constant = mMediaCardHeightValue;
        [_mMediaCardView layoutIfNeeded];
        [_mContentScrollView layoutIfNeeded];
        [self.view layoutIfNeeded];
    }
    
    MesiboFile *file = [message getFile];
    if(!file) return;
    
    // add data in horizontal picture gallery maximum 35 picturesd
    // fill structure [albumlist]....[photolist]
    if(mFavMediaFiles.count < MAX_MEDIA_FILE_THUMBNAIL_GALLERY) {
        [mFavMediaFiles addObject:file.path];
    }
    PhotoData *tempPhotoData = [[PhotoData alloc]init];
    AlbumsData *tempAlbumData ;
    
    tempPhotoData.mSourcePath = file.path;
    int index = file.type < 3 ?file.type-1: 2;
    tempAlbumData = [mAlbumGalleryData objectAtIndex:index];
    
    if(tempAlbumData.mPhotoGList.count == 0) {
        tempAlbumData.mAlbumProfilePicPath = file.path;
    }
    
    tempAlbumData.mAlbumPhotoCount++;
    [tempAlbumData.mPhotoGList addObject:tempPhotoData];
    _mMediaFileCounter.text = [NSString stringWithFormat:@"%d", (int) [mFavMediaFiles count]];
    [_mMediaGallery reloadData];
    
}

- (void) openProfileImage:(UITapGestureRecognizer *)sender{
    UIImage *image = [mUserProfile getImageOrThumbnail];
    
    if (image) {
        
        [AppUIManager showImageFile:[ImagePicker sharedInstance] withParentController:self withImage:image withTitle:[mUserProfile getName]];
    } else {
        //[AppAlert showDialogue:@"Profile image not found" withTitle:@"Missing Image"];
    }
    
}

- (void) openMediaGallery {
    
    // if data is there then only show it in medai viewer
    ImagePicker *im = [ImagePicker sharedInstance];
    for(int i=mAlbumGalleryData.count-1; i > 0 ; i--) {
        AlbumsData *albumData = [mAlbumGalleryData objectAtIndex:i];
        if(albumData.mPhotoGList.count==0)
            [mAlbumGalleryData removeObjectAtIndex:i];
    }
    if(mAlbumGalleryData.count >0)
        [AppUIManager showEntireAlbum:im withParentController:self withAlbum:mAlbumGalleryData withTitle:[mUserProfile getName]];
    
}

- (void) fillUserData{
    
    // fill other user data like status, profile image and all
    NSString *imagePath = [mUserProfile getImageOrThumbnailPath];
    
    UIImage *profileImage = [UIImage imageWithContentsOfFile:imagePath];
    if(nil != profileImage ) {
        _mProfileImageView.image = profileImage;
        
    }
    
    _mUserName.text = [mUserProfile getName];
    
    uint64_t lastSeen = [mUserProfile getLastSeen];
    NSString *onlineStatus = @"Online";
    _mUserActivityStatus.hidden = NO;
    
    if(lastSeen < 0) {
        _mUserActivityStatus.hidden = YES;
    } else if(lastSeen > 0) {

        if(lastSeen >= 2*24*3600) {
            onlineStatus = @"days ago";
            lastSeen = lastSeen/(24*3600);
        } else if(lastSeen >= 24*3600) {
            onlineStatus = @"yesterday";
            lastSeen = 0;
        } else if(lastSeen >= 7200 ){
            onlineStatus = @"hours ago";
            lastSeen = lastSeen/(3600);
        } else if(lastSeen >= 3600) {
            onlineStatus = @"an hour ago";
            lastSeen = 0;
        } else if(lastSeen >= 120) {
            onlineStatus = @"minutes ago";
            lastSeen = lastSeen/(60);
        } else {
            onlineStatus = @"a few moments before";
            lastSeen = 0;
        }
        
        if(lastSeen) {
            onlineStatus = [NSString stringWithFormat:@"Last seen %d %@", (int)lastSeen, onlineStatus];
        } else {
            onlineStatus = [NSString stringWithFormat:@"Last seen %@", onlineStatus];
        }
    }

    _mUserActivityStatus.text = onlineStatus;
    _mMediaFileCounter.text = [NSString stringWithFormat:@"%d", (int) [mFavMediaFiles count]];
    
    _mUserMobile.text= [NSString stringWithFormat:@"+%@",[mUserProfile getAddress]];
    //_mUserPhoneType.text=_mUserData.mUSerMobileType;
    _mUserPhoneType.text=@"Mobile";
    
    if([mUserProfile getStatus] != nil || [mUserProfile getStatus].length != 0) {
        _mUserCurrentStatus.text= [mUserProfile getStatus];
        _mUserCurrentStatus.numberOfLines = 4;
        //_mUserCurrentStausUpdateTime.text=_mUserData.mUserProfileStatusUpdated;
        //_mUserCurrentStausUpdateTime.text=@"10 hours before";
        _mUserCurrentStausUpdateTime.hidden = YES;
        _mStatusCardHeight.constant = 168.5;

        
    }else {
        _mUserCurrentStatus.hidden = YES;
        _mUserCurrentStausUpdateTime.hidden=YES;
        [_mUserCurrentStatus removeConstraints:[_mUserCurrentStatus constraints]];
        [_mUserCurrentStausUpdateTime removeConstraints:[_mUserCurrentStausUpdateTime constraints]];
        _mStatusLineView.hidden = YES;
        _mHideStatusViewConstrain.constant = 0;
        [_mStatusLineView removeConstraints:[_mStatusLineView constraints]];
        _mStatusCardHeight.constant = 90;

    }
    
    [_mBackButton layoutIfNeeded];
    [_mReportUserBtn layoutIfNeeded];
    _mReportUserBtn.layer.cornerRadius = _mReportUserBtn.layer.frame.size.height/2;
    _mReportUserBtn.layer.masksToBounds = YES;
    
    _mBackButton.layer.cornerRadius = _mBackButton.layer.frame.size.height/2;
    _mBackButton.layer.masksToBounds = YES;
    
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    if([mUserProfile getGroupId] > 0) {
        
        _mUserName.text = [mUserProfile getName];
        
        NSString *imagePath = [mUserProfile getImageOrThumbnailPath];
        
        UIImage *profileImage = [UIImage imageWithContentsOfFile:imagePath];
        if(nil != profileImage ) {
            _mProfileImageView.image = profileImage;
            
        }
        
        [[mUserProfile getGroupProfile] getMembers:100 restart:0 listener:self];
        
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

-(void) parseGroupMembers:(NSArray *)members {
    
    [mProfiles removeAllObjects];
           
    NSInteger count;
    if (mExpandMembers) {
        count = members.count;
        _mShowMoreHeightConstrain.constant = 0;
        [_mShowMore setHidden:YES];
    }
    else {
        if (members.count > 10) {
            count = 10;
            [_mShowMore setHidden:NO];
            _mShowMoreHeightConstrain.constant = 30;
        }
        else {
            count = members.count;
            [_mShowMore setHidden:YES];
            _mShowMoreHeightConstrain.constant = 0;
            
        }
    }
    
    NSString *phone = [SampleAPIInstance getPhone];
    for(int i=0; i < count; i++) {
        MesiboGroupMember *m = members[i];
        
        if([SampleAPI equals:phone old:[m getAddress]]) {
            mSelfMember = m;
            if([m isAdmin])
                [self uiChangeForAdmin];
        }
          
        
        [mProfiles addObject:m];
    }
    
    [self reloadMembersTable];
}

- (IBAction)backButtonPressed:(id)sender {
    [MesiboInstance removeListner:self];
    //[self  dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
    
}

- (IBAction)onMute:(id)sender {
    [mUserProfile toggleBlock];
    [mUserProfile save];
}


- (IBAction)reportUser:(id)sender {
    [self flagTheUser:nil];
}



- (IBAction)callToUser:(id)sender {
}

- (IBAction)messageTOUser:(id)sender {
    [self backButtonPressed:nil];
}

- (IBAction)showMore:(id)sender {
    mExpandMembers = YES;
    //[self parseGroupMembers];
    [self reloadMembersTable];
    _mContentScrollView.contentSize = CGSizeMake(_mContentScrollView.frame.size.width, _mGroupMemberCardHeight.constant+EXTRA_SPACE_FOR_SCROLLING+_mMediaCardHeight.constant);
}

- (IBAction)createNewContact:(id)sender {
    
}

- (IBAction)addToExistingContact:(id)sender {

}

- (IBAction)editContact:(id)sender {

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    int halfScreenwidth = (int)(mScreenWidth/2);
    
    if(mFirstProfileLoad) {
        mFirstProfileLoad = NO;
        // initial animated scrollling . .. . .
        [_mTopScrollerDetailVu setContentOffset:CGPointMake(0, halfScreenwidth) animated:YES];
        CGFloat contentSize = 0;
        
        if([mUserProfile getGroupId] ==0)
            contentSize = CGRectGetMaxY(_mStatusPhoneCard.frame) + EXTRA_SPACE_FOR_SCROLLING;
        else
            contentSize = CGRectGetMaxY(_mGroupMembersCard.frame) + EXTRA_SPACE_FOR_SCROLLING;
        
        _mContentScrollView.contentSize = CGSizeMake(_mContentScrollView.frame.size.width, contentSize);
        //_mBottomScrollerProfileImage.contentSize = CGSizeMake(_mContentScrollView.frame.size.width, EXTRA_SPACE_FOR_BOTTOMSCROLLING);
    }
    
    float shadowRadius = 0;  //2
    float shadowOpacity = 0; //0.5
    
    // just to give card effects in uiview
    _mMediaCardView.layer.masksToBounds = NO;
    _mMediaCardView.layer.masksToBounds = NO;
    _mMediaCardView.layer.shadowOffset = CGSizeMake(0, 00);
    _mMediaCardView.layer.shadowRadius = shadowRadius;
    _mMediaCardView.layer.shadowOpacity = shadowOpacity;
    
    _mNotificationView.layer.masksToBounds = NO;
    _mNotificationView.layer.masksToBounds = NO;
    _mNotificationView.layer.shadowOffset = CGSizeMake(0, 00);
    _mNotificationView.layer.shadowRadius = shadowRadius;
    _mNotificationView.layer.shadowOpacity = shadowOpacity;
    
    _mStatusPhoneCard.layer.masksToBounds = NO;
    _mStatusPhoneCard.layer.masksToBounds = NO;
    _mStatusPhoneCard.layer.shadowOffset = CGSizeMake(0, 00);
    _mStatusPhoneCard.layer.shadowRadius = shadowRadius;
    _mStatusPhoneCard.layer.shadowOpacity = shadowOpacity;
    
    _mGroupMembersCard.layer.masksToBounds = NO;
    _mGroupMembersCard.layer.masksToBounds = NO;
    _mGroupMembersCard.layer.shadowOffset = CGSizeMake(0, 00);
    _mGroupMembersCard.layer.shadowRadius = shadowRadius;
    _mGroupMembersCard.layer.shadowOpacity = shadowOpacity;
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // we do not want other scroller(tableview og groupmemeber) to interfear in scrolling mechanism
    if(scrollView.tag == 3000) //
        return;
    
    // there are top scroller and bottom scroller bottom scroller contains image profile
    // top scroller cotains content scroller inside it to show all contents in card view manner
    // both scroller are synchronised but only top scroller can move bottom scroller but vise versa is not true
    
    CGFloat topScrollOffset = scrollView.contentOffset.y;
    if (topScrollOffset < 0) {
        
        // Reset scrollers ....stop every scrolling when scrolling toward down in negative direction
        [_mTopScrollerDetailVu setContentOffset:CGPointMake(0, 0)];
        [_mBottomScrollerProfileImage setContentOffset:CGPointMake(0, 0)];
        [_mContentScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        _mContentScrollView.scrollEnabled = NO;
        
    } else if(topScrollOffset < (_mProfileImageHeight.constant -MINIMUM_PROFILE_PICTURE_HEIGHT)){
        // when scrolling is in betwwen 0 to (pictureheight -100) do scrolling , fade in image accrording to scrolling . .. content scrolling disabled
        
        _mContentScrollView.scrollEnabled = NO;
        //alpha mvalue manipulation to fade picture while scrolling we can do anything
        float alpha = 1 - ((float)(topScrollOffset /_mProfileImageHeight.constant));
        if(alpha < ALPHA_CHANGE_POINT_1)
            alpha = alpha + ALPHA_CHANGE_VALUE_2;
        else
            alpha = 1;
        _mProfileImageView.alpha = alpha;
        CGFloat bottomScrollOffsetY = topScrollOffset*PARALLAX_SCROLLING_SPEED;
        if(bottomScrollOffsetY)
            [_mBottomScrollerProfileImage setContentOffset:CGPointMake(0,bottomScrollOffsetY) animated:NO];
    }else {
        
        /// now stop all scroller scrolling but enable content scrolling . .. . .. .
        _mContentScrollView.scrollEnabled = YES;
        
        [_mTopScrollerDetailVu setContentOffset:CGPointMake(0, _mProfileImageHeight.constant -MINIMUM_PROFILE_PICTURE_HEIGHT)];
        [_mBottomScrollerProfileImage setContentOffset:CGPointMake(0, (_mProfileImageHeight.constant - MINIMUM_PROFILE_PICTURE_HEIGHT)*PARALLAX_SCROLLING_SPEED) animated:NO];
    }
}

#pragma mark UICollectionView

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [mFavMediaFiles count];
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    UIImageView *imageCell = [cell viewWithTag:133];
    UIImageView *playLayer = [cell viewWithTag:134];
    NSString *filePath = [mFavMediaFiles objectAtIndex:indexPath.row];
    if([CommonAppUtils isImageFile:filePath]) {
        playLayer.hidden = YES;
    }else {
        playLayer.hidden = NO;
    }
    UIImage *tempImage = [CommonAppUtils getBitmapFromFile:filePath];
    imageCell.image = tempImage ;
    imageCell.layer.cornerRadius = 10.0;
    imageCell.layer.masksToBounds = YES;
    return cell;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(nonnull UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    //top, left, bottom, right
    return UIEdgeInsetsMake(0, THUMBNAIL_LEFT_SPACE, 0, THUMBNAIL_RIGHT_SPACE);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(THUMBNAIL_GALLERY_SIZE, THUMBNAIL_GALLERY_SIZE);
    
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ImagePicker *im = [ImagePicker sharedInstance];
    int index = (int)indexPath.item;
    
    NSString *filePath = [mFavMediaFiles objectAtIndex:indexPath.row];
    int type = [MesiboInstance getFileType:filePath];
    
    if(type == MESIBO_FILETYPE_VIDEO) {
        [ImagePicker showFile:self path:filePath title:nil type:1];
        return;
    }
    
    if(type != MESIBO_FILETYPE_IMAGE) {
        [ImagePicker showFile:self path:filePath title:nil type:2];
        return;
    }
    
    [AppUIManager showImagesInViewer:im withParentController:self withImages:mFavMediaFiles withStartIndex:index withTitle:[mUserProfile getName]];
    
    //
    
}

+ (UIViewController*) topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    return topController;
}


- (void) flagTheUser:(id)sender {
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"Flag User" message:@"Redifine the relation with user" preferredStyle:UIAlertControllerStyleActionSheet];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        // Cancel button tappped.
        [actionSheet removeFromParentViewController];
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Spamming" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [actionSheet removeFromParentViewController];
        
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Inapropriate messages" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [actionSheet removeFromParentViewController];
        
    }]];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Block Contact" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [actionSheet removeFromParentViewController];
        //[AddressBookViewController launchNewContact:self phone:@"+123333333333333"];
        
    }]];
    // Present action sheet.
    [[ProfileViewerController topMostController] presentViewController:actionSheet animated:YES completion:nil];
    return;

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return  [mProfiles count];
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    static NSString * resueIdentifier = @"cells";
    
    cell = [tableView dequeueReusableCellWithIdentifier:resueIdentifier];
    if(cell==nil) {
        cell   = [[UITableViewCell alloc]
                  initWithStyle:UITableViewCellStyleDefault
                  reuseIdentifier:resueIdentifier];
    }
    MesiboGroupMember *gm = [mProfiles objectAtIndex:indexPath.row];
    MesiboProfile *mp = [gm getProfile];
    
    UIImageView *profileImageView =(UIImageView *) [cell viewWithTag:105];
    [profileImageView layoutIfNeeded];
    
    
    NSString *imagePath = [mp getImageOrThumbnailPath];
    UIImage *profileImage = [UIImage imageWithContentsOfFile:imagePath];
    if(!profileImage)
        profileImage = [AppUIManager getDefaultImage:NO];
    
    profileImageView.image = profileImage;
    
    profileImageView.layer.cornerRadius = 25;
    profileImageView.layer.masksToBounds = YES;
    
    UILabel *name = (UILabel *)[cell viewWithTag:101];
    name.text = [mp getName];
    
    UILabel *status = (UILabel*) [cell viewWithTag:102];
    status.text = [mp getStatus];
    UILabel *adminLabel = (UILabel*) [cell viewWithTag:103];
    
    if([gm isAdmin])
        adminLabel.alpha = 1;
    else
        adminLabel.alpha = 0;
    
    [adminLabel layoutIfNeeded];
    adminLabel.layer.cornerRadius = 7.0;
    adminLabel.layer.masksToBounds = YES;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MesiboGroupMember *gm = [mProfiles objectAtIndex:indexPath.row];

    MesiboProfile *memberProfile =[gm getProfile];
    
    //if(memberProfile == sp)
      //  return;
    
    // selected user is owner or non-admin, don't show menu
    if(![mSelfMember isAdmin]) {
        if([memberProfile isSelfProfile])
            return;
        
        [MesiboUI launchMessageViewController:self profile:memberProfile];
        return;
    }
    
    
    NSMutableArray *numbersArrayList = [NSMutableArray new];
    
    
    if(![gm isAdmin]) {
        [numbersArrayList addObject:@"Make Admin"];
    } else {
        [numbersArrayList addObject:@"Remove Admin"];
    }
    
    if(![memberProfile isSelfProfile]) {
        [numbersArrayList addObject:@"Delete Member"];
        [numbersArrayList addObject:@"Message"];
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Select an Action:"
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (int j =0 ; j<numbersArrayList.count; j++){
        NSString *titleString = numbersArrayList[j];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:titleString style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSArray *member = @[[memberProfile getAddress]];
            
            // toggle admin
            if(0 == j) {
                [[mUserProfile getGroupProfile] addMembers:member permissions:MESIBO_MEMBERFLAG_ALL adminPermissions:[gm isAdmin]?0:MESIBO_ADMINFLAG_ALL];
            }
            else if(j == 1) {
                [[mUserProfile getGroupProfile] removeMembers:member];
                [mProfiles removeObjectAtIndex:indexPath.row];
                [_mMembersTable reloadData];
            } else if(2 == j) {
                [MesiboUI launchMessageViewController:self profile:memberProfile];
            }
            
        }];
        //[action setValue:[[UIImage imageNamed:@"sample.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
        [alertController addAction:action];
    }
    
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action) {
                                                             [alertController removeFromParentViewController];
                                                         }];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}


- (void) editGroupAndMemebers {
    
    [MesiboUI launchEditGroupDetails:self groupid:[mUserProfile getGroupId]];
    return;
    
}

- (IBAction)deleteGroup:(id)sender {
    [[mUserProfile getGroupProfile] deleteGroup];
    
}


@end
