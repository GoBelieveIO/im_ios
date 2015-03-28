//
//  APIRequest.h
//  Message
//
//  Created by houxh on 14-7-26.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IMHttpAPI : NSObject

@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, copy) NSString *apiURL;

+(IMHttpAPI*)instance;

+(NSOperation*)uploadImage:(UIImage*)image success:(void (^)(NSString *url))success fail:(void (^)())fail;

+(NSOperation*)uploadAudio:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)())fail;

+(NSOperation*)bindDeviceToken:(NSString*)deviceToken success:(void (^)())success fail:(void (^)())fail;

+(NSOperation*)createGroup:(NSString*)groupName master:(int64_t)master members:(NSArray*)members success:(void (^)(int64_t))success fail:(void (^)())fail;

@end
