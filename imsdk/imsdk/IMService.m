/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#import "IMService.h"
#import "AsyncTCP.h"
#import "Message.h"
#import "util.h"
#import "GOReachability.h"

#define HEARTBEAT_HZ (180)

#define HOST  @"imnode.gobelieve.io"
#define PORT 23000

@interface IMService()
@property(nonatomic)int seq;
@property(nonatomic)int64_t roomID;
@property(nonatomic)NSMutableArray *peerObservers;
@property(nonatomic)NSMutableArray *groupObservers;
@property(nonatomic)NSMutableArray *roomObservers;
@property(nonatomic)NSMutableArray *loginPointObservers;
@property(nonatomic)NSMutableArray *systemObservers;

@property(nonatomic)NSMutableData *data;
@property(nonatomic)NSMutableDictionary *peerMessages;
@property(nonatomic)NSMutableDictionary *groupMessages;
@property(nonatomic)NSMutableDictionary *roomMessages;


@end

@implementation IMService
+(IMService*)instance {
    static IMService *im;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!im) {
            im = [[IMService alloc] init];
        }
    });
    return im;
}

-(id)init {
    self = [super init];
    if (self) {
        self.peerObservers = [NSMutableArray array];
        self.groupObservers = [NSMutableArray array];
        self.roomObservers = [NSMutableArray array];
        self.loginPointObservers = [NSMutableArray array];
        self.systemObservers = [NSMutableArray array];
        
        self.data = [NSMutableData data];
        self.peerMessages = [NSMutableDictionary dictionary];
        self.groupMessages = [NSMutableDictionary dictionary];
        self.roomMessages = [NSMutableDictionary dictionary];
        
        self.host = HOST;
        self.port = PORT;
        self.heartbeatHZ = HEARTBEAT_HZ;
    }
    return self;
}

-(void)handleACK:(Message*)msg {
    NSNumber *seq = (NSNumber*)msg.body;
    IMMessage *m = (IMMessage*)[self.peerMessages objectForKey:seq];
    IMMessage *m2 = (IMMessage*)[self.groupMessages objectForKey:seq];
    RoomMessage *m3 = (RoomMessage*)[self.roomMessages objectForKey:seq];
    if (!m && !m2 && !m3) {
        return;
    }
    if (m) {
        [self.peerMessageHandler handleMessageACK:m.msgLocalID uid:m.receiver];
        [self.peerMessages removeObjectForKey:seq];
        [self publishPeerMessageACK:m.msgLocalID uid:m.receiver];
    } else if (m2) {
        [self.groupMessageHandler handleMessageACK:m2.msgLocalID gid:m2.receiver];
        [self.groupMessages removeObjectForKey:seq];
        [self publishGroupMessageACK:m2.msgLocalID gid:m2.receiver];
    } else if (m3) {
        [self.roomMessages removeObjectForKey:seq];
        [self publishRoomMessageACK:m3];
    }
}

-(void)handleIMMessage:(Message*)msg {
    IMMessage *im = (IMMessage*)msg.body;
    if (self.uid == im.sender) {
        [self.peerMessageHandler handleMessage:im uid:im.receiver];
    } else {
        [self.peerMessageHandler handleMessage:im uid:im.sender];
    }
    NSLog(@"peer message sender:%lld receiver:%lld content:%s", im.sender, im.receiver, [im.content UTF8String]);
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
    [self publishPeerMessage:im];
    
    if (self.uid == im.sender) {
        [self.peerMessageHandler handleMessageACK:im.msgLocalID uid:im.receiver];
        [self publishPeerMessageACK:im.msgLocalID uid:im.receiver];
    }
}

-(void)handleGroupIMMessage:(Message*)msg {
    IMMessage *im = (IMMessage*)msg.body;
    [self.groupMessageHandler handleMessage:im];
    NSLog(@"group message sender:%lld receiver:%lld content:%s", im.sender, im.receiver, [im.content UTF8String]);
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
    [self publishGroupMessage:im];
    
    if (im.sender == self.uid) {
        [self.groupMessageHandler handleMessageACK:im.msgLocalID gid:im.receiver];
        [self publishGroupMessageACK:im.msgLocalID gid:im.receiver];
    }
}

