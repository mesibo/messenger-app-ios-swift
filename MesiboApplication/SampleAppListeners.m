//
//  SampleAppListeners.m
//
//  Created by John on 23/03/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SampleAppListeners.h"
#import "SampleAPI.h"
#import "NSDictionary+NilObject.h"
#import "ContactUtils/ContactUtils.h"
#import "UIManager.h"
#import "AppUIManager.h"
#import "SampleAppNotify.h"
#import "AppAlert.h"
#import "MesiboCall/MesiboCall.h"
#import "MesiboMessenger-Swift.h"


@implementation SampleAppListeners

+(SampleAppListeners *)getInstance {
    static SampleAppListeners *myInstance = nil;
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

-(void) initialize {
    [MesiboInstance addListener:self];
    [MesiboCallInstance setListener:self];
}

-(void) Mesibo_OnMessage:(MesiboParams *)params data:(NSData *)data {
    [SampleAPIInstance autoAddContact:params];
    
    if([MesiboInstance isReading:params])
        return;
    
    if([data length] == 0) {
        return;
    }
    
    //TBD, we need to handle missed and incoming call from here
    //currently done from MesiboCall_onNotifyIncoming (below)
    if([params isCall]) return;
    
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [SampleAppNotifyInstance notifyMessage:params message:message];
}

-(void) Mesibo_onFile:(MesiboParams *)params file:(MesiboFileInfo *)file {
    [SampleAPIInstance autoAddContact:params];
    
    if([MesiboInstance isReading:params])
        return;
    
    [SampleAppNotifyInstance notifyMessage:params message:@"Attachment"];
    
}

-(void) Mesibo_onLocation:(MesiboParams *)params location:(MesiboLocation *)location {
    [SampleAPIInstance autoAddContact:params];
    
    if([MesiboInstance isReading:params])
        return;
    
    [SampleAppNotifyInstance notifyMessage:params message:@"Location"];
}

// so that we get contact while user has started typing
-(void) Mesibo_onActivity:(MesiboParams *)params activity:(int)activity {
    [SampleAPIInstance autoAddContact:params];
}

-(void) Mesibo_OnConnectionStatus:(int)status {
    
    NSLog(@"Connection status: %d", status);
    
    if (MESIBO_STATUS_SIGNOUT == status) {
        //TBD, inform user
        [AppAlert showDialogue:@"You have been loggeed out from this device since you loggedin from another device." withTitle:@"Logged out"];
        
        [SampleAPIInstance logout:YES parent:nil];
        
    } else if (MESIBO_STATUS_AUTHFAIL == status) {
        [SampleAPIInstance logout:YES parent:nil];
    }
    
    if(MESIBO_STATUS_ONLINE == status) {
        [SampleAPIInstance startOnlineAction];
    }
    
}

-(BOOL) Mesibo_onUpdateUserProfiles:(MesiboUserProfile *)profile {
    
    /* Note: You must not call setProfile from here */
    
    if(profile.flag&MESIBO_USERFLAG_DELETED) {
        
        // TBD, in fact, for both user and group profile we need to do
        if(profile.groupid) {
            profile.lookedup = YES; // else it will be recursive call from getProfile
            [SampleAPIInstance updateDeletedGroup:profile.groupid];
        }
        
        return YES;
    }
    
    if(profile && profile.groupid) {
        profile.status = [SampleAPIInstance groupStatusFromMembers:profile.groupMembers];
        return YES;
    }
    
    // Called by Mesibi UI if contacts need update, we dont use it
    if(!profile && profile.address) {
        return NO;
    }
    
    if(![SampleAPI isEmpty:profile.address]) {
        PhonebookContact *c = [ContactUtilsInstance lookup:profile.address returnCopy:NO];
        if(!c || !c.name)
            return NO;
        
        if([SampleAPI equals:c.name old:profile.name ])
            return NO;
        
        profile.name = c.name;
        return YES;
    }
    
    return NO; //group
}

- (void)Mesibo_onShowProfile:(id)parent profile:(MesiboUserProfile *)profile {
    [AppUIManager launchProfile:parent profile:profile];
}


-(void) Mesibo_onSetGroup:(id)parent profile:(MesiboUserProfile *)profile type:(int)type members:(NSArray *)members handler:(Mesibo_onSetGroupHandler)handler {
    [[UIManager getInstance] addProgress:((UIViewController *)(parent)).view];
    [[UIManager getInstance] showProgress];
    [SampleAPIInstance setGroup:profile members:members handler:^(int result, NSDictionary *response) {
        [[UIManager getInstance] hideProgress];
        u_int32_t groupid = [[response objectForKey:@"gid"] unsignedIntValue];
        handler(groupid);
    }];
}

-(void) Mesibo_onGetGroup:(id)parent groupid:(uint32_t)groupid handler:(Mesibo_onSetGroupHandler)handler {
    //[SampleAPIInstance getGroup:groupid handler:handler];
}

-(NSArray *) getGroupMembers:(NSString*) members {
    if([SampleAPI isEmpty:members])
        return nil;
    
    NSArray *s = [members componentsSeparatedByString: @":"];
    if(!s || s.count < 2)
        return nil;
    
    NSArray *users = [s[1] componentsSeparatedByString: @","];
    if(!users)
        return nil;
    
    
    NSMutableArray *m = [NSMutableArray new];
    
    for(int i=0; i < users.count; i++) {
        MesiboUserProfile *u = [MesiboInstance getUserProfile:users[i]];
        if(!u)
            u = [MesiboInstance createProfile:users[i] groupid:0 name:nil];
        
        [m addObject:u];
    }
    
    return m;
}

-(NSArray *) Mesibo_onGetGroupMembers:(id)parent groupid:(uint32_t)groupid {
    MesiboUserProfile *profile = [MesiboInstance getProfile:nil groupid:groupid];
    if(!profile) return nil;
    
    return [self getGroupMembers:profile.groupMembers];
}

-(BOOL) Mesibo_OnMessageFilter:(MesiboParams *)params direction:(int)direction data:(NSData *)data {
    if(1 == direction)
        return YES;
    
    // using it for notifications
    if(1 != params.type)
        return YES;
    
    if(![data length])
        return NO;
    
    NSError *jsonerror = nil;
    NSMutableDictionary *returnedDict = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonerror];
    
    if (jsonerror != nil) {
        return NO;
    }
    
    if (![jsonObject isKindOfClass:[NSArray class]]) {
        //LOGD(@"its probably a dictionary");
        returnedDict = (NSMutableDictionary *)jsonObject;
    }
    
    if(!returnedDict)
        return NO;
    
    NSString *subject = (NSString *)[returnedDict objectForKeyOrNil:@"subject"];
    NSString *phone = (NSString *)[returnedDict objectForKeyOrNil:@"phone"];
    
    if(subject) {
        NSString *name = (NSString *)[returnedDict objectForKeyOrNil:@"name"];
        NSString *msg = (NSString *)[returnedDict objectForKeyOrNil:@"msg"];
        if(phone) {
            PhonebookContact *c = [ContactUtilsInstance lookup:phone returnCopy:NO];
            if(c && [c.name length] > 0) {
                name = c.name;
            }
        }
        
        if(!name)
            name = phone;
        
        if(name) {
            subject = [subject stringByReplacingOccurrencesOfString:@"%NAME%" withString:name];
            
            if(msg)
                msg = [msg stringByReplacingOccurrencesOfString:@"%NAME%" withString:name];
        }
        
        [SampleAppNotifyInstance notify:SAMPLEAPP_NOTIFYTYPE_OTHER subject:subject message:msg];
    }
    
    [SampleAPIInstance createContact:returnedDict serverts:([MesiboInstance getTimestamp]-params.ts)/1000 selfProfile:NO refresh:YES visibility:VISIBILITY_UNCHANGED];
    
    return NO;
    
}

