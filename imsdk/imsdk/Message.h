/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

#define MSG_HEARTBEAT 1

#define MSG_AUTH_STATUS 3
#define MSG_IM 4
#define MSG_ACK 5

#define MSG_GROUP_NOTIFICATION 7
#define MSG_GROUP_IM 8

#define MSG_INPUTING 10

#define MSG_PING 13
#define MSG_PONG 14
#define MSG_AUTH_TOKEN 15

#define MSG_RT 17
#define MSG_ENTER_ROOM 18
#define MSG_LEAVE_ROOM 19
#define MSG_ROOM_IM 20
#define MSG_SYSTEM 21
#define MSG_UNREAD_COUNT 22

#define MSG_CUSTOMER 24
#define MSG_CUSTOMER_SUPPORT 25


//客户端->服务端
#define MSG_SYNC  26 //同步消息
//服务端->客服端
#define MSG_SYNC_BEGIN  27
#define MSG_SYNC_END  28
//通知客户端有新消息
#define MSG_SYNC_NOTIFY  29

//客户端->服务端
#define MSG_SYNC_GROUP  30//同步超级群消息
//服务端->客服端
#define MSG_SYNC_GROUP_BEGIN  31
#define MSG_SYNC_GROUP_END  32
//通知客户端有新消息
#define MSG_SYNC_GROUP_NOTIFY  33



#define MSG_VOIP_CONTROL 64

#define PLATFORM_IOS  1
#define PLATFORM_ANDROID 2
#define PLATFORM_WEB 3




@interface IMMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, assign)int32_t timestamp;
@property(nonatomic, assign)int32_t msgLocalID;
@property(nonatomic, copy)NSString *content;
@end

@interface CustomerMessage : NSObject
//本地消息id 不会序列化传到服务器
@property(nonatomic, assign)int32_t msgLocalID;

@property(nonatomic, assign)int64_t customerAppID;
@property(nonatomic, assign)int64_t customerID;
@property(nonatomic, assign)int64_t storeID;
@property(nonatomic, assign)int64_t sellerID;
@property(nonatomic, assign)int32_t timestamp;
@property(nonatomic, copy)NSString *content;
@end

@interface RoomMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, copy)NSString *content;
@end

typedef RoomMessage RTMessage;

@interface MessageInputing : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@end

@interface AuthenticationToken : NSObject
@property(nonatomic, copy) NSString *token;
@property(nonatomic, assign) int8_t platformID;
@property(nonatomic, copy) NSString *deviceID;
@end


@interface VOIPControl : NSObject
@property(nonatomic, assign) int64_t sender;
@property(nonatomic, assign) int64_t receiver;
@property(nonatomic) NSData *content;

@end

typedef NSNumber SyncKey;

@interface GroupSyncKey : NSObject
@property(nonatomic, assign) int64_t groupID;
@property(nonatomic, assign) int64_t syncKey;
@end


@interface Message : NSObject
@property(nonatomic, assign)int cmd;
@property(nonatomic, assign)int seq;
@property(nonatomic) NSObject *body;

-(NSData*)pack;

-(BOOL)unpack:(NSData*)data;
@end
