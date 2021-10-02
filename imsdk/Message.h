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

#define MSG_PING 13
#define MSG_PONG 14
#define MSG_AUTH_TOKEN 15

#define MSG_RT 17
#define MSG_ENTER_ROOM 18
#define MSG_LEAVE_ROOM 19
#define MSG_ROOM_IM 20
#define MSG_SYSTEM 21
#define MSG_UNREAD_COUNT 22

#define MSG_CUSTOMER_ 24
#define MSG_CUSTOMER_SUPPORT_ 25


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

//客服端->服务端
#define MSG_SYNC_KEY  34
#define MSG_GROUP_SYNC_KEY 35

#define MSG_METADATA 37

#define MSG_CUSTOMER 64


#define PLATFORM_IOS  1
#define PLATFORM_ANDROID 2
#define PLATFORM_WEB 3

//message flag
#define MSG_FLAG_TEXT 1
#define MSG_FLAG_UNPERSISTENT 2
#define MSG_FLAG_GROUP 4
#define MSG_FLAG_SELF 8
#define MSG_FLAG_PUSH 0x10
#define MSG_FLAG_SUPER_GROUP 0x20

//message ack
#define MSG_ACK_SUCCESS  0
#define MSG_ACK_NOT_MY_FRIEND  1
#define MSG_ACK_NOT_YOUR_FRIEND  2
#define MSG_ACK_IN_YOUR_BLACKLIST  3
#define MSG_ACK_NOT_GROUP_MEMBER  64

@interface IMMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, assign)int32_t timestamp;
@property(nonatomic, assign)int64_t msgLocalID;
@property(nonatomic, copy)NSString *content;

@property(nonatomic)NSDictionary *dict;//content dict

@property(nonatomic, assign)BOOL secret;

//文本消息
@property(nonatomic, assign) BOOL isText;
//群组已读消息，通过点对点消息来发送
@property(nonatomic, assign)int64_t groupID;

//会话未读数减一
@property(nonatomic, assign)BOOL decrementUnread;

//消息由当前用户在当前设备发出
@property(nonatomic, assign) BOOL isSelf;
//群组通知消息
@property(nonatomic, assign) BOOL isGroupNotification;
@end


typedef IMMessage GroupMessage;
typedef IMMessage PeerMessage;



@interface CustomerMessage : IMMessage
@property(nonatomic, assign)int64_t senderAppID;
@property(nonatomic, assign)int64_t receiverAppID;
@end

@interface RoomMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, copy)NSString *content;
@end

typedef RoomMessage RTMessage;


@interface AuthenticationToken : NSObject
@property(nonatomic, copy) NSString *token;
@property(nonatomic, assign) int8_t platformID;
@property(nonatomic, copy) NSString *deviceID;
@end


@interface ACKMessage : NSObject
@property(nonatomic, assign) int seq;
@property(nonatomic, assign) int status;
@end

typedef NSNumber SyncKey;

@interface GroupSyncKey : NSObject
@property(nonatomic, assign) int64_t groupID;
@property(nonatomic, assign) int64_t syncKey;
@end

typedef SyncKey SyncNotify;

typedef GroupSyncKey GroupSyncNotify;


@interface Metadata : NSObject
@property(nonatomic, assign) int64_t syncKey;
@property(nonatomic, assign) int64_t prevSyncKey;
@end

__attribute__((objc_runtime_name("GoBelieveMessage")))
@interface Message : NSObject
@property(nonatomic, assign)int cmd;
@property(nonatomic, assign)int seq;
@property(nonatomic, assign)int flag;
@property(nonatomic) NSObject *body;

@property(nonatomic, assign)int failCount;//发送失败的次数

-(NSData*)pack;

-(BOOL)unpack:(NSData*)data;
@end
