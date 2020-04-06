//
//  SampleAPI.m
//  MesiboDevel
//
//  Copyright © 2018 Mesibo. All rights reserved.
//  This file is for reference only and will be removed. Use BackendAPI.swift instead

#import "SampleAPI.h"
#import "Mesibo/Mesibo.h"
#import "NSDictionary+NilObject.h"
#import "ContactUtils/ContactUtils.h"

#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlaces/GooglePlaces.h>
#import "AppAlert.h"

#import "MesiboMessenger-Swift.h"

#define APNTOKEN_KEY @"apntoken"
#define GOOGLE_KEY  @"googlekey"
#define UPLOADURL_KEY  @"upload"
#define DOWNLOADURL_KEY  @"download"
#define INVITE_KEY  @"inivte"
#define CC_KEY  @"cc"


@interface SampleAPI ( /* class extension */ )
{
    NSUserDefaults *mUserDefaults;
    NSString *mToken, *mPhone, *mInvite, *mCc;
    uint64_t mContactTimestamp;
    SampleAPI_LogoutBlock mLogoutBlock;
    BOOL mSyncPending;
    BOOL mResetSyncedContacts;
    BOOL mAutoDownload;
    NSString *mDeviceType;
    NSString *mApnToken;
    NSString *mApiUrl;
    NSString *mUploadUrl;
    NSString *mDownloadUrl;
    int mApnTokenType;
    NSString *mGoogleKey;
    BOOL mApnTokenSent;
    BOOL mSyncStarted;
    BOOL mInitPhonebook;
    void (^mAPNCompletionHandler)(UIBackgroundFetchResult);
}

@end

@implementation SampleAPI

+(SampleAPI *)getInstance {
    #ifdef USE_SWIFT_API
    return BackendAPI.getInstance;
#endif
    static SampleAPI *myInstance = nil;
    if(nil == myInstance) {
        @synchronized(self) {
            if (nil == myInstance) {
                myInstance = [[self alloc] init];
                [myInstance initialize];
            }
        }
    }
    return myInstance;
}

-(BOOL) isValidUrl:(NSString *)url {
    return ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]);
}

-(void)initialize {
    
    mApnToken = nil;
    mApnTokenType = 0;
    mApnTokenSent = NO;
    mGoogleKey = nil;
    mInvite = nil;
    
    mApiUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MessengerApiUrl"];
    
    if (!mApiUrl || ![self isValidUrl:mApiUrl]) {
        NSLog(@"************* INVALID URL - set a valid URL in MessengerApiUrl field in Info.plist ************* ");
    }
    
    mGoogleKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GoogleMapKey"];
    if (!mGoogleKey || [mGoogleKey length] < 32) {
        NSLog(@"************* INVALID GOOGLE MAP KEY - set a valid Key in GoogleMapKey field in Info.plist ************* ");
    }
    
    mUserDefaults = [NSUserDefaults standardUserDefaults];
    mContactTimestamp = 0;
    mToken = [mUserDefaults objectForKey:@"token"];
    
    
    mPhone = nil;
    mCc = nil;
    mSyncPending = YES;
    mResetSyncedContacts = NO;
    mSyncStarted = NO;
    mInitPhonebook = NO;
    
    mDeviceType = [NSString stringWithFormat:@"%d", [MesiboInstance getDeviceType]];
    
    if([mToken length] > 0) {
        mContactTimestamp = [[mUserDefaults objectForKey:@"ts"] longLongValue];
        [self startMesibo:NO];
    }
}

-(void) setOnLogout:(SampleAPI_LogoutBlock)logOutBlock {
    mLogoutBlock = logOutBlock;
}

-(NSString *)getSavedValue:(NSString *)value key:(NSString *)key {
    if(value) {
        [MesiboInstance setKey:value value:key];
        return value;
    }
    
    return [MesiboInstance readKey:key];
}

#define SYNCEDCONTACTS_KEY @"syncedcontacts"

-(void) startMesibo:(BOOL) resetProfiles {
    
    [SampleAppListeners getInstance]; // will initiallize and register listener
    // early initialize for reverse lookup
    
    NSString *appdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    [MesiboInstance setPath:appdir];
    
    [MesiboInstance setAccessToken:[SampleAPIInstance getToken]];
    [MesiboInstance setDatabase:@"test.db" resetTables:resetProfiles?MESIBO_DBTABLE_PROFILES:0]; //TBD, change this after testing
    
    if(resetProfiles) {
        [ContactUtilsInstance reset];
        [MesiboInstance setKey:SYNCEDCONTACTS_KEY value:@""];
    }
    
    [self initAutoDownload];
    mCc = [self getSavedValue:mCc key:CC_KEY];
    
    if(mCc && [mCc intValue] > 0)
        [ContactUtilsInstance setCountryCode:[mCc intValue]];
    
    [GMSServices provideAPIKey:mGoogleKey];
    [GMSPlacesClient provideAPIKey:mGoogleKey];
    
    [MesiboInstance setSecureConnection:YES];
    [MesiboInstance start];
    
}