-(void)handleAuthStatus:(Message*)msg {
    int status = [(NSNumber*)msg.body intValue];
    NSLog(@"auth status:%d", status);
    if (status != 0) {
        //失效的accesstoken,2s后重新连接
        [self reconnect2S];
        return;
    }
    if (self.roomID > 0) {
        [self sendEnterRoom:self.roomID];
    }
}

-(void)handleInputing:(Message*)msg {
    MessageInputing *inputing = (MessageInputing*)msg.body;
    for (id<PeerMessageObserver> ob in self.peerObservers) {
        if ([ob respondsToSelector:@selector(onPeerInputing:)]) {
            [ob onPeerInputing:inputing.sender];
        }
    }
}

-(void)handlePeerACK:(Message*)msg {
    return;
}

-(void)handlePong:(Message*)msg {
    [self pong];
}

-(void)handleGroupNotification:(Message*)msg {
    NSString *notification = (NSString*)msg.body;
    NSLog(@"group notification:%@", notification);
    [self.groupMessageHandler handleGroupNotification:notification];
    for (id<GroupMessageObserver> ob in self.groupObservers) {
        if ([ob respondsToSelector:@selector(onGroupNotification:)]) {
            [ob onGroupNotification:notification];
        }
    }
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
}

-(void)handleLoginPoint:(Message*)msg {
    [self publishLoginPoint:(LoginPoint*)msg.body];
}

-(void)handleRoomMessage:(Message*)msg {
    RoomMessage *rm = (RoomMessage*)msg.body;
    [self publishRoomMessage:rm];
}

-(void)handleSystemMessage:(Message*)msg {
    NSString *sys = (NSString*)msg.body;
    [self publishSystemMessage:sys];
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
}

-(void)publishPeerMessage:(IMMessage*)msg {
    for (id<PeerMessageObserver> ob in self.peerObservers) {
        if ([ob respondsToSelector:@selector(onPeerMessage:)]) {
            [ob onPeerMessage:msg];
        }
    }
}

-(void)publishPeerMessageACK:(int)msgLocalID uid:(int64_t)uid {
    for (id<PeerMessageObserver> ob in self.peerObservers) {
        if ([ob respondsToSelector:@selector(onPeerMessageACK:uid:)]) {
            [ob onPeerMessageACK:msgLocalID uid:uid];
        }
    }
}

-(void)publishPeerMessageFailure:(IMMessage*)msg {
    for (id<PeerMessageObserver> ob in self.peerObservers) {
        if ([ob respondsToSelector:@selector(onPeerMessageFailure:uid:)]) {
            [ob onPeerMessageFailure:msg.msgLocalID uid:msg.receiver];
        }
    }
}

-(void)publishGroupMessage:(IMMessage*)msg {
    for (id<GroupMessageObserver> ob in self.groupObservers) {
        if ([ob respondsToSelector:@selector(onGroupMessage:)]) {
            [ob onGroupMessage:msg];
        }
    }
}

-(void)publishGroupMessageACK:(int)msgLocalID gid:(int64_t)gid {
    for (id<GroupMessageObserver> ob in self.groupObservers) {
        if ([ob respondsToSelector:@selector(onGroupMessageACK:gid:)]) {
            [ob onGroupMessageACK:msgLocalID gid:gid];
        }
    }
}

-(void)publishGroupMessageFailure:(IMMessage*)msg {
    for (id<GroupMessageObserver> ob in self.groupObservers) {
        [ob onGroupMessageFailure:msg.msgLocalID gid:msg.receiver];
    }
}

-(void)publishRoomMessage:(RoomMessage*)msg {
    for (id<RoomMessageObserver> ob in self.roomObservers) {
        if ([ob respondsToSelector:@selector(onRoomMessage:)]) {
            [ob onRoomMessage:msg];
        }
    }
}

-(void)publishRoomMessageACK:(RoomMessage*)msg {
    for (id<RoomMessageObserver> ob in self.roomObservers) {
        if ([ob respondsToSelector:@selector(onRoomMessageACK:)]) {
            [ob onRoomMessageACK:msg];
        }
    }
}

