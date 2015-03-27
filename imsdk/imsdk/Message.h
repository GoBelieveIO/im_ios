//
//  IM.h
//  im
//
//  Created by houxh on 14-6-21.
//  Copyright (c) 2014年 potato. All rights reserved.
//

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


#define PLATFORM_IOS 1

@interface IMMessage : NSObject
@property(nonatomic, assign)int64_t sender;
@property(nonatomic, assign)int64_t receiver;
@property(nonatomic, assign)int32_t timestamp;
@property(nonatomic, assign)int32_t msgLocalID;
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

@interface Message : NSObject
@property(nonatomic, assign)int cmd;
@property(nonatomic, assign)int seq;
@property(nonatomic) NSObject *body;

-(NSData*)pack;

-(BOOL)unpack:(NSData*)data;
@end