-(void) startSync {
    
    
    @synchronized (self) {
        if(!mSyncPending)
            return;
        
        mSyncPending = NO;
    }
    
    if(mResetSyncedContacts) {
        [ContactUtilsInstance reset];
        [MesiboInstance setKey:SYNCEDCONTACTS_KEY value:@""];
    }
    
    id thiz = self;
    [self getContacts:nil hidden:NO handler:^(int result, NSDictionary *response) {
            //update entire table after all groups added since UI doesn't add group messages unless profile present
            NSArray *contacts = (NSArray *)[response objectForKeyOrNil:@"contacts"];
        
            if([contacts count] > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MesiboInstance setProfile:nil refresh:YES];
                });
            }
        
            [thiz startContactSync];
    }];
}

-(void) onContactsChanged {
    mSyncPending = YES;
    [self startSync];
}

-(NSString *) getSyncedContacts {
    return [MesiboInstance readKey:SYNCEDCONTACTS_KEY];
}

-(void) saveSyncedContacts:(NSArray *) contacts {
    NSString *str = [ContactUtilsInstance synced:contacts type:CONTACTUTILS_SYNCTYPE_SYNC];
    [MesiboInstance setKey:SYNCEDCONTACTS_KEY value:str];
}

-(void) startContactSync {
    
    if(nil == self)
        return;
    
    @synchronized (self) {
    if(mSyncStarted)
        return;
    
    mSyncStarted = YES;
    }
    
    //TBD, we need to fix contact utils to run in this thread
    // We must run in UI thread else contact change is not triggered
    [MesiboInstance runInThread:YES handler: ^{
        __block NSMutableArray *mContacts = [NSMutableArray new];
        __block NSMutableArray *mDeletedContacts = [NSMutableArray new];
        
        [ContactUtilsInstance sync:^BOOL (PhonebookContact *c, int type) {
                             if(!c)
                                 return NO;
                             
                             if(CONTACTUTILS_SYNCTYPE_DELETE == type && c.phoneNumber) {
                                 MesiboUserProfile *profile = [MesiboInstance getProfile:c.phoneNumber groupid:0];
                                 if(profile)
                                     [MesiboInstance deleteProfile:profile refresh:NO forced:NO];
                                 
                                 [mDeletedContacts addObject:c.phoneNumber];
                                 return YES;
                             }
                             //NSLog(@"Contact: %@", c);
                             
                             NSString *selfPhone = [self getPhone];
                             if(selfPhone && c.phoneNumber && [selfPhone isEqualToString:c.phoneNumber]) {
                                 NSArray *selfarray = [NSArray arrayWithObject:c.phoneNumber];
                                 [self saveSyncedContacts:selfarray];
                                 return YES;
                             }
                             
                             if(c.phoneNumber)
                                 [mContacts addObject:c.phoneNumber];
                             
                             if(mContacts.count >= 200 || (nil == c.phoneNumber && mContacts.count > 0)) {
                                 
                                 
                                 if([self getContacts:mContacts hidden:NO handler:nil]) {
                                     //TBD. crash here
                                     @synchronized (self) {
                                         if(mContacts && [mContacts count] > 0)
                                             [mContacts removeAllObjects];
                                     }
                                     
                                 }
                                 else {
                                     return NO;
                                 }
                                 
                             }
                             
                             if(nil == c.phoneNumber && mDeletedContacts.count > 0) {
                                 [SampleAPIInstance deleteContacts:mDeletedContacts];
                                 [mDeletedContacts removeAllObjects];
                             }
                             
                             return YES;
                         }
         
                            ];
    }];
}

-(NSString *) getPhone {
    if(mPhone)
        return mPhone;
    
    MesiboUserProfile *u = [MesiboInstance getSelfProfile];
    if(!u) {
        //MUST not hapen
        return nil;
    }
    
    mPhone = u.address;
    return mPhone;
}

-(NSString *) getInvite {
    if(mInvite && [mInvite length] > 6)
        return mInvite;
    
    mInvite = [self getSavedValue:nil key:INVITE_KEY];
    return mInvite;
}

