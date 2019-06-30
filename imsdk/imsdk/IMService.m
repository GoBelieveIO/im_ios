
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


#define HEARTBEAT_HZ (180)

#define HOST  @"imnode2.gobelieve.io"
#define PORT 23000


@interface GroupSync : NSObject
@property(nonatomic, assign) int64_t groupID;
@property(nonatomic, assign) int64_t syncKey;
@property(nonatomic, assign) int64_t peedingSyncKey;
@property(nonatomic, assign) int32_t syncTimestamp;
@property(nonatomic, assign) BOOL isSyncing;
@end

@implementation GroupSync
@end

@interface IMService()
@property(nonatomic)int seq;
@property(nonatomic)int64_t roomID;
@property(nonatomic)NSMutableArray *peerObservers;
@property(nonatomic)NSMutableArray *groupObservers;
@property(nonatomic)NSMutableArray *roomObservers;
@property(nonatomic)NSMutableArray *systemObservers;
@property(nonatomic)NSMutableArray *customerServiceObservers;
@property(nonatomic)NSMutableArray *rtObservers;

@property(nonatomic)NSMutableData *data;
@property(nonatomic)NSMutableDictionary *peerMessages;
@property(nonatomic)NSMutableDictionary *groupMessages;
@property(nonatomic)NSMutableDictionary *roomMessages;
@property(nonatomic)NSMutableDictionary *customerServiceMessages;

//优化，收到群组消息后，缓存到数组中， 然后一次性调用observer，这样可以只需要更新一次ui
@property(nonatomic)NSMutableArray *receivedGroupMessages;

@property(nonatomic)Message *metaMessage;

//保证一个时刻只存在一个同步过程，否则会导致获取到重复的消息
@property(nonatomic, assign) int64_t peedingSyncKey;
@property(nonatomic, assign) BOOL isSyncing;
@property(nonatomic, assign) int32_t syncTimestmap;


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
        self.rtObservers = [NSMutableArray array];
        
        self.receivedGroupMessages = [NSMutableArray array];
        
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
    MessageACK *ack = (MessageACK*)msg.body;
    NSNumber *seq = @(ack.seq);
    IMMessage *m = (IMMessage*)[self.peerMessages objectForKey:seq];
    IMMessage *m2 = (IMMessage*)[self.groupMessages objectForKey:seq];
    RoomMessage *m3 = (RoomMessage*)[self.roomMessages objectForKey:seq];
    CustomerMessage *m4 = [self.customerServiceMessages objectForKey:seq];
    if (!m && !m2 && !m3 && !m4) {
        return;
    }
    if (m) {
        [self.peerMessageHandler handleMessageACK:m];
        [self.peerMessages removeObjectForKey:seq];
        [self publishPeerMessageACK:m];
    } else if (m2) {
        [self.groupMessageHandler handleMessageACK:m2];
        [self.groupMessages removeObjectForKey:seq];
        [self publishGroupMessageACK:m2];
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
    im.isSelf = msg.flag & MESSAGE_FLAG_SELF;
    [self.peerMessageHandler handleMessage:im];
    NSLog(@"peer message sender:%lld receiver:%lld content:%s", im.sender, im.receiver, [im.content UTF8String]);
    
    [self sendACK:msg.seq];
    if (im.secret) {
        [self publishPeerSecretMessage:im];
    } else {
        [self publishPeerMessage:im];
    }
}

-(void)handleGroupIMMessage:(Message*)msg {
    IMMessage *im = (IMMessage*)msg.body;
    im.isSelf = msg.flag & MESSAGE_FLAG_SELF;
    NSLog(@"group message sender:%lld receiver:%lld content:%s", im.sender, im.receiver, [im.content UTF8String]);
    [self sendACK:msg.seq];
    
    if (msg.flag & MESSAGE_FLAG_PUSH) {
        NSArray *array = @[im];
        [self.groupMessageHandler handleMessages:array];
        [self publishGroupMessages:array];
    } else {
        [self.receivedGroupMessages addObject:im];
    }
}

