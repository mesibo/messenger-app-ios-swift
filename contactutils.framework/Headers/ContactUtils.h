//
//  PhoneUtils.h
//  MesiboDevel
//
//  Copyright © 2017 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ContactUtilsInstance [ContactUtils getInstance]

#define CONTACTUTILS_SYNCTYPE_SYNC  0
#define CONTACTUTILS_SYNCTYPE_DELETE  1

@interface PhonebookContact : NSObject
//@property (nonatomic) long contactid;
@property (nonatomic, strong) NSString *firstname, *lastname, *name; // name of the person
@property (nonatomic, strong) NSString *phoneNumber, *displayPhoneNumber; // mobile detail
@property (nonatomic, assign) BOOL hasImage;
//@property (nonatomic, strong) NSString *type; // mobile detail
@property int type; //type in TringMe values
@property (nonatomic, strong) NSData *image; // image filename of person
@property (nonatomic, strong) NSDate *ts;
@property (nonatomic, assign) BOOL synced;
@property (nonatomic, assign) int index;
+(PhonebookContact *) initWithName:(NSString *)firstname lastname:(NSString *)lastname phone:(NSString *)phone type:(int)type;

@end

typedef BOOL (^onContactBlock)(PhonebookContact *c, int type);
typedef void (^onContactSaveBlock)(NSString *contactsToSave, BOOL syncDone);
typedef void (^onContactPermissionBlock)(BOOL result);
typedef void (^onContactChangedBlock)();




@interface ContactUtils : NSObject
+(ContactUtils *)getInstance;
-(void) initPhonebook:(NSString *)lastSynced onPermission:(onContactPermissionBlock) onPermission onChange:(onContactChangedBlock)onChange;
-(NSString *) stripPhone:(NSString *)phone;
-(NSString *) getFQN:(NSString *)phone;
-(int) getCountryCode;
-(void) setCountryCode:(int)code;
-(void) reset;
-(BOOL) sync:(onContactBlock)onContactBlock ;
-(NSString *) synced:(NSArray *)numbers type:(int)type;
-(BOOL) getSyncStatus;
-(PhonebookContact *) search:(NSString *)phone returnCopy:(BOOL)returnCopy;
-(PhonebookContact *) lookup:(NSString *)phone returnCopy:(BOOL)returnCopy;

@end