-(NSString *) getToken {
    if([SampleAPI isEmpty:mToken])
        return nil;
    
    return mToken;
}

-(NSString *) getApiUrl {
    return mApiUrl;
}

-(NSString *) getUploadUrl {
    if(mUploadUrl && [mUploadUrl length] > 6)
        return mUploadUrl;
    
    mUploadUrl = [self getSavedValue:nil key:UPLOADURL_KEY];
    return mUploadUrl;
}

-(NSString *) getDownloadUrl {
    if(mDownloadUrl && [mDownloadUrl length] > 6)
        return mDownloadUrl;
    
    mDownloadUrl = [self getSavedValue:nil key:DOWNLOADURL_KEY];
    return mDownloadUrl;
}

-(void)save {
    [mUserDefaults setObject:mToken forKey:@"token"];
    [mUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:mContactTimestamp] forKey:@"ts"];
    [mUserDefaults synchronize];
}

-(void) checkSyncFailure:(NSDictionary *)request {
    NSString *op = (NSString *)[request objectForKeyOrNil:@"op"];
    if([SampleAPI equals:op old:@"getcontacts"]) {
        mSyncPending = YES;
    }
}

-(BOOL) parseResponse:(NSString *)response request:(NSDictionary*)request handler:(SampleAPI_onResponse) handler {
    NSMutableDictionary *returnedDict = nil;
    NSString *op = nil;
    int result = SAMPLEAPP_RESULT_FAIL;
    
    NSError *jsonerror = nil;
    
    //MUST not happen
    if(nil == response)
        return YES;
    
    //LOGD(@"Data %@", [NSString stringWithUTF8String:(const char *)[data bytes]]);
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonerror];
    
    if (jsonerror != nil) {
        if(nil != handler)
            handler(result, nil);
        return YES;
    }
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        //LOGD(@"its an array!");
        //NSArray *jsonArray = (NSArray *)jsonObject;
        
    }
    else {
        //LOGD(@"its probably a dictionary");
        returnedDict = (NSMutableDictionary *)jsonObject;
    }
    
    if(nil == returnedDict) {
        if(nil != handler)
            handler(result, nil);
        
        [self checkSyncFailure:request];
        
        return YES;
        
    }
    
    //NSString *result = (NSString *)[returnedDict objectForKeyOrNil:@"result"];
    //NSString *subresult = (NSString *)[returnedDict objectForKeyOrNil:@"subresult"];
    op = (NSString *)[returnedDict objectForKeyOrNil:@"op"];
    NSString *res = (NSString *)[returnedDict objectForKeyOrNil:@"result"];
    if([res isEqualToString:@"OK"]) {
        result = SAMPLEAPP_RESULT_OK;
    } else {
        NSString *error = (NSString *)[returnedDict objectForKeyOrNil:@"error"];
        if([error isEqualToString:@"AUTHFAIL"]) {
            result = SAMPLEAPP_RESULT_AUTHFAIL;
            [self logout:YES parent:nil];
            return NO;
        }
    }
    
    int64_t serverts = (uint64_t) [[returnedDict objectForKeyOrNil:@"ts"] longLongValue];
    
    if(SAMPLEAPP_RESULT_OK != result) {
        if(nil != handler)
            handler(result, returnedDict);
        return NO;
    }
    
    NSString *temp = (NSString *)[returnedDict objectForKeyOrNil:@"invite"];
    if(temp && [temp length] >0) {
        mInvite = [self getSavedValue:temp key:INVITE_KEY];
    }
    
    NSDictionary *urls = (NSDictionary *)[returnedDict objectForKeyOrNil:@"urls"];
    if(urls) {
        mUploadUrl = [self getSavedValue:(NSString *)[urls objectForKeyOrNil:@"upload"] key:UPLOADURL_KEY];
        mDownloadUrl = [self getSavedValue:(NSString *)[urls objectForKeyOrNil:@"download"] key:DOWNLOADURL_KEY];
    }
    
    if([op isEqualToString:@"login"]) {
        mToken = (NSString *)[returnedDict objectForKeyOrNil:@"token"];
        mPhone = (NSString *)[returnedDict objectForKeyOrNil:@"phone"];
        mCc = (NSString *)[returnedDict objectForKeyOrNil:@"cc"];
        

        if(![SampleAPI isEmpty:mToken]) {
            mContactTimestamp = 0;
            [self save];
            
            mResetSyncedContacts = YES;
            mSyncPending = YES;
            [ContactUtilsInstance setCountryCode:[mCc intValue]];
            [ContactUtilsInstance reset];
            [MesiboInstance reset];
            
            
            //NO DB OP SHOULD BE HERE UNLESS DB is initialized
            [self startMesibo:MESIBO_DBTABLE_PROFILES];
            
            [self createContact:returnedDict serverts:serverts selfProfile:YES refresh:NO visibility:VISIBILITY_VISIBLE];
            
        }
        
    } else if([op isEqualToString:@"getcontacts"]) {
        NSArray *contacts = (NSArray *)[returnedDict objectForKeyOrNil:@"contacts"];
        
        int visibility = VISIBILITY_VISIBLE;
        NSString *h = [request objectForKey:@"hidden"];
        if(h && [h isEqualToString:@"1"]) {
            visibility = VISIBILITY_HIDE;
        }
        
        for(int i=0; i<contacts.count; i++) {
            NSDictionary *userDictionary = [contacts objectAtIndex:i];
            
            [self createContact:userDictionary serverts:serverts selfProfile:NO refresh:YES visibility:visibility];
        }
        
        if(contacts.count > 0) {
            [self save];
        }
        mResetSyncedContacts = NO;
        
            
        
    } else if([op isEqualToString:@"getgroup"] || [op isEqualToString:@"setgroup"]) {
        [self createContact:returnedDict serverts:serverts selfProfile:NO refresh:NO visibility:VISIBILITY_VISIBLE];
    } else if([op isEqualToString:@"editmembers"] || [op isEqualToString:@"setadmin"]) {
        uint32_t groupid = [[returnedDict objectForKeyOrNil:@"gid"] unsignedIntValue];
        if(groupid > 0) {
            MesiboUserProfile *u = [MesiboInstance getGroupProfile:groupid];
            if(u) {
                u.groupMembers = [returnedDict objectForKeyOrNil:@"members"];
                u.status = [self groupStatusFromMembers:u.groupMembers];
                [MesiboInstance setProfile:u refresh:NO];
            }
        }
    } else if([op isEqualToString:@"delgroup"]) {
        uint32_t groupid = [[returnedDict objectForKeyOrNil:@"gid"] unsignedIntValue];
        [self updateDeletedGroup:groupid];
    } else if([op isEqualToString:@"upload"]) {
        int profile = [[returnedDict objectForKeyOrNil:@"profile"] intValue];
        if(profile) {
            [self createContact:returnedDict serverts:serverts selfProfile:YES refresh:NO visibility:VISIBILITY_VISIBLE];
        }
        
    }
    
    if(handler)
        handler(result, returnedDict);
    
    return YES;
    
}