-(void)handleCustomerSupportMessage:(Message*)msg {
    CustomerMessage *im = (CustomerMessage*)msg.body;
    im.isSelf = msg.flag & MESSAGE_FLAG_SELF;
    [self.customerMessageHandler handleCustomerSupportMessage:im];
    
    NSLog(@"customer support message customer id:%lld customer appid:%lld store id:%lld seller id:%lld content:%s",
          im.customerID, im.customerAppID, im.storeID, im.sellerID, [im.content UTF8String]);
    
    [self sendACK:msg.seq];
    [self publishCustomerSupportMessage:im];
}

-(void)handleCustomerMessage:(Message*)msg {
    CustomerMessage *im = (CustomerMessage*)msg.body;
    im.isSelf = msg.flag & MESSAGE_FLAG_SELF;
    [self.customerMessageHandler handleMessage:im];
    
    NSLog(@"customer message customer id:%lld customer appid:%lld store id:%lld seller id:%lld content:%s",
          im.customerID, im.customerAppID, im.storeID, im.sellerID, [im.content UTF8String]);
    
    [self sendACK:msg.seq];
    [self publishCustomerMessage:im];
}

-(void)handleRTMessage:(Message*)msg {
    RTMessage *rt = (RTMessage*)msg.body;
    [self publishRTMessage:rt];
    

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

-(void)handlePong:(Message*)msg {
    [self pong];
}

-(void)handleGroupNotification:(Message*)msg {
    NSString *notification = (NSString*)msg.body;
    NSLog(@"group notification:%@", notification);
    [self.groupMessageHandler handleGroupNotification:notification];
    for (NSValue *value in self.groupObservers) {
        id<GroupMessageObserver> ob = [value nonretainedObjectValue];
        if ([ob respondsToSelector:@selector(onGroupNotification:)]) {
            [ob onGroupNotification:notification];
        }
    }
    
    [self sendACK:msg.seq];
}

-(void)handleRoomMessage:(Message*)msg {
    RoomMessage *rm = (RoomMessage*)msg.body;
    [self publishRoomMessage:rm];
}

-(void)handleSystemMessage:(Message*)msg {
    NSString *sys = (NSString*)msg.body;
    [self publishSystemMessage:sys];
    
    [self sendACK:msg.seq];
}

-(void)handleSyncBegin:(Message*)msg {
    NSLog(@"sync begin...:%@", msg.body);
}

-(void)handleSyncEnd:(Message*)msg {
    NSLog(@"sync end...:%@", msg.body);

    if (self.receivedGroupMessages.count > 0) {
        [self.groupMessageHandler handleMessages:self.receivedGroupMessages];
        [self publishGroupMessages:self.receivedGroupMessages];
        [self.receivedGroupMessages removeAllObjects];
    }
    

    NSNumber *newSyncKey = (NSNumber*)msg.body;
    if ([newSyncKey longLongValue] !=  self.syncKey) {
        self.syncKey = [newSyncKey longLongValue];
        [self.syncKeyHandler saveSyncKey:self.syncKey];
        [self sendSyncKey:self.syncKey];
    }

    self.isSyncing = NO;
    
    if (self.peedingSyncKey > self.syncKey) {
        //在本次同步过程中，再次收到了新的SyncNotify消息
        [self sendSync:self.syncKey];
        self.isSyncing = YES;
        self.syncTimestmap = (int)time(NULL);
        self.peedingSyncKey = 0;
    }
}

-(void)handleSyncNotify:(Message*)msg {
    NSLog(@"sync notify:%@", msg.body);
    NSNumber *newSyncKey = (NSNumber*)msg.body;

    int now = (int)time(NULL);
    //4s同步超时
    BOOL isSyncing = self.isSyncing && (now - self.syncTimestmap < 4);
    if (!isSyncing && [newSyncKey longLongValue] > self.syncKey) {
        [self sendSync:self.syncKey];
        self.isSyncing = YES;
        self.syncTimestmap = (int)time(NULL);
    } else if ([newSyncKey longLongValue] > self.peedingSyncKey) {
        self.peedingSyncKey = [newSyncKey longLongValue];
    }
}

-(void)handleSyncGroupBegin:(Message*)msg {
    GroupSyncKey *groupSyncKey = (GroupSyncKey*)msg.body;
    NSLog(@"sync group begin:%lld %lld", groupSyncKey.groupID, groupSyncKey.syncKey);
}

-(void)handleSyncGroupEnd:(Message*)msg {
    GroupSyncKey *groupSyncKey = (GroupSyncKey*)msg.body;
    NSLog(@"sync group end:%lld %lld", groupSyncKey.groupID, groupSyncKey.syncKey);
    
    if (self.receivedGroupMessages.count > 0) {
        [self.groupMessageHandler handleMessages:self.receivedGroupMessages];
        [self publishGroupMessages:self.receivedGroupMessages];
        [self.receivedGroupMessages removeAllObjects];
    }
    
    GroupSync *s = [self.groupSyncKeys objectForKey:[NSNumber numberWithLongLong:groupSyncKey.groupID]];
    if (!s) {
        NSLog(@"no group:%lld sync key", groupSyncKey.groupID);
        return;
    }

    if (groupSyncKey.syncKey != s.syncKey) {
        s.syncKey = groupSyncKey.syncKey;
        [self.syncKeyHandler saveGroupSyncKey:groupSyncKey.syncKey gid:groupSyncKey.groupID];
        [self sendGroupSyncKey:groupSyncKey.syncKey gid:groupSyncKey.groupID];
    }
    
    s.isSyncing = NO;
    
    if (s.peedingSyncKey > s.syncKey) {
        //上次同步过程中，再次收到了新的SyncGroupNotify消息
        [self sendGroupSync:s.syncKey gid:s.groupID];
        s.syncTimestamp = (int)time(NULL);
        s.isSyncing = YES;
        s.peedingSyncKey = 0;
    }
}

-(void)handleSyncGroupNotify:(Message*)msg {
    GroupSyncNotify *notify = (GroupSyncNotify*)msg.body;
    NSLog(@"sync group notify:%lld %lld", notify.groupID, notify.syncKey);
    
    GroupSync *s = [self.groupSyncKeys objectForKey:[NSNumber numberWithLongLong:notify.groupID]];
    if (!s) {
        //新加入的超级群
        s = [[GroupSync alloc] init];
        s.groupID = notify.groupID;
        s.syncKey = 0;
        [self.groupSyncKeys setObject:s forKey:[NSNumber numberWithLongLong:notify.groupID]];
    }
    
    int now = (int)time(NULL);
    //4s同步超时
    BOOL isSyncing = s.isSyncing && (now - s.syncTimestamp < 4);
    
    if (!isSyncing && notify.syncKey > s.syncKey) {
        [self sendGroupSync:s.syncKey gid:s.groupID];
        s.syncTimestamp = now;
        s.isSyncing = YES;
    } else if (notify.syncKey > s.peedingSyncKey) {
        s.peedingSyncKey = notify.syncKey;
    }
}

-(void)handleMetadata:(Message*)msg {
    self.metaMessage = msg;
}

-(void)publishPeerMessage:(IMMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.peerObservers) {
            id<PeerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onPeerMessage:)]) {
                [ob onPeerMessage:msg];
            }
        }
    }];

}

