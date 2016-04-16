/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

#define MSG_HEARTBEAT 1
#define MSG_AUTH 2
#define MSG_AUTH_STATUS 3
#define MSG_IM 4
#define MSG_ACK 5
#define MSG_RST 6
#define MSG_GROUP_NOTIFICATION 7
#define MSG_GROUP_IM 8
#define MSG_PEER_ACK 9
#define MSG_INPUTING 10
#define MSG_SUBSCRIBE_ONLINE_STATE 11
#define MSG_ONLINE_STATE 12
#define MSG_PING 13
#define MSG_PONG 14
#define MSG_AUTH_TOKEN 15
#define MSG_LOGIN_POINT 16
#define MSG_RT 17
#define MSG_ENTER_ROOM 18
#define MSG_LEAVE_ROOM 19
#define MSG_ROOM_IM 20
#define MSG_SYSTEM 21
#define MSG_UNREAD_COUNT 22
#define MSG_CUSTOMER_SERVICE 23
#define MSG_CUSTOMER 24
#define MSG_CUSTOMER_SUPPORT 25

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

@interface LoginPoint : NSObject
@property(nonatomic, assign) int32_t upTimestamp;
@property(nonatomic, assign) int8_t platformID;
@property(nonatomic, copy) NSString *deviceID;
@end




@interface VOIPControl : NSObject
@property(nonatomic, assign) int64_t sender;
@property(nonatomic, assign) int64_t receiver;
@property(nonatomic) NSData *content;

@end


@interface Message : NSObject
@property(nonatomic, assign)int cmd;
@property(nonatomic, assign)int seq;
@property(nonatomic) NSObject *body;

-(NSData*)pack;

-(BOOL)unpack:(NSData*)data;
@end