-(void) invokeApi:(NSDictionary *)post filePath:(NSString *)filePath handler:(SampleAPI_onResponse) handler {
    
    if(post) {
        [post setValue:mDeviceType forKey:@"dt"];
    }
    
    Mesibo_onHTTPProgress progressHandler = ^BOOL(MesiboHttp *http, int state, int progress) {
        
        /*
         if(nil != response) {
         NSArray *aArray = [response componentsSeparatedByString:@"op"];
         NSString *str1 = @"{\"op";
         NSString *str2 = [aArray objectAtIndex:1];
         response = [str1 stringByAppendingString:str2];
         }*/
        
        if(100 == progress && state == MESIBO_HTTPSTATE_DOWNLOAD) {
            [self parseResponse:[http getDataString] request:post handler:handler];
        }
        
        if(progress < 0) {
            NSLog(@"invokeAPI failed");
            [self checkSyncFailure:post];
            // 100 % progress will be handled by parseResponse
            if(nil != handler) {
                handler(SAMPLEAPP_RESULT_FAIL, nil);
            }
        }
        
        
        return YES;
        
    };
    
    MesiboHttp *http = [MesiboHttp new];
    http.url = [self getApiUrl];
    http.postBundle = post;
    http.uploadFile = filePath;
    http.uploadFileField = @"photo";
    http.listener = progressHandler;
    
    if(![http execute]) {
        
    }
    
}

+(BOOL) equals:(NSString *)s old:(NSString *)old {
    int sempty = (int) [s length];
    int dempty = (int) [old length];
    if(sempty != dempty) return NO;
    if(!sempty) return YES;
    
    return ([s caseInsensitiveCompare:old] == NSOrderedSame);
}

+(BOOL) isEmpty:(NSString *)string {
    if(/*[NSNull null] == string ||*/ nil == string || 0 == [string length])
        return YES;
    return NO;
}

-(NSString *) phoneBookLookup:(NSString *)phone {
    PhonebookContact *c = [ContactUtilsInstance lookup:phone returnCopy:NO];
    if(!c) return nil;
    
    return c.name;
}