-(void)publishPeerSecretMessage:(IMMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.peerObservers) {
            id<PeerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onPeerSecretMessage:)]) {
                [ob onPeerSecretMessage:msg];
            }
        }
    }];

}


-(void)publishPeerMessageACK:(IMMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.peerObservers) {
            id<PeerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onPeerMessageACK:)]) {
                [ob onPeerMessageACK:msg];
            }
        }
    }];
}

-(void)publishPeerMessageFailure:(IMMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.peerObservers) {
            id<PeerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onPeerMessageFailure:)]) {
                [ob onPeerMessageFailure:msg];
            }
        }
    }];

}

-(void)publishGroupMessages:(NSArray*)msgs {
    [self runOnMainThread:^{
        for (NSValue *value in self.groupObservers) {
            id<GroupMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onGroupMessages:)]) {
                [ob onGroupMessages:msgs];
            }
        }
    }];

}

-(void)publishGroupMessageACK:(IMMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.groupObservers) {
            id<GroupMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onGroupMessageACK:)]) {
                [ob onGroupMessageACK:msg];
            }
        }
    }];
}

-(void)publishGroupMessageFailure:(IMMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.groupObservers) {
            id<GroupMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onGroupMessageFailure:)]) {
                [ob onGroupMessageFailure:msg];
            }
        }
    }];

}

