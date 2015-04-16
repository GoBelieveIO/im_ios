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

+(NSOperation*)uploadImage:(UIImage*)image success:(void (^)(NSString *url))success fail:(void (^)())fail;

+(NSOperation*)uploadAudio:(NSData*)data success:(void (^)(NSString *url))success fail:(void (^)())fail;

/**
 * 绑定用户的devicetoken,用户登录后调用
 *
 */
+(NSOperation*)bindDeviceToken:(NSString*)deviceToken success:(void (^)())success fail:(void (^)())fail;

/**
 * 清除绑定在用户上的devicetoken,用户注销前调用.
 *
 */
+(NSOperation*)unbindDeviceToken:(NSString*)deviceToken success:(void (^)())success fail:(void (^)())fail;

/**
 * 创建群组
 * @param groupName 群组名称
 * @param master 群主ID
 * @param members 群组成员的ID数组
 */
+(NSOperation*)createGroup:(NSString*)groupName master:(int64_t)master members:(NSArray*)members success:(void (^)(int64_t))success fail:(void (^)())fail;

@end