-(void)publishRoomMessageFailure:(RoomMessage*)msg {
    for (id<RoomMessageObserver> ob in self.roomObservers) {
        if ([ob respondsToSelector:@selector(onRoomMessageFailure:)]) {
            [ob onRoomMessageFailure:msg];
        }
    }
}

-(void)publishLoginPoint:(LoginPoint*)lp {
    for (id<LoginPointObserver> ob in self.loginPointObservers) {
        if ([ob respondsToSelector:@selector(onLoginPoint:)]) {
            [ob onLoginPoint:lp];
        }
    }
}

-(void)publishSystemMessage:(NSString*)sys {
    for (id<SystemMessageObserver> ob in self.systemObservers) {
        if ([ob respondsToSelector:@selector(onSystemMessage:)]) {
            [ob onSystemMessage:sys];
        }
    }
}
-(void)handleMessage:(Message*)msg {
    if (msg.cmd == MSG_AUTH_STATUS) {
        [self handleAuthStatus:msg];
    } else if (msg.cmd == MSG_ACK) {
        [self handleACK:msg];
    } else if (msg.cmd == MSG_IM) {
        [self handleIMMessage:msg];
    } else if (msg.cmd == MSG_GROUP_IM) {
        [self handleGroupIMMessage:msg];
    } else if (msg.cmd == MSG_INPUTING) {
        [self handleInputing:msg];
    } else if (msg.cmd == MSG_PEER_ACK) {
        [self handlePeerACK:msg];
    } else if (msg.cmd == MSG_PONG) {
        [self handlePong:msg];
    } else if (msg.cmd == MSG_GROUP_NOTIFICATION) {
        [self handleGroupNotification:msg];
    } else if (msg.cmd == MSG_LOGIN_POINT) {
        [self handleLoginPoint:msg];
    } else if (msg.cmd == MSG_ROOM_IM) {
        [self handleRoomMessage:msg];
    } else if (msg.cmd == MSG_SYSTEM) {
        [self handleSystemMessage:msg];
    }
}

-(BOOL)handleData:(NSData*)data {
    [self.data appendData:data];
    int pos = 0;
    const uint8_t *p = [self.data bytes];
    while (YES) {
        if (self.data.length < pos + 4) {
            break;
        }
        int len = readInt32(p+pos);
        if (self.data.length < 4 + 8 + pos + len) {
            break;
        }
        NSData *tmp = [NSData dataWithBytes:p+4+pos length:len + 8];
        Message *msg = [[Message alloc] init];
        if (![msg unpack:tmp]) {
            NSLog(@"unpack message fail");
            return NO;
        }
        [self handleMessage:msg];
        pos += 4+8+len;
    }
    self.data = [NSMutableData dataWithBytes:p+pos length:self.data.length - pos];
    return YES;
}


-(void)addPeerMessageObserver:(id<PeerMessageObserver>)ob {
    [self.peerObservers addObject:ob];
}

-(void)removePeerMessageObserver:(id<PeerMessageObserver>)ob {
    [self.peerObservers removeObject:ob];
}

-(void)addGroupMessageObserver:(id<GroupMessageObserver>)ob {
    [self.groupObservers addObject:ob];
}

-(void)removeGroupMessageObserver:(id<GroupMessageObserver>)ob {
    [self.groupObservers removeObject:ob];
}


-(void)addLoginPointObserver:(id<LoginPointObserver>)ob {
    [self.loginPointObservers addObject:ob];
}
-(void)removeLoginPointObserver:(id<LoginPointObserver>)ob {
    [self.loginPointObservers removeObject:ob];
}

-(void)addRoomMessageObserver:(id<RoomMessageObserver>)ob {
    [self.roomObservers addObject:ob];
}

-(void)removeRoomMessageObserver:(id<RoomMessageObserver>)ob {
    [self.roomObservers removeObject:ob];
}

-(void)addSystemMessageObserver:(id<SystemMessageObserver>)ob {
    [self.systemObservers addObject:ob];
}