-(void)publishRoomMessage:(RoomMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.roomObservers) {
            id<RoomMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onRoomMessage:)]) {
                [ob onRoomMessage:msg];
            }
        }
    }];
}

-(void)publishRoomMessageACK:(RoomMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.roomObservers) {
            id<RoomMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onRoomMessageACK:)]) {
                [ob onRoomMessageACK:msg];
            }
        }
    }];
}

-(void)publishRoomMessageFailure:(RoomMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.roomObservers) {
            id<RoomMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onRoomMessageFailure:)]) {
                [ob onRoomMessageFailure:msg];
            }
        }
    }];
}

-(void)publishRTMessage:(RTMessage*)rt {
    [self runOnMainThread:^{
        for (NSValue *value in self.rtObservers) {
            id<RTMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onRTMessage:)]) {
                [ob onRTMessage:rt];
            }
        }
    }];
}

-(void)publishSystemMessage:(NSString*)sys {
    [self runOnMainThread:^{
        for (NSValue *value in self.systemObservers) {
            id<SystemMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onSystemMessage:)]) {
                [ob onSystemMessage:sys];
            }
        }
    }];

}

-(void)publishCustomerSupportMessage:(CustomerMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.customerServiceObservers) {
            id<CustomerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onCustomerSupportMessage:)]) {
                [ob onCustomerSupportMessage:msg];
            }
        }
    }];
}

-(void)publishCustomerMessage:(CustomerMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.customerServiceObservers) {
            id<CustomerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onCustomerMessage:)]) {
                [ob onCustomerMessage:msg];
            }
        }
    }];
}

-(void)publishCustomerMessageACK:(CustomerMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.customerServiceObservers) {
            id<CustomerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onCustomerMessageACK:)]) {
                [ob onCustomerMessageACK:msg];
            }
        }
    }];
}

-(void)publishCustomerMessageFailure:(CustomerMessage*)msg {
    [self runOnMainThread:^{
        for (NSValue *value in self.customerServiceObservers) {
            id<CustomerMessageObserver> ob = [value nonretainedObjectValue];
            if ([ob respondsToSelector:@selector(onCustomerMessageFailure:)]) {
                [ob onCustomerMessageFailure:msg];
            }
        }
    }];
}

