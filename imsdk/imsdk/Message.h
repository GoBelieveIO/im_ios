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

#define MSG_VOIP_CONTROL 64

#define PLATFORM_IOS  1
#define PLATFORM_ANDROID 2
#define PLATFORM_WEB 3

enum VOIPCommand {
    //语音通话
    VOIP_COMMAND_DIAL = 1,
    VOIP_COMMAND_ACCEPT,
    VOIP_COMMAND_CONNECTED,
    VOIP_COMMAND_REFUSE,
    VOIP_COMMAND_REFUSED,
    VOIP_COMMAND_HANG_UP,
    VOIP_COMMAND_RESET,
    
    //通话中
    VOIP_COMMAND_TALKING,
    
    //视频通话
    VOIP_COMMAND_DIAL_VIDEO,
};


@interface IMMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, assign)int32_t timestamp;
@property(nonatomic, assign)int32_t msgLocalID;
@property(nonatomic, copy)NSString *content;
@end

@interface CustomerMessage : IMMessage
@property(nonatomic, assign)int64_t customer;//普通用户id
@end

@interface RoomMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, copy)NSString *content;
@end


@interface MessageInputing : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@end


@interface MessagePeerACK : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, assign)int32_t msgLocalID;
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

@interface NatPortMap : NSObject
@property(nonatomic) int32_t ip;
@property(nonatomic) int16_t port;
@end


@interface VOIPControl : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, assign) int32_t cmd;
@property(nonatomic, assign) int32_t dialCount;//只对VOIP_COMMAND_DIAL, VOIP_COMMAND_DIAL_VIDEO
@property(nonatomic) NatPortMap *natMap;//VOIP_COMMAND_ACCEPT，VOIP_COMMAND_CONNECTED
@property(nonatomic) int32_t relayIP;//VOIP_COMMAND_CONNECTED, 中转服务器ip地址
@end


@interface Message : NSObject
@property(nonatomic, assign)int cmd;
@property(nonatomic, assign)int seq;
@property(nonatomic) NSObject *body;

-(NSData*)pack;

-(BOOL)unpack:(NSData*)data;
@end