-(void) Mesibo_onForeground:(id)parent screenId:(int)screenId foreground:(BOOL)foreground {
    //userlist is in foreground
    if(foreground && 0 == screenId) {
        //notify count clear
        [SampleAppNotifyInstance clear];
    }
    
}

-(BOOL) MesiboCall_onNotifyIncoming:(int)type profile:(MesiboUserProfile *)profile video:(BOOL)video {
    NSString *n = nil;
    NSString *subj = nil;
    if(MESIBOCALL_NOTIFY_INCOMING == type) {
        subj = @"Mesibo Incoming Call";
        n = [NSString stringWithFormat:@"Mesibo %scall from %@", video?"Video ":"", profile.name];
    } else if(MESIBOCALL_NOTIFY_MISSED == type) {
        subj = @"Mesibo Missed Call";
        n = [NSString stringWithFormat:@"You missed a Mesibo %scall from %@", video?"Video ":"", profile.name];
    }
    
    if(n) {
        [MesiboInstance runInThread:YES handler:^{
            [SampleAppNotifyInstance notify:2 subject:subj message:n];
        }];
    }
    
    return YES;
}

-(void) MesiboCall_onShowViewController:(id)parent vc:(id)vc {
    [AppUIManager launchVC:parent vc:vc];
}

-(void) MesiboCall_onDismissViewController:(id)vc {
}

@end