-(void) updateDeletedGroup:(uint32_t)groupid {
    if(!groupid) return;
    
    MesiboUserProfile *u = [MesiboInstance getGroupProfile:groupid];
    if(!u) return;
    u.flag |= MESIBO_USERFLAG_DELETED;
    u.status = @"Not a group member";
    [MesiboInstance setProfile:u refresh:NO];
}

//TBD, this should be generated dynamically
-(NSString *) groupStatusFromMembers:(NSString*) members {
    if([SampleAPI isEmpty:members])
        return nil;
    
    NSArray *s = [members componentsSeparatedByString: @":"];
    if(!s || s.count < 2)
        return nil;
    
    NSArray *users = [s[1] componentsSeparatedByString: @","];
    if(!users)
        return nil;
    
    NSString *status = @"";
    
    for(int i=0; i < users.count; i++) {
        if(![SampleAPI isEmpty:status]) {
            status = [status stringByAppendingString:@", "];
        }
        
        NSString *p = [self getPhone];
        if(p && [p isEqualToString:users[i]]) {
            status = [status stringByAppendingString:@"You"];
        } else {
            MesiboUserProfile *u = [MesiboInstance getUserProfile:users[i]];
            if(u)
                [MesiboInstance lookupProfile:u source:2];
            
            if(u && u.name)
                status = [status stringByAppendingString:u.name];
            else
                status = [status stringByAppendingString:users[i]];
        }
        
        if([status length] > 32)
            break;
    }
    
    return status;
}

-(void) createContact:(NSDictionary *)response serverts:(int64_t)serverts selfProfile:(BOOL)selfProfile refresh:(BOOL)refresh visibility:(int)visibility {
    NSString *name = [response objectForKeyOrNil:@"name"];
    NSString *phone = [response objectForKeyOrNil:@"phone"];
    NSString *status = [response objectForKeyOrNil:@"status"];
    NSString *photo = [response objectForKeyOrNil:@"photo"];
    NSString *members = [response objectForKeyOrNil:@"members"];
    
    
    if(![photo isKindOfClass:[NSString class]])
        photo = @"";
    
    uint32_t groupid = 0;
    if(!selfProfile) {
        groupid = [[response objectForKeyOrNil:@"gid"] unsignedIntValue];
        if(groupid)
            phone = @"";
    }
    
    if([SampleAPI isEmpty:phone] && 0 == groupid) {
        return;
    }
    
    int64_t timestamp = (uint64_t) [[response objectForKeyOrNil:@"ts"] longLongValue];
    if(!selfProfile && timestamp > mContactTimestamp)
        mContactTimestamp = timestamp;
    
    NSString *tn = [response objectForKeyOrNil:@"tn"];
    
    [self createContact:name phone:phone groupid:groupid status:status members:members photo:photo tnbase64:tn ts:timestamp when:(serverts-timestamp) selfProfile:selfProfile refresh:refresh visibility:visibility];
}


-(void) createContact:(NSString *)name phone:(NSString *)phone groupid:(uint32_t)groupid status:(NSString *)status members:(NSString *)members photo:(NSString *)photo tnbase64:(NSString *)tnbase64 ts:(uint64_t)ts when:(int64_t)when selfProfile:(BOOL)selfProfile refresh:(BOOL)refresh visibility:(int)visibility {
    
    MesiboUserProfile *u = [[MesiboUserProfile alloc] init];
    u.address = phone;
    u.groupid = groupid;
    if(selfProfile) {
        u.groupid = 0;
        groupid = 0;
    }
    
    if(!selfProfile && 0 == u.groupid) {
        u.name = [self phoneBookLookup:phone];
    }
    
    if([SampleAPI isEmpty:u.name]) {
        u.name = name;
    }
    
    if([SampleAPI isEmpty:u.name]) {
        u.name = phone;
        if([SampleAPI isEmpty:u.name]) {
            u.name = [NSString stringWithFormat:@"Group-%d", groupid];
        }
    }
    
    if(0 == u.groupid && ![SampleAPI isEmpty:phone] && [phone isEqualToString:@"0"]) {
        //debug
        u.name = @"Hello - debug";
        return;
    }
    
    u.status = status;
    if(u.groupid) {
        u.groupMembers = members;
        NSString *phone = [self getPhone];
        if(!phone) {
            return;
        }
        if(![members containsString:phone]) {
            [self updateDeletedGroup:groupid];
            return;
        }
        u.status = [self groupStatusFromMembers:members];
    }
    
    if(!u.status) {
        u.status = @"";
    }
    
    u.picturePath = photo;
    u.timestamp = ts;
    if(!selfProfile &&  ts > 0 && u.timestamp > mContactTimestamp)
        mContactTimestamp = u.timestamp;
    
    if(when >= 0) {
        u.lastActiveTime = [MesiboInstance getTimestamp] - (when*100);
    }
    
    if([tnbase64 length] > 3) {
        NSData *tnData = [[NSData alloc] initWithBase64EncodedString:tnbase64 options:0];
        if(tnData && [tnData length] > 100) {
            NSString *imagePath = [MesiboInstance getFilePath:MESIBO_FILETYPE_PROFILETHUMBNAIL];
            if([MesiboInstance createFile:imagePath fileName:u.picturePath data:tnData overwrite:YES]) {
            }
        }
    }
    
    if(VISIBILITY_HIDE == visibility) {
        u.flag |= MESIBO_USERFLAG_HIDDEN;
    } else if(VISIBILITY_UNCHANGED == visibility) {
        MesiboUserProfile *tp = [MesiboInstance getProfile:u.address groupid:u.groupid];
        if(tp && (tp.flag&MESIBO_USERFLAG_HIDDEN)) {
            u.flag |= MESIBO_USERFLAG_HIDDEN;
        }
    }
    
    if(selfProfile) {
        mPhone = u.address;
        [MesiboInstance setSelfProfile:u];
    }
    else
        [MesiboInstance setProfile:u refresh:refresh];
    
}