-(void)handleMessage:(Message*)msg {
    NSLog(@"message cmd:%d", msg.cmd);
    
    Metadata *metadata = nil;
    
    //处理服务器推到客户端的消息,
    if (msg.flag & MESSAGE_FLAG_PUSH) {
        Message *metaMessage = self.metaMessage;
        self.metaMessage = nil;
        if (metaMessage && metaMessage.seq + 1 == msg.seq) {
            Metadata *meta = (Metadata*)metaMessage.body;
            metadata = meta;
        } else {
            //no metadata, ignore the push message
            return;
        }
        
        if (metadata.prevSyncKey == 0 || metadata.syncKey == 0) {
            //no metadata, ignore the push message
            return;
        }
        
        //校验metadata中的synckey是否连续
        if (msg.flag & MESSAGE_FLAG_SUPER_GROUP) {
            if (msg.cmd != MSG_GROUP_IM) {
                return;
            }
            IMMessage *m = (IMMessage*)msg.body;
            int64_t groupID = m.receiver;
            GroupSync *s = [self.groupSyncKeys objectForKey:@(groupID)];
            if (metadata.prevSyncKey != s.syncKey) {
                NSLog(@"sync key is not sequence:%lld---%lld, ignore push message", metadata.prevSyncKey, s.syncKey);
                return;
            }
        } else {
            if (metadata.prevSyncKey != self.syncKey) {
                NSLog(@"sync key is not sequence:%lld---%lld, ignore push message", metadata.prevSyncKey, self.syncKey);
                return;
            }
        }
    }
    
    if (msg.cmd == MSG_AUTH_STATUS) {
        [self handleAuthStatus:msg];
    } else if (msg.cmd == MSG_ACK) {
        [self handleACK:msg];
    } else if (msg.cmd == MSG_IM) {
        [self handleIMMessage:msg];
    } else if (msg.cmd == MSG_GROUP_IM) {
        [self handleGroupIMMessage:msg];
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
    } else if (msg.cmd == MSG_METADATA) {
        [self handleMetadata:msg];
    } else {
        NSLog(@"cmd:%d no handler", msg.cmd);
    }
    
    if (msg.flag & MESSAGE_FLAG_PUSH) {
        //保存synckey
        int64_t newSyncKey = metadata.syncKey;
        if (msg.flag & MESSAGE_FLAG_SUPER_GROUP) {
            if (msg.cmd != MSG_GROUP_IM) {
                return;
            }
            IMMessage *m = (IMMessage*)msg.body;
            int64_t groupID = m.receiver;
            
            GroupSync *s = [self.groupSyncKeys objectForKey:@(groupID)];
            
            if (newSyncKey != s.syncKey) {
                s.syncKey = newSyncKey;
                [self.syncKeyHandler saveGroupSyncKey:newSyncKey gid:groupID];
                [self sendGroupSyncKey:newSyncKey gid:groupID];
            }
        } else {
            if (newSyncKey !=  self.syncKey) {
                self.syncKey = newSyncKey;
                [self.syncKeyHandler saveSyncKey:self.syncKey];
                [self sendSyncKey:self.syncKey];
            }
        }
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
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.peerObservers containsObject:value]) {
        [self.peerObservers addObject:value];
    }
}

-(void)removePeerMessageObserver:(id<PeerMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.peerObservers removeObject:value];
}

-(void)addGroupMessageObserver:(id<GroupMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.groupObservers containsObject:value]) {
        [self.groupObservers addObject:value];
    }
}

-(void)removeGroupMessageObserver:(id<GroupMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.groupObservers removeObject:value];
}

-(void)addRoomMessageObserver:(id<RoomMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.roomObservers containsObject:value]) {
        [self.roomObservers addObject:value];
    }
}

-(void)removeRoomMessageObserver:(id<RoomMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.roomObservers removeObject:value];
}

-(void)addSystemMessageObserver:(id<SystemMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.systemObservers containsObject:value]) {
        [self.systemObservers addObject:value];
    }
}

-(void)removeSystemMessageObserver:(id<SystemMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.systemObservers removeObject:value];
}

-(void)addCustomerMessageObserver:(id<CustomerMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.customerServiceObservers containsObject:value]) {
        [self.customerServiceObservers addObject:value];
    }
}

-(void)removeCustomerMessageObserver:(id<CustomerMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.customerServiceObservers removeObject:value];
}

-(void)addRTMessageObserver:(id<RTMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    if (![self.rtObservers containsObject:value]) {
        [self.rtObservers addObject:value];
    }
}

-(void)removeRTMessageObserver:(id<RTMessageObserver>)ob {
    NSValue *value = [NSValue valueWithNonretainedObject:ob];
    [self.rtObservers removeObject:value];
}


-(void)removeSuperGroupSyncKey:(int64_t)gid {
    NSNumber *k = [NSNumber numberWithLongLong:gid];
    [self.groupSyncKeys removeObjectForKey:k];
}

