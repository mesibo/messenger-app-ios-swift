//
//  SampleAPI.h
//  MesiboDevel
//
//  Created by John on 23/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mesibo/Mesibo.h"


@interface SampleAPIRespose : NSObject
@property (nonatomic) NSString *result;
@property (nonatomic) NSString *op;
@property (nonatomic) NSString *error;
@property (nonatomic) NSString *token;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *photo;
@property (nonatomic) NSString *invite;
@property (nonatomic) uint32_t gid;
@property (nonatomic) int type;
@end

#define SAMPLEAPP_RESULT_OK         0
#define SAMPLEAPP_RESULT_FAIL       1
#define SAMPLEAPP_RESULT_AUTHFAIL   2


#define VISIBILITY_HIDE         0
#define VISIBILITY_VISIBLE      1
#define VISIBILITY_UNCHANGED    2

typedef void (^SampleAPI_LogoutBlock)(id parent);
typedef void (^SampleAPI_onResponse)(int result, NSDictionary *response);

#define USE_SWIFT_API
#ifdef USE_SWIFT_API
#define SampleAPIInstance BackendAPI.getInstance
#else
#define SampleAPIInstance [SampleAPI getInstance]
#endif



@interface SampleAPI : NSObject

+(SampleAPI *) getInstance;

-(void) initialize;
-(void) setOnLogout:(SampleAPI_LogoutBlock)logOutBlock;
-(NSString *) getToken;
-(NSString *) getApiUrl;
-(NSString *) getUploadUrl;
-(NSString *) getDownloadUrl;
-(NSString *) getInvite;

-(void) startMesibo:(BOOL) resetProfiles;
-(void) startSync;
-(void) onContactsChanged;
-(NSString *) getSyncedContacts;

-(void) resetDB;
-(void) logout:(BOOL) forced parent:(id)parent;
-(void) login:(NSString *)phone code:(NSString *)code handler:(SampleAPI_onResponse) handler;
-(void) login:(NSString *)akAuthCode handler:(SampleAPI_onResponse) handler;
-(BOOL) getContacts:(NSArray *)contacts hidden:(BOOL)hidden handler:(SampleAPI_onResponse) handler;
-(BOOL) deleteContacts:(NSArray *)contacts;
-(BOOL) setProfile:(NSString*)name status:(NSString*)status groupid:(uint32_t)groupid handler:(SampleAPI_onResponse) handler;
-(BOOL) setProfilePicture:(NSString*)filePath groupid:(uint32_t)groupid handler:(SampleAPI_onResponse) handler ;
-(BOOL) deleteGroup:(uint32_t) groupid handler:(SampleAPI_onResponse) handler ;
-(BOOL) getGroup:(uint32_t) groupid handler:(SampleAPI_onResponse) handler ;
-(void) autoAddContact:(MesiboParams *)params;
-(void) addContacts:(NSArray *)profiles hidden:(BOOL)hidden ;

-(BOOL) setGroup:(MesiboUserProfile *)profile members:(NSArray *)members handler:(SampleAPI_onResponse) handler ;
-(void) updateDeletedGroup:(uint32_t)groupid;

-(BOOL) editMemebers:(uint32_t) groupid removegroup:(BOOL)remove members:(NSArray *)members handler:(SampleAPI_onResponse) handler ;
-(BOOL) setAdmin:(uint32_t) groupid members:(NSString *)members admin:(BOOL)admin handler:(SampleAPI_onResponse) handler;
-(void) createContact:(NSDictionary *)response serverts:(int64_t)serverts selfProfile:(BOOL)selfProfile refresh:(BOOL)refresh visibility:(int)visibility;
-(NSString *) groupStatusFromMembers:(NSString*) members;

-(void) setAPNToken:(NSString *) token;
-(void) setPushToken:(NSString *)token;
-(void) setMediaAutoDownload:(BOOL)autoDownload;
-(BOOL) getMediaAutoDownload;

+(BOOL) isEmpty:(NSString *)string; //utility
+(BOOL) equals:(NSString *)s old:(NSString *)old;

-(void) startOnlineAction;

-(BOOL) setAPNCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