-(void) startLogout:(SampleAPI_onResponse) handler {
    if(nil == mToken)
        return;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"logout" forKey:@"op"];
    
    //even if token value is wrong, logout will happen due to AUTHFAIL
    [post setValue:mToken forKey:@"token"];
    
    [self invokeApi:post filePath:nil handler:handler];
    return;
}

-(void) logout:(BOOL)forced parent:(id)parent {
    if(!forced) {
        [self startLogout:^(int result, NSDictionary *response) {
            if(MESIBO_RESULT_OK == result)
                [self logout:YES parent:parent];
        }];
        return;
    }
    
    [MesiboInstance setKey:APNTOKEN_KEY value:@""];
    [MesiboInstance stop];
    mApnTokenSent = NO;
    mToken = @"";
    mPhone = nil;
    mCc = nil;
    mContactTimestamp = 0;
    [self save];
    [MesiboInstance reset];
    
    if(nil != mLogoutBlock)
        mLogoutBlock(parent);
    
}

-(void) login:(NSString *)phone code:(NSString *)code handler:(SampleAPI_onResponse) handler {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"login" forKey:@"op"];
    [post setValue:phone forKey:@"phone"];
    if(nil != code) {
        [post setValue:code forKey:@"code"];
    }
    
    NSString *packageName = [[NSBundle mainBundle] bundleIdentifier];
    [post setValue:packageName forKey:@"appid"];
    
    [self invokeApi:post filePath:nil handler:handler];
}

-(BOOL) setProfile:(NSString*)name status:(NSString*)status groupid:(uint32_t)groupid handler:(SampleAPI_onResponse) handler {
    if(nil == mToken || mToken.length == 0)
        return NO ;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"profile" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    [post setValue:name forKey:@"name"];
    [post setValue:status forKey:@"status"];
    [post setValue:[@(groupid) stringValue]  forKey:@"gid"];
    
    [self invokeApi:post filePath:nil handler:handler];
    return YES;
}

-(BOOL) setProfilePicture:(NSString *)filePath groupid:(uint32_t)groupid handler:(SampleAPI_onResponse)handler {
    if(nil == mToken || mToken.length == 0)
        return NO ;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"upload" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    [post setValue:[@(0) stringValue] forKey:@"mid"];
    [post setValue:[@(1) stringValue] forKey:@"profile"];
    [post setValue:[@(groupid) stringValue]  forKey:@"gid"];
    
    if([SampleAPI isEmpty:filePath]) {
        filePath = nil;
        [post setValue:[@(1) stringValue] forKey:@"delete"];
    }
    
    [self invokeApi:post filePath:filePath handler:handler];
    return YES;
}

-(NSString *) fetch:(NSDictionary *)post filePath:(NSString *) filePath {
    MesiboHttp *http = [MesiboHttp new];
    http.url = [self getApiUrl];
    http.postBundle = post;
    http.uploadFile = filePath;
    http.uploadFileField = @"photo";
    
    if([http executeAndWait]) {
        return [http getDataString];
    }
    
    return nil;
}