-(void)addSuperGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid {
    NSNumber *k = [NSNumber numberWithLongLong:gid];
    GroupSync *s = [[GroupSync alloc] init];
    s.groupID = gid;
    s.syncKey = syncKey;
    [self.groupSyncKeys setObject:s forKey:k];
    [self sendGroupSync:syncKey gid:gid];
}

-(void)clearSuperGroupSyncKey {
    [self.groupSyncKeys removeAllObjects];
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

-(void)sendPeerMessageAsync:(IMMessage *)im {
    dispatch_async(self.queue, ^{
        BOOL r = [self sendPeerMessage:im];
        if (!r) {
            [self.peerMessageHandler handleMessageFailure:im];
            [self publishPeerMessageFailure:im];
        }
    });
}

-(BOOL)sendPeerMessage:(IMMessage *)im {
    [self assertWorkQueue];
    Message *m = [[Message alloc] init];
    m.cmd = MSG_IM;
    m.body = im;
    BOOL r = [self sendMessage:m];

    if (!r) {
        return r;
    }
    [self.peerMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    
    //在发送需要回执的消息时尽快发现socket已经断开的情况
    [self ping];
    
    return r;
}

-(void)sendGroupMessageAsync:(IMMessage *)im {
    dispatch_async(self.queue, ^{
        BOOL r = [self sendGroupMessage:im];
        if (!r) {
            [self.groupMessageHandler handleMessageFailure:im];
            [self publishGroupMessageFailure:im];
        }
    });
}

-(BOOL)sendGroupMessage:(IMMessage *)im {
    [self assertWorkQueue];
    Message *m = [[Message alloc] init];
    m.cmd = MSG_GROUP_IM;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) return r;
    [self.groupMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    
    //在发送需要回执的消息时尽快发现socket已经断开的情况
    [self ping];
    
    return r;
}

-(void)sendRoomMessageAsync:(RoomMessage*)rm {
    dispatch_async(self.queue, ^{
        [self sendRoomMessage:rm];
    });
}

-(BOOL)sendRoomMessage:(RoomMessage*)rm {
    [self assertWorkQueue];
    Message *m = [[Message alloc] init];
    m.cmd = MSG_ROOM_IM;
    m.body = rm;
    BOOL r = [self sendMessage:m];
    if (!r) return r;
    [self.roomMessages setObject:rm forKey:[NSNumber numberWithInt:m.seq]];
    return r;
}

-(void)sendCustomerSupportMessageAsync:(CustomerMessage *)im {
    dispatch_async(self.queue, ^{
        BOOL r = [self sendCustomerSupportMessage:im];
        if (!r) {
            [self.customerMessageHandler handleMessageFailure:im];
            [self publishCustomerMessageFailure:im];
        }
    });
}

-(BOOL)sendCustomerSupportMessage:(CustomerMessage*)im {
    [self assertWorkQueue];
    Message *m = [[Message alloc] init];
    m.cmd = MSG_CUSTOMER_SUPPORT;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) {
        return r;
    }
    [self.customerServiceMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    
    //在发送需要回执的消息时尽快发现socket已经断开的情况
    [self ping];
    
    return r;
}

-(void)sendCustomerMessageAsync:(CustomerMessage *)im {
    dispatch_async(self.queue, ^{
        BOOL r = [self sendCustomerMessage:im];
        if (!r) {
            [self.customerMessageHandler handleMessageFailure:im];
            [self publishCustomerMessageFailure:im];
        }
    });
}

-(BOOL)sendCustomerMessage:(CustomerMessage*)im {
    [self assertWorkQueue];
    Message *m = [[Message alloc] init];
    m.cmd = MSG_CUSTOMER;
    m.body = im;
    BOOL r = [self sendMessage:m];
    
    if (!r) {
        return r;
    }
    [self.customerServiceMessages setObject:im forKey:[NSNumber numberWithInt:m.seq]];
    
    //在发送需要回执的消息时尽快发现socket已经断开的情况
    [self ping];
    
    return r;
}

-(void)sendRTMessageAsync:(RTMessage *)rt {
    dispatch_async(self.queue, ^{
        [self sendRTMessage:rt];
    });
}

-(BOOL)sendRTMessage:(RTMessage *)rt {
    [self assertWorkQueue];
    Message *m = [[Message alloc] init];
    m.cmd = MSG_RT;
    m.body = rt;
    BOOL r = [self sendMessage:m];
    return r;
}

-(BOOL)sendMessage:(Message *)msg {
    NSLog(@"send message:%d", msg.cmd);
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
    self.data = [NSMutableData data];
    self.peedingSyncKey = 0;
    self.isSyncing = 0;
    self.syncTimestmap = 0;
    for (NSNumber *k in self.groupSyncKeys) {
        GroupSync *v = [self.groupSyncKeys objectForKey:k];
        v.isSyncing = NO;
        v.syncTimestamp = 0;
        v.peedingSyncKey = 0;
    }
    
    
    [self sendAuth];
    if (self.roomID > 0) {
        [self sendEnterRoom:self.roomID];
    }
    
    int now = (int)time(NULL);
    //send sync
    [self sendSync:self.syncKey];
    self.isSyncing = YES;
    self.syncTimestmap = now;
    
    for (NSNumber *k in self.groupSyncKeys) {
        GroupSync *v = [self.groupSyncKeys objectForKey:k];
        [self sendGroupSync:v.syncKey gid:v.groupID];
        v.isSyncing = YES;
        v.syncTimestamp = now;
    }
}

-(void)sendSync:(int64_t)syncKey {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_SYNC;
    msg.body = [NSNumber numberWithLongLong:syncKey];
    [self sendMessage:msg];
}

-(void)sendSyncKey:(int64_t)syncKey {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_SYNC_KEY;
    msg.body = [NSNumber numberWithLongLong:syncKey];
    [self sendMessage:msg];
}

-(void)sendGroupSync:(int64_t)syncKey gid:(int64_t)gid {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_SYNC_GROUP;
    GroupSyncKey *s = [[GroupSyncKey alloc] init];
    s.groupID = gid;
    s.syncKey = syncKey;
    msg.body = s;
    [self sendMessage:msg];
}

-(void)sendGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_GROUP_SYNC_KEY;
    GroupSyncKey *s = [[GroupSyncKey alloc] init];
    s.groupID = gid;
    s.syncKey = syncKey;
    msg.body = s;
    [self sendMessage:msg];
}

-(void)onClose {
    if (self.receivedGroupMessages.count) {
        NSLog(@"received group messages:%@", self.receivedGroupMessages);
        [self.receivedGroupMessages removeAllObjects];
    }
    
    if (self.metaMessage) {
        NSLog(@"socket closed, meta message:%@", self.metaMessage);
        self.metaMessage = nil;
    }
    
    for (NSNumber *seq in self.peerMessages) {
        IMMessage *msg = [self.peerMessages objectForKey:seq];
        [self.peerMessageHandler handleMessageFailure:msg];
        [self publishPeerMessageFailure:msg];
    }
    
    for (NSNumber *seq in self.groupMessages) {
        IMMessage *msg = [self.groupMessages objectForKey:seq];
        [self.groupMessageHandler handleMessageFailure:msg];
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

-(void)sendACK:(int)seq {
    MessageACK *a = [[MessageACK alloc] init];
    a.seq = seq;
    Message *ack = [[Message alloc] init];
    ack.cmd = MSG_ACK;
    ack.body = a;
    [self sendMessage:ack];
}

-(void)sendPing {
    Message *msg = [[Message alloc] init];
    msg.cmd = MSG_PING;
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
    [self runOnWorkQueue:^{
        self.roomID = roomID;
        [self sendEnterRoom:self.roomID];
    }];
}

-(void)leaveRoom:(int64_t)roomID {
    if ( roomID == 0) {
        return;
    }
    
    [self runOnWorkQueue:^{
        if (roomID != self.roomID) {
            return;
        }
        [self sendLeaveRoom:self.roomID];
        self.roomID = 0;
    }];
}

@end
