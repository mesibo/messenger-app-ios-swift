//
//  Mesibo_FileTransferHandler.m
//  LiveChat
//
//  Created by Mesibo on 22/09/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SampleAppFileTransferHandler.h"
#import "SampleAPI.h"
#import "MesiboMessenger-Swift.h"

#import <Photos/Photos.h>

@implementation SampleAppFileTransferHandler

- (void) initialize {
    [MesiboInstance addListener:self];
}

-(BOOL) Mesibo_onStartUpload:(MesiboFileInfo *)file {
    int type = [MesiboInstance getNetworkConnectivity];
    
    if(MESIBO_CONNECTIVITY_WIFI != type && !file.userInteraction)
        return NO;
    
    //TBD, check max file size
    MesiboParams *params = [file getParams];
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    
    [post setObject:@"upload" forKey:@"op"];
    [post setValue:[SampleAPIInstance getToken] forKey:@"token"];
    [post setValue:[@(params.mid) stringValue] forKey:@"mid"];
    [post setValue:[@(0) stringValue] forKey:@"profile"];
    
    //UIImage *a = [MesiboInstance loadImage:nil filePath:[file getPath] maxside:0];
    
    Mesibo_onHTTPProgress handler = ^BOOL(MesiboHttp *http, int state, int progress) {
        
        int status = [file getStatus];
        
        if(MESIBO_FILESTATUS_RETRYLATER != status) {
            status = MESIBO_FILESTATUS_INPROGRESS;
            if(progress < 0)
                status = MESIBO_FILESTATUS_FAILED;
        }
        
        if(100 == progress && MESIBO_HTTPSTATE_DOWNLOAD == state) {
            NSError *jsonerror = nil;
            
            NSData *data = [[http getDataString] dataUsingEncoding:NSUTF8StringEncoding];
            id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonerror];
            NSDictionary *returnedDict = (NSMutableDictionary *)jsonObject;
            NSString *fileUrl =  [returnedDict valueForKey:@"file"];
            
            if(fileUrl)
                [file setUrl:fileUrl];
            else {
                progress = -1;
                status = MESIBO_FILESTATUS_FAILED;
            }
        }
        
        if(progress < 100 || (100 == progress && MESIBO_HTTPSTATE_DOWNLOAD == state))
           [MesiboInstance updateFileTransferProgress:file progress:progress status:status];
        
        return ((100 == progress && MESIBO_HTTPSTATE_DOWNLOAD == state) || MESIBO_FILESTATUS_RETRYLATER != status);
    };
    
    MesiboHttp *http = [MesiboHttp new];
    http.url = [SampleAPIInstance getUploadUrl];
    http.uploadPhAsset = file.asset;
    http.uploadLocalIdentifier = file.localIdentifier;
    http.uploadFile = [file getPath];
    http.postBundle = post;
    http.uploadFileField = @"photo";
    http.listener =  handler;
    
    [file setFileTransferContext:http];
 
    return [http execute];
}

-(BOOL) Mesibo_onStartDownload:(MesiboFileInfo *)file {
    int type = [MesiboInstance getNetworkConnectivity];
    
    if(![SampleAPIInstance getMediaAutoDownload] && MESIBO_CONNECTIVITY_WIFI != type && !file.userInteraction)
        return NO;
    
    MesiboParams *params = [file getParams];
    
    if(MESIBO_ORIGIN_REALTIME != params.origin && !file.userInteraction)
        return NO;
    
    NSString *url = [file getUrl];
    
    if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
        url = [[SampleAPIInstance getDownloadUrl] stringByAppendingString:url];
    }
    
    Mesibo_onHTTPProgress handler = ^BOOL(MesiboHttp *http, int state, int progress) {
        int status = [file getStatus];
        
        if(MESIBO_FILESTATUS_RETRYLATER != status) {
            status = MESIBO_FILESTATUS_INPROGRESS;
            if(progress < 0)
                status = MESIBO_FILESTATUS_FAILED;
        }
        
        [MesiboInstance updateFileTransferProgress:file progress:progress status:status];
        return (100 == progress || MESIBO_FILESTATUS_RETRYLATER != status);
    };
    
    MesiboHttp *http = [MesiboHttp new];
    http.url = url;
    http.downloadFile = [file getPath];
    http.resume = YES;
    http.listener =  handler;
    
    [file setFileTransferContext:http];
    
    return [http execute];
    
}

-(BOOL) Mesibo_onStartFileTransfer:(MesiboFileInfo *)file {
    
    if(MESIBO_FILEMODE_DOWNLOAD == file.mode) {
        return [self Mesibo_onStartDownload:file];
    }
    
    return [self Mesibo_onStartUpload:file];
    
}

-(BOOL) Mesibo_onStopFileTransfer:(MesiboFileInfo *)file {
    MesiboHttp *http = [file getFileTransferContext];
    if(http) {
        [http cancel];
    }
    return YES;
}

@end