-(BOOL) getContacts:(NSArray *)contacts hidden:(BOOL)hidden handler:(SampleAPI_onResponse) handler {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"getcontacts" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    
    if(hidden && (!contacts || [contacts count] == 0))
        return NO;
    
    [post setValue:(hidden?@"1":@"0") forKey:@"hidden"];
    
    if(!hidden && mResetSyncedContacts) {
        [post setValue:@"1" forKey:@"reset"];
        mContactTimestamp = 0;
    }
    
    [post setValue:[NSNumber numberWithUnsignedLongLong:mContactTimestamp] forKey:@"ts"];
    if(contacts && contacts.count > 0) {
        NSString *string = [contacts componentsJoinedByString:@","];
        [post setValue:string forKey:@"phones"];
    }
    if(handler)
        [self invokeApi:post filePath:nil handler:handler];
    else {
        NSString *response = [self fetch:post filePath:nil];
        if(!response) {
            //TBD, if response nil due to network error, we must retry later
            return NO;
        }
        
        BOOL rv = [self parseResponse:response request:post handler:handler];
        if(contacts && rv) {
            [self saveSyncedContacts:contacts];
        }
        
        return rv;
    }
    return YES;
}

-(BOOL) deleteContacts:(NSArray *)contacts {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"delcontacts" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    
    if(contacts && contacts.count > 0) {
        NSString *string = [contacts componentsJoinedByString:@","];
        [post setValue:string forKey:@"phones"];
    }
    
    NSString *response = [self fetch:post filePath:nil];
    if(!response) {
        //TBD, if response nil due to network error, we must retry later
        return NO;
    }
    
    BOOL rv = [self parseResponse:response request:post handler:nil];
    if(contacts && rv) {
        
        [ContactUtilsInstance synced:contacts type:CONTACTUTILS_SYNCTYPE_DELETE];
    }
    
    return rv;
}

-(BOOL) setGroup:(MesiboUserProfile *)profile members:(NSArray *)members handler:(SampleAPI_onResponse)handler {
    if(nil == mToken)
        return NO;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"setgroup" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    
    if(profile.groupid)
        [post setValue:[@(profile.groupid) stringValue] forKey:@"gid"];
    
    if(profile.name)
        [post setValue:profile.name forKey:@"name"];
    if(profile.status)
        [post setValue:profile.status forKey:@"status"];
    
    if(members && members.count > 0) {
        NSString *string = [members componentsJoinedByString:@","];
        [post setValue:string forKey:@"m"];
    }
    
    [self invokeApi:post filePath:profile.picturePath handler:handler];
    
    return YES;
}

-(BOOL) deleteGroup:(uint32_t) groupid handler:(SampleAPI_onResponse) handler {
    if(nil == mToken || 0 == groupid)
        return NO;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"delgroup" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    [post setValue:[@(groupid) stringValue] forKey:@"gid"];
    
    [self invokeApi:post filePath:nil handler:handler];
    return YES;
}

-(BOOL) getGroup:(uint32_t) groupid handler:(SampleAPI_onResponse) handler {
    if(nil == mToken || 0 == groupid)
        return NO;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"getgroup" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    [post setValue:[@(groupid) stringValue] forKey:@"gid"];
    
    [self invokeApi:post filePath:nil handler:handler];
    return YES;
}

-(BOOL) editMemebers:(uint32_t) groupid removegroup:(BOOL)remove members:(NSArray *)members handler:(SampleAPI_onResponse) handler {
    if(nil == mToken || 0 == groupid || nil == members)
        return NO;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"editmembers" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    [post setValue:[@(groupid) stringValue] forKey:@"gid"];
    [post setValue:[@(remove?1:0) stringValue] forKey:@"delete"];
    
    if(members.count > 0) {
        NSString *string = [members componentsJoinedByString:@","];
        [post setValue:string forKey:@"m"];
    }
    
    [self invokeApi:post filePath:nil handler:handler];
    
    return YES;
}

-(BOOL) setAdmin:(uint32_t) groupid members:(NSString *)members admin:(BOOL)admin handler:(SampleAPI_onResponse) handler {
    if(nil == mToken || 0 == groupid || nil == members)
        return NO;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"setadmin" forKey:@"op"];
    [post setValue:mToken forKey:@"token"];
    [post setValue:[@(groupid) stringValue] forKey:@"gid"];
    [post setValue:[@(admin?1:0) stringValue] forKey:@"admin"];
    [post setValue:members forKey:@"m"];
    
    [self invokeApi:post filePath:nil handler:handler];
    
    return YES;
}

