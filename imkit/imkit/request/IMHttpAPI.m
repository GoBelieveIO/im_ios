//
//  APIRequest.m
//  Message
//
//  Created by houxh on 14-7-26.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "IMHttpAPI.h"
#import "TAHttpOperation.h"

#define API_URL @"http://api.gobelieve.io"
@implementation IMHttpAPI


+(IMHttpAPI*)instance {
    static IMHttpAPI *im;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!im) {
            im = [[IMHttpAPI alloc] init];
        }
    });
    return im;
}

+(NSOperation*)uploadImage:(UIImage*)image success:(void (^)(NSString *url))success fail:(void (^)())fail {
    NSData *data = UIImagePNGRepresentation(image);
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [API_URL stringByAppendingString:@"/images"];
    request.method = @"POST";
    request.postBody = data;
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"image/png" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    request.headers = headers;
    
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSString *src_url = [resp objectForKey:@"src_url"];
        success(src_url);
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;

}


+(NSOperation*)uploadAudio:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [API_URL stringByAppendingString:@"/audios"];
    request.method = @"POST";
    request.postBody = data;
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/plain" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    request.headers = headers;

    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSString *src_url = [resp objectForKey:@"src_url"];
        success(src_url);
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(NSOperation*)bindDeviceToken:(NSString*)deviceToken success:(void (^)())success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [API_URL stringByAppendingString:@"/device/bind"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:deviceToken forKey:@"apns_device_token"];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        int statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSLog(@"bind device token fail");
            fail();
            return;
        }
        success();
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        NSLog(@"bind device token fail");
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(NSOperation*)createGroup:(NSString*)groupName master:(int64_t)master members:(NSArray*)members success:(void (^)(int64_t))success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [API_URL stringByAppendingString:@"/groups"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:[NSNumber numberWithLongLong:master] forKey:@"master"];
    [dict setObject:groupName forKey:@"name"];
    [dict setObject:members forKey:@"members"];
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];

    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        int statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSLog(@"create group fail:%@", resp);
            fail();
            return;
        }
        
        NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        int64_t groupID = [[[resp objectForKey:@"data"] objectForKey:@"group_id"] longLongValue];
        success(groupID);
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        NSLog(@"create group fail");
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

@end