-(void)removeSystemMessageObserver:(id<SystemMessageObserver>)ob {
    [self.systemObservers removeObject:ob];
}

-(BOOL)isPeerMessageSending:(int)msgLocalID {
    for (NSNumber *s in self.peerMessages) {
        IMMessage *im = [self.peerMessages objectForKey:s];
        if (im.msgLocalID == msgLocalID) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)isGroupMessageSending:(int)msgLocalID {
    for (NSNumber *s in self.groupMessages) {
        IMMessage *im = [self.groupMessages objectForKey:s];
        if (im.msgLocalID == msgLocalID) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)sendPeerMessage:(IMMessage *)im {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_IM;
    m.body = im;
    BOOL r = [self sendMessage:m];

    if (!r) {
        return r;
    }
    [self.peerMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendGroupMessage:(IMMessage *)im {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_GROUP_IM;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) return r;
    [self.groupMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendRoomMessage:(RoomMessage*)rm {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_ROOM_IM;
    m.body = rm;
    BOOL r = [self sendMessage:m];
    if (!r) return r;
    [self.roomMessages setObject:rm forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendMessage:(Message *)msg {
    if (!self.tcp || self.connectState != STATE_CONNECTED) return NO;
    self.seq = self.seq + 1;
    msg.seq = self.seq;

    NSMutableData *data = [NSMutableData data];
    NSData *p = [msg pack];
    if (!p) {
        NSLog(@"message pack error");
        return NO;
    }
    char b[4];
    writeInt32((int)(p.length)-8, b);
    [data appendBytes:(void*)b length:4];
    [data appendData:p];
    [self.tcp write:data];
    return YES;
}


-(void)sendAuth {
    NSLog(@"send auth");
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_AUTH_TOKEN;
    AuthenticationToken *auth = [[AuthenticationToken alloc] init];
    auth.token = self.token;
    auth.platformID = PLATFORM_IOS;
    auth.deviceID = self.deviceID;
    msg.body = auth;
    [self sendMessage:msg];
}

-(void)onConnect {
    [self sendAuth];
    if (self.roomID > 0) {
        [self sendEnterRoom:self.roomID];
    }
}

-(void)onClose {
    for (NSNumber *seq in self.peerMessages) {
        IMMessage *msg = [self.peerMessages objectForKey:seq];
        [self.peerMessageHandler handleMessageFailure:msg.msgLocalID uid:msg.receiver];
        [self publishPeerMessageFailure:msg];
    }
    
    for (NSNumber *seq in self.groupMessages) {
        IMMessage *msg = [self.peerMessages objectForKey:seq];
        [self.groupMessageHandler handleMessageFailure:msg.msgLocalID gid:msg.receiver];
        [self publishGroupMessageFailure:msg];
    }
    
    for (NSNumber *seq in self.roomMessages) {
        RoomMessage *msg = [self.roomMessages objectForKey:seq];
        [self publishRoomMessageFailure:msg];
    }
    
    [self.peerMessages removeAllObjects];
    [self.groupMessages removeAllObjects];
    [self.roomMessages removeAllObjects];
}

-(void)sendPing {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_PING;
    [self sendMessage:msg];
}

//正在输入
-(void)sendInputing:(MessageInputing*)inputing {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_INPUTING;
    msg.body = inputing;
    [self sendMessage:msg];
}

-(void)sendEnterRoom:(int64_t)roomID {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_ENTER_ROOM;
    msg.body = [NSNumber numberWithLongLong:roomID];
    [self sendMessage:msg];
}

-(void)sendLeaveRoom:(int64_t)roomID {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_LEAVE_ROOM;
    msg.body = [NSNumber numberWithLongLong:self.roomID];
    [self sendMessage:msg];
}

-(void)enterRoom:(int64_t)roomID {
    if (roomID == 0) {
        return;
    }
    self.roomID = roomID;
    [self sendEnterRoom:self.roomID];
}

-(void)leaveRoom:(int64_t)roomID {
    if (roomID != self.roomID || roomID == 0) {
        return;
    }
    [self sendLeaveRoom:self.roomID];
    self.roomID = 0;
}

@end
