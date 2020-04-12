/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "IMHttpAPI.h"
#import "TAHttpOperation.h"

#define API_URL @"https://api.gobelieve.io"
@implementation IMHttpAPI


+(IMHttpAPI*)instance {
    static IMHttpAPI *im;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!im) {
            im = [[IMHttpAPI alloc] init];
            im.apiURL = API_URL;
        }
    });
    return im;
}
+(NSOperation*)uploadImageData:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)(void))fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/images"];
    request.method = @"POST";
    request.postBody = data;
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"image/png" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    request.headers = headers;
    
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSLog(@"图片上传失败");
            fail();
        } else {
            NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSString *src_url = [resp objectForKey:@"src_url"];
            success(src_url);
        }
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(NSOperation*)uploadImage:(UIImage*)image success:(void (^)(NSString *url))success fail:(void (^)(void))fail {
    NSData *data = UIImagePNGRepresentation(image);
    return [self uploadImageData:data success:success fail:fail];
}


+(NSOperation*)uploadAudio:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)(void))fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/audios"];
    request.method = @"POST";
    request.postBody = data;
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/plain" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    request.headers = headers;

    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSLog(@"录音上传失败");
            fail();
        } else {
            NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            NSString *src_url = [resp objectForKey:@"src_url"];
            success(src_url);
        }
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

static NSString * AFCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

+(void)uploadFile:(NSData*)fileData success:(void(^)(NSString* url))success fail:(void(^)(void))fail {
    [self uploadFile:fileData filename:@"file.tmp" success:success fail:fail];
}

+(void)uploadFile:(NSData*)fileData filename:(NSString*)filename success:(void(^)(NSString* url))success fail:(void(^)(void))fail {
    NSString *url = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/files"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [request setValue:auth forHTTPHeaderField:@"Authorization"];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:60];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = AFCreateMultipartFormBoundary();
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // post body
    NSMutableData *body = [NSMutableData data];
    if (fileData) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/plain\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:fileData];
        [body appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];

    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%zd", [body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                               if(statusCode == 200 && data.length > 0) {
                                   NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                   NSString *src_url = [resp objectForKey:@"src_url"];
                                   success(src_url);
                               } else {
                                   NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                   NSLog(@"error:%@", resp);
                                   fail();
                               }
                           }];
}


+(NSOperation*)bindPushKitDeviceToken:(NSString*)deviceToken success:(void (^)(void))success fail:(void (^)(void))fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/device/bind"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:deviceToken forKey:@"pushkit_device_token"];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
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

+(NSOperation*)bindDeviceToken:(NSString*)deviceToken success:(void (^)())success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/device/bind"];
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
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
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


+(NSOperation*)unbindDeviceToken:(NSString*)deviceToken pushKitToken:(NSString*)pushKitToken success:(void (^)())success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/device/unbind"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (deviceToken.length > 0) {
        [dict setObject:deviceToken forKey:@"apns_device_token"];
    }
    if (pushKitToken.length > 0) {
        [dict setObject:deviceToken forKey:@"pushkit_device_token"];
    }
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSLog(@"unbind device token fail");
            fail();
            return;
        }
        success();
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        NSLog(@"unbind device token fail");
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(NSOperation*)openGroupNotification:(int64_t)group_id success:(void (^)())success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    
    request.targetURL = [NSString stringWithFormat:@"%@/notification/groups/%lld", [IMHttpAPI instance].apiURL, group_id];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:0] forKey:@"quiet"];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            fail();
            return;
        }
        success();
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(NSOperation*)closeGroupNotification:(int64_t)group_id success:(void (^)())success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    
    request.targetURL = [NSString stringWithFormat:@"%@/notification/groups/%lld", [IMHttpAPI instance].apiURL, group_id];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSNumber numberWithInt:1] forKey:@"quiet"];
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", [IMHttpAPI instance].accessToken];
    [headers setObject:auth forKey:@"Authorization"];
    
    request.headers = headers;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    request.postBody = data;
    request.method = @"POST";
    request.successCB = ^(IMHttpOperation*commObj, NSURLResponse *response, NSData *data) {
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
        if (statusCode != 200) {
            NSLog(@"open group notification fail");
            fail();
            return;
        }
        success();
    };
    request.failCB = ^(IMHttpOperation*commObj, IMHttpOperationError error) {
        NSLog(@"open group notification fail");
        fail();
    };
    [[NSOperationQueue mainQueue] addOperation:request];
    return request;
}

+(NSOperation*)createGroup:(NSString*)groupName master:(int64_t)master members:(NSArray*)members success:(void (^)(int64_t))success fail:(void (^)())fail {
    IMHttpOperation *request = [IMHttpOperation httpOperationWithTimeoutInterval:60];
    request.targetURL = [[IMHttpAPI instance].apiURL stringByAppendingString:@"/groups"];
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
        NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
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
