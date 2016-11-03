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

#define HOST  @"imnode2.gobelieve.io"
#define PORT 23000

@interface IMService()
@property(nonatomic)int seq;
@property(nonatomic)int64_t roomID;
@property(nonatomic)NSMutableArray *peerObservers;
@property(nonatomic)NSMutableArray *groupObservers;
@property(nonatomic)NSMutableArray *roomObservers;
@property(nonatomic)NSMutableArray *systemObservers;
@property(nonatomic)NSMutableArray *customerServiceObservers;
@property(nonatomic)NSMutableArray *voipObservers;
@property(nonatomic)NSMutableArray *rtObservers;

@property(nonatomic)NSMutableData *data;
@property(nonatomic)NSMutableDictionary *peerMessages;
@property(nonatomic)NSMutableDictionary *groupMessages;
@property(nonatomic)NSMutableDictionary *roomMessages;
@property(nonatomic)NSMutableDictionary *customerServiceMessages;

@property(nonatomic)NSMutableDictionary *groupSyncKeys;
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
        self.systemObservers = [NSMutableArray array];
        self.customerServiceObservers = [NSMutableArray array];
        self.voipObservers = [NSMutableArray array];
        self.rtObservers = [NSMutableArray array];
        
        self.data = [NSMutableData data];
        self.peerMessages = [NSMutableDictionary dictionary];
        self.groupMessages = [NSMutableDictionary dictionary];
        self.roomMessages = [NSMutableDictionary dictionary];
        self.customerServiceMessages = [NSMutableDictionary dictionary];
        self.groupSyncKeys = [NSMutableDictionary dictionary];
        
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
    CustomerMessage *m4 = [self.customerServiceMessages objectForKey:seq];
    if (!m && !m2 && !m3 && !m4) {
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
    } else if (m4) {
        [self.customerMessageHandler handleMessageACK:m4];
        [self.customerServiceMessages removeObjectForKey:seq];
        [self publishCustomerMessageACK:m4];
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

-(void)handleCustomerSupportMessage:(Message*)msg {
    CustomerMessage *im = (CustomerMessage*)msg.body;
    [self.customerMessageHandler handleCustomerSupportMessage:im];
    
    NSLog(@"customer support message customer id:%lld customer appid:%lld store id:%lld seller id:%lld content:%s",
          im.customerID, im.customerAppID, im.storeID, im.sellerID, [im.content UTF8String]);
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
    [self publishCustomerSupportMessage:im];
    
    //客服端收到发自客服的消息
    if (self.appID > 0 && im.sellerID == self.uid) {
        [self.customerMessageHandler handleMessageACK:im];
        [self publishCustomerMessageACK:im];
    }
}

-(void)handleCustomerMessage:(Message*)msg {
    CustomerMessage *im = (CustomerMessage*)msg.body;
    [self.customerMessageHandler handleMessage:im];
    
    NSLog(@"customer message customer id:%lld customer appid:%lld store id:%lld seller id:%lld content:%s",
          im.customerID, im.customerAppID, im.storeID, im.sellerID, [im.content UTF8String]);
    
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = [NSNumber numberWithInt:msg.seq];
    [self sendMessage:ack];
    [self publishCustomerMessage:im];
    
    //客户收到发自客户自己的消息
    if ((self.appID == 0 || self.appID == im.customerAppID) && im.customerID == self.uid) {
        [self.customerMessageHandler handleMessageACK:im];
        [self publishCustomerMessageACK:im];
    }
}

-(void)handleRTMessage:(Message*)msg {
    RTMessage *rt = (RTMessage*)msg.body;
    for (id<RTMessageObserver> ob in self.rtObservers) {
        if ([ob respondsToSelector:@selector(onRTMessage:)]) {
            [ob onRTMessage:rt];
        }
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

-(void)handleSyncBegin:(Message*)msg {
    NSLog(@"sync begin...:%@", msg.body);
}

-(void)handleSyncEnd:(Message*)msg {
    NSLog(@"sync end...:%@", msg.body);
    
    NSNumber *newSyncKey = (NSNumber*)msg.body;
    if ([newSyncKey longLongValue] > self.syncKey) {
        self.syncKey = [newSyncKey longLongValue];
        [self.syncKeyHandler saveSyncKey:self.syncKey];
    }
}

-(void)handleSyncNotify:(Message*)msg {
    NSLog(@"sync notify:%@", msg.body);
    NSNumber *newSyncKey = (NSNumber*)msg.body;
    
    if ([newSyncKey longLongValue] > self.syncKey) {
        [self sendSync:self.syncKey];
    }
}

-(void)handleSyncGroupBegin:(Message*)msg {
    GroupSyncKey *groupSyncKey = (GroupSyncKey*)msg.body;
    NSLog(@"sync group begin:%lld %lld", groupSyncKey.groupID, groupSyncKey.syncKey);
}

-(void)handleSyncGroupEnd:(Message*)msg {
    GroupSyncKey *groupSyncKey = (GroupSyncKey*)msg.body;
    NSLog(@"sync group end:%lld %lld", groupSyncKey.groupID, groupSyncKey.syncKey);
    
    NSNumber *originSyncKey = [self.groupSyncKeys objectForKey:[NSNumber numberWithLongLong:groupSyncKey.groupID]];
    
    if (groupSyncKey.syncKey > [originSyncKey longLongValue]) {
        [self.groupSyncKeys setObject:[NSNumber numberWithLongLong:groupSyncKey.syncKey] forKey:[NSNumber numberWithLongLong:groupSyncKey.groupID]];
        [self.syncKeyHandler saveGroupSyncKey:groupSyncKey.syncKey gid:groupSyncKey.groupID];
    }
    
}

-(void)handleSyncGroupNotify:(Message*)msg {
    GroupSyncKey *groupSyncKey = (GroupSyncKey*)msg.body;
    NSLog(@"sync group notify:%lld %lld", groupSyncKey.groupID, groupSyncKey.syncKey);
    
    NSNumber *originSyncKey = [self.groupSyncKeys objectForKey:[NSNumber numberWithLongLong:groupSyncKey.groupID]];
    
    if (groupSyncKey.syncKey > [originSyncKey longLongValue]) {
        [self sendGroupSyncKey:[originSyncKey longLongValue] gid:groupSyncKey.groupID];
    }
}

-(void)handleVOIPControl:(Message*)msg {
    VOIPControl *ctl = (VOIPControl*)msg.body;
    id<VOIPObserver> ob = [self.voipObservers lastObject];
    if (ob) {
        [ob onVOIPControl:ctl];
    }
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
        if ([ob respondsToSelector:@selector(onGroupMessageFailure:gid:)]) {
            [ob onGroupMessageFailure:msg.msgLocalID gid:msg.receiver];
        }
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

-(void)publishSystemMessage:(NSString*)sys {
    for (id<SystemMessageObserver> ob in self.systemObservers) {
        if ([ob respondsToSelector:@selector(onSystemMessage:)]) {
            [ob onSystemMessage:sys];
        }
    }
}

-(void)publishCustomerSupportMessage:(CustomerMessage*)msg {
    for (id<CustomerMessageObserver> ob in self.customerServiceObservers) {
        if ([ob respondsToSelector:@selector(onCustomerSupportMessage:)]) {
            [ob onCustomerSupportMessage:msg];
        }
    }
}

-(void)publishCustomerMessage:(CustomerMessage*)msg {
    for (id<CustomerMessageObserver> ob in self.customerServiceObservers) {
        if ([ob respondsToSelector:@selector(onCustomerMessage:)]) {
            [ob onCustomerMessage:msg];
        }
    }
}

-(void)publishCustomerMessageACK:(CustomerMessage*)msg {
    for (id<CustomerMessageObserver> ob in self.customerServiceObservers) {
        if ([ob respondsToSelector:@selector(onCustomerMessageACK:)]) {
            [ob onCustomerMessageACK:msg];
        }
    }
}

-(void)publishCustomerMessageFailure:(CustomerMessage*)msg {
    for (id<CustomerMessageObserver> ob in self.customerServiceObservers) {
        if ([ob respondsToSelector:@selector(onCustomerMessageFailure:)]) {
            [ob onCustomerMessageFailure:msg];
        }
    }
}

-(void)handleMessage:(Message*)msg {
    NSLog(@"message cmd:%d", msg.cmd);
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
    } else if (msg.cmd == MSG_PONG) {
        [self handlePong:msg];
    } else if (msg.cmd == MSG_GROUP_NOTIFICATION) {
        [self handleGroupNotification:msg];
    } else if (msg.cmd == MSG_ROOM_IM) {
        [self handleRoomMessage:msg];
    } else if (msg.cmd == MSG_SYSTEM) {
        [self handleSystemMessage:msg];
    } else if (msg.cmd == MSG_CUSTOMER) {
        [self handleCustomerMessage:msg];
    } else if (msg.cmd == MSG_CUSTOMER_SUPPORT) {
        [self handleCustomerSupportMessage:msg];
    } else if (msg.cmd == MSG_VOIP_CONTROL) {
        [self handleVOIPControl:msg];
    } else if (msg.cmd == MSG_RT) {
        [self handleRTMessage:msg];
    } else if (msg.cmd == MSG_SYNC_NOTIFY) {
        [self handleSyncNotify:msg];
    } else if (msg.cmd == MSG_SYNC_BEGIN) {
        [self handleSyncBegin:msg];
    } else if (msg.cmd == MSG_SYNC_END) {
        [self handleSyncEnd:msg];
    } else if (msg.cmd == MSG_SYNC_GROUP_NOTIFY) {
        [self handleSyncGroupNotify:msg];
    } else if (msg.cmd == MSG_SYNC_GROUP_BEGIN) {
        [self handleSyncGroupBegin:msg];
    } else if (msg.cmd == MSG_SYNC_GROUP_END) {
        [self handleSyncGroupEnd:msg];
    } else {
        NSLog(@"cmd:%d no handler", msg.cmd);
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

-(void)addCustomerMessageObserver:(id<CustomerMessageObserver>)ob {
    [self.customerServiceObservers addObject:ob];
}

-(void)removeCustomerMessageObserver:(id<CustomerMessageObserver>)ob {
    [self.customerServiceObservers removeObject:ob];
}

-(void)addRTMessageObserver:(id<RTMessageObserver>)ob {
    [self.rtObservers addObject:ob];
}

-(void)removeRTMessageObserver:(id<RTMessageObserver>)ob {
    [self.rtObservers removeObject:ob];
}

-(void)pushVOIPObserver:(id<VOIPObserver>)ob {
    [self.voipObservers addObject:ob];
}

-(void)popVOIPObserver:(id<VOIPObserver>)ob {
    NSInteger count = [self.voipObservers count];
    if (count == 0) {
        return;
    }
    id<VOIPObserver> top = [self.voipObservers objectAtIndex:count-1];
    if (top == ob) {
        [self.voipObservers removeObject:top];
    }
}

-(void)removeSuperGroupSyncKey:(int64_t)gid {
    NSNumber *k = [NSNumber numberWithLongLong:gid];
    [self.groupSyncKeys removeObjectForKey:k];
}

-(void)addSuperGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid {
    NSNumber *k = [NSNumber numberWithLongLong:gid];
    NSNumber *v = [NSNumber numberWithLongLong:syncKey];
    
    [self.groupSyncKeys setObject:v forKey:k];
}

-(void)clearSuperGroupSyncKey {
    [self.groupSyncKeys removeAllObjects];
}

-(BOOL)sendVOIPControl:(VOIPControl*)ctl {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_VOIP_CONTROL;
    m.body = ctl;
    return [self sendMessage:m];
}


-(BOOL)isPeerMessageSending:(int64_t)peer id:(int)msgLocalID {
    for (NSNumber *s in self.peerMessages) {
        IMMessage *im = [self.peerMessages objectForKey:s];
        if (im.receiver == peer && im.msgLocalID == msgLocalID) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)isGroupMessageSending:(int64_t)groupID id:(int)msgLocalID {
    for (NSNumber *s in self.groupMessages) {
        IMMessage *im = [self.groupMessages objectForKey:s];
        if (im.receiver == groupID && im.msgLocalID == msgLocalID) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)isCustomerSupportMessageSending:(int)msgLocalID customerID:(int64_t)customerID customerAppID:(int64_t)customerAppID {
    for (NSNumber *s in self.customerServiceMessages) {
        CustomerMessage *im = [self.customerServiceMessages objectForKey:s];
        if (im.msgLocalID == msgLocalID &&
            im.customerID == customerID &&
            im.customerAppID == customerAppID) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)isCustomerMessageSending:(int)msgLocalID  storeID:(int64_t)storeID {
    for (NSNumber *s in self.customerServiceMessages) {
        CustomerMessage *im = [self.customerServiceMessages objectForKey:s];
        
        if (im.msgLocalID == msgLocalID && im.storeID == storeID) {
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

-(BOOL)sendCustomerSupportMessage:(CustomerMessage*)im {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_CUSTOMER_SUPPORT;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) {
        return r;
    }
    [self.customerServiceMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendCustomerMessage:(CustomerMessage*)im {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_CUSTOMER;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) {
        return r;
    }
    [self.customerServiceMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(BOOL)sendRTMessage:(RTMessage *)rt {
    Message *m = [[Message alloc] init];
    m.cmd = MSG_RT;
    m.body = rt;
    BOOL r = [self sendMessage:m];
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
    
    //send sync
    [self sendSync:self.syncKey];
    
    for (NSNumber *k in self.groupSyncKeys) {
        NSNumber *v = [self.groupSyncKeys objectForKey:k];
        [self sendGroupSyncKey:[v longLongValue] gid:[k longLongValue]];
    }
}

-(void)sendSync:(int64_t)syncKey {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_SYNC;
    msg.body = [NSNumber numberWithLongLong:syncKey];
    [self sendMessage:msg];
}

-(void)sendGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_SYNC_GROUP;
    GroupSyncKey *s = [[GroupSyncKey alloc] init];
    s.groupID = gid;
    s.syncKey = syncKey;
    msg.body = s;
    [self sendMessage:msg];
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
    
    for (NSNumber *seq in self.customerServiceMessages) {
        CustomerMessage *msg = [self.customerServiceMessages objectForKey:seq];
        [self.customerMessageHandler handleMessageFailure:msg];
        [self publishCustomerMessageFailure:msg];
    }
    
    [self.peerMessages removeAllObjects];
    [self.groupMessages removeAllObjects];
    [self.roomMessages removeAllObjects];
    [self.customerServiceMessages removeAllObjects];
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

-(void)sendUnreadCount:(int)unread {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_UNREAD_COUNT;
    msg.body = [NSNumber numberWithInt:unread];
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
