/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IMHttpAPI : NSObject

@property(nonatomic, copy) NSString *accessToken;
@property(nonatomic, copy) NSString *apiURL;

+(IMHttpAPI*)instance;

+(NSOperation*)uploadImageData:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)(void))fail;

+(NSOperation*)uploadImage:(UIImage*)image success:(void (^)(NSString *url))success fail:(void (^)(void))fail;

+(NSOperation*)uploadAudio:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)(void))fail;

+(void)uploadFile:(NSData*)fileData
          success:(void(^)(NSString* url))success
             fail:(void(^)(void))fail;

+(void)uploadFile:(NSData*)fileData
         filename:(NSString*)filename
          success:(void(^)(NSString* url))success
             fail:(void(^)(void))fail;

+(NSOperation*)bindPushKitDeviceToken:(NSString*)deviceToken
                              success:(void (^)(void))success
                                 fail:(void (^)(void))fail;

/**
 * 绑定用户的devicetoken,用户登录后调用
 *
 */
+(NSOperation*)bindDeviceToken:(NSString*)deviceToken
                       success:(void (^)(void))success
                          fail:(void (^)(void))fail;

/**
 * 清除绑定在用户上的devicetoken,用户注销前调用.
 *
 */
+(NSOperation*)unbindDeviceToken:(NSString*)deviceToken
                    pushKitToken:(NSString*)pushKitToken
                         success:(void (^)(void))success
                            fail:(void (^)(void))fail;




+(NSOperation*)getCustomerSupporter:(int64_t)storeId
                            success:(void (^)(NSDictionary *resp))success
                               fail:(void (^)(NSString *err))fail;

@end