-(void) sendAPNToken {
    //first check in non-synronized stage. If this is called in response to sendAPNToken request itself, mApnTokenSent will be set and it will return so it can't go recursive
    if(!mApnToken || mApnTokenSent)
        return;
    
    if(nil == mToken || [mToken length] == 0)
        return;
    
    @synchronized (self) {
        if(mApnTokenSent)
            return;
        mApnTokenSent = YES; // so that next time it will not be called
    }
    
    [MesiboInstance setPushToken:mApnToken];
}

-(void) addContacts:(NSArray *)profiles hidden:(BOOL)hidden {
    NSMutableArray *addresses = [NSMutableArray new];
    
    for(int i=0; i < profiles.count; i++) {
        MesiboUserProfile *profile = (MesiboUserProfile *)[profiles objectAtIndex:i];
        if(profile.address && (profile.flag&MESIBO_USERFLAG_TEMPORARY) && !(profile.flag&MESIBO_USERFLAG_PROFILEREQUESTED)) {
            profile.flag |= MESIBO_USERFLAG_PROFILEREQUESTED;
            [addresses addObject:profile.address];
        }
    }
    
    if([addresses count] == 0)
        return;
    
    [self getContacts:addresses hidden:hidden handler:^(int result, NSDictionary *response) {
        
    }];
    
}

-(void) autoAddContact:(MesiboParams *)params {
    if(MESIBO_MSGSTATUS_OUTBOX == params.status)
        return;
    
    if(0 == (params.profile.flag&MESIBO_USERFLAG_TEMPORARY) || (params.profile.flag&MESIBO_USERFLAG_PROFILEREQUESTED) )
        return;
    
    MesiboUserProfile *profile = params.profile;
    NSMutableArray *profiles = [NSMutableArray new];
    [profiles addObject:profile];
    [self addContacts:profiles hidden:YES];
}


-(void) setAPNToken:(NSString *)token {
    return; // We are disabling sending APN token, instead we sending Push token
    // TBD. later send both
    
    mApnToken = token;
    mApnTokenType = 0;
    [self sendAPNToken];
}

-(void) setPushToken:(NSString *)token {
    mApnToken = token;
    mApnTokenType = 1;
    [self sendAPNToken];
}



-(void) executeAPNCompletion:(double) delayInSeconds {
    if(!mAPNCompletionHandler)
        return;
    
    if(delayInSeconds < 0.01) {
        @synchronized (self) {
            if(mAPNCompletionHandler)
                mAPNCompletionHandler(UIBackgroundFetchResultNewData);
            mAPNCompletionHandler = nil;
        }
        return;
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){        
        [self executeAPNCompletion:0];
    });
    
}

-(BOOL) setAPNCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self executeAPNCompletion:0]; // complete existing
    
    mAPNCompletionHandler = completionHandler;
    [MesiboInstance setAppInForeground:nil screenId:-1 foreground:YES];
    [self executeAPNCompletion:10.0];
    return YES;
}

-(void) startOnlineAction {
    [self sendAPNToken]; // this will also be called on online status to ensure that APN token is sent
    [self startSync];
    [self executeAPNCompletion:3.0];
}

-(void) resetDB {
    [MesiboInstance resetDatabase:MESIBO_DBTABLE_ALL];
}

#define AUTODOWNLOAD_KEY    @"autodownload"
-(void) initAutoDownload {
    NSString *autodownload = [MesiboInstance readKey:AUTODOWNLOAD_KEY];
    mAutoDownload = (!autodownload || [autodownload isEqualToString:@"1"]);
}

-(void) setMediaAutoDownload:(BOOL)autoDownload {
    mAutoDownload = autoDownload;
    [MesiboInstance setKey:AUTODOWNLOAD_KEY value:mAutoDownload?@"1":@"0"];
}

-(BOOL)getMediaAutoDownload {
    return mAutoDownload;
}

//https://github.com/bitstadium/HockeySDK-iOS/blob/develop/Classes/BITHockeyHelper.m
BOOL isAppStoreVersion(void) {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
    
    NSURL *appStoreReceiptURL = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent;
    BOOL isSandboxReceipt = [appStoreReceiptLastComponent isEqualToString:@"sandboxReceipt"];
    
    if(isSandboxReceipt) return NO;
    
    return [NSBundle.mainBundle respondsToSelector:@selector(appStoreReceiptURL)];
}

BOOL localVerson(void) {
    BOOL hasEmbeddedMobileProvision = !![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    return hasEmbeddedMobileProvision;
}

-(BOOL) isAppStoreBuild {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
    
    // MobilePovision profiles are a clear indicator for Ad-Hoc distribution
    if (localVerson()) {
        return NO;
    }
    
    return isAppStoreVersion();
}


@end
