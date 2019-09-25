/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "Message.h"
#import "util.h"

#define HEAD_SIZE 8
#define VERSION 2

@implementation IMMessage

@end

@implementation CustomerMessage

@end

@implementation RoomMessage

@end


@implementation AuthenticationToken

@end

@implementation ACKMessage

@end

@implementation GroupSyncKey

@end



@implementation Metadata

@end

@implementation Message
-(NSData*)pack {
    char buf[64*1024] = {0};
    char *p = buf;

    writeInt32(self.seq, p);
    p += 4;
    *p++ = (uint8_t)self.cmd;
    *p++ = (uint8_t)VERSION;
    *p++ = (uint8_t)self.flag;
    p++;
    
    if (self.cmd == MSG_HEARTBEAT || self.cmd == MSG_PING) {
        return [NSData dataWithBytes:buf length:HEAD_SIZE];
    } else if (self.cmd == MSG_AUTH_TOKEN) {
        AuthenticationToken *auth = (AuthenticationToken*)self.body;
        *p++ = auth.platformID;
        const char *t;
        t = [auth.token UTF8String];
        *p++ = strlen(t);
        memcpy(p, t, strlen(t));
        p += strlen(t);
        t = [auth.deviceID UTF8String];
        *p++ = strlen(t);
        memcpy(p, t, strlen(t));
        p += strlen(t);
        return [NSData dataWithBytes:buf length:(p-buf)];
    }  else if (self.cmd == MSG_IM || self.cmd == MSG_GROUP_IM) {
        IMMessage *m = (IMMessage*)self.body;
        writeInt64(m.sender, p);
        p += 8;
        writeInt64(m.receiver, p);
        p += 8;
        writeInt32(m.timestamp, p);
        p += 4;
        writeInt32(0, p);
        p += 4;
        const char *s = [m.content UTF8String];
        size_t l = strlen(s);
        if ((l + 36) > 64*1024) {
            return nil;
        }
        memcpy(p, s, l);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 24 +l];
    } else if (self.cmd == MSG_CUSTOMER || self.cmd == MSG_CUSTOMER_SUPPORT) {
        CustomerMessage *m = (CustomerMessage*)self.body;
        writeInt64(m.customerAppID, p);
        p += 8;
        writeInt64(m.customerID, p);
        p += 8;
        writeInt64(m.storeID, p);
        p += 8;
        writeInt64(m.sellerID, p);
        p += 8;
        writeInt32(m.timestamp, p);
        p += 4;
        const char *s = [m.content UTF8String];
        size_t l = strlen(s);
        if ((l + 36) >= 32*1024) {
            return nil;
        }
        memcpy(p, s, l);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 36 + l];
    } else if (self.cmd == MSG_ACK) {
        ACKMessage *ack = (ACKMessage*)self.body;
        writeInt32(ack.seq, p);
        p += 4;
        *p++ = (uint8_t)ack.status;
        return [NSData dataWithBytes:buf length:HEAD_SIZE+5];
    } else if (self.cmd == MSG_ENTER_ROOM || self.cmd == MSG_LEAVE_ROOM) {
        NSNumber *n = (NSNumber*)self.body;
        int64_t roomID = [n longLongValue];
        writeInt64(roomID, p);
        p += 8;
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 8];
    } else if (self.cmd == MSG_ROOM_IM || self.cmd == MSG_RT) {
        RoomMessage *rm = (RoomMessage*)self.body;
        writeInt64(rm.sender, p);
        p += 8;
        writeInt64(rm.receiver, p);
        p += 8;
        const char *s = [rm.content UTF8String];
        size_t l = strlen(s);
        if ((l + 28) > 64*1024) {
            return nil;
        }
        memcpy(p, s, l);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 16 +l];
    } else if (self.cmd == MSG_UNREAD_COUNT) {
        NSNumber *u = (NSNumber*)self.body;
        writeInt32([u intValue], p);
        p += 4;
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 4];
    } else if (self.cmd == MSG_SYNC || self.cmd == MSG_SYNC_KEY) {
        NSNumber *u = (NSNumber*)self.body;
        writeInt64([u longLongValue], p);
        p += 8;
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 8];
    } else if (self.cmd == MSG_SYNC_GROUP || self.cmd == MSG_GROUP_SYNC_KEY) {
        GroupSyncKey *s = (GroupSyncKey*)self.body;
        writeInt64(s.groupID, p);
        p += 8;
        writeInt64(s.syncKey, p);
        p += 8;
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 16];
    }
    return nil;
}

-(BOOL)unpack:(NSData*)data {
    const char *p = [data bytes];
    self.seq = readInt32(p);
    p += 4;
    self.cmd = *p;
    self.flag = *(p+2);
    p += 4;
    NSLog(@"seq:%d cmd:%d flag:%d", self.seq, self.cmd, self.flag);
    if (self.cmd == MSG_PONG) {
        return YES;
    } else if (self.cmd == MSG_AUTH_STATUS) {
        int status = readInt32(p);
        self.body = [NSNumber numberWithInt:status];
        return YES;
    } else if (self.cmd == MSG_IM || self.cmd == MSG_GROUP_IM) {
        IMMessage *m = [[IMMessage alloc] init];
        m.sender = readInt64(p);
        p += 8;
        m.receiver = readInt64(p);
        p += 8;
        m.timestamp = readInt32(p);
        p += 4;
        m.msgLocalID = 0;
        p += 4;
        m.content = [[NSString alloc] initWithBytes:p length:data.length-32 encoding:NSUTF8StringEncoding];
        self.body = m;
        return YES;
    } else if (self.cmd == MSG_CUSTOMER || self.cmd == MSG_CUSTOMER_SUPPORT) {
        CustomerMessage *m = [[CustomerMessage alloc] init];
        m.customerAppID = readInt64(p);
        p += 8;
        m.customerID = readInt64(p);
        p += 8;
        m.storeID = readInt64(p);
        p += 8;
        m.sellerID = readInt64(p);
        p += 8;
        m.timestamp = readInt32(p);
        p += 4;
        m.content = [[NSString alloc] initWithBytes:p length:data.length- HEAD_SIZE - 36 encoding:NSUTF8StringEncoding];
        self.body = m;
        return YES;
    } else if (self.cmd == MSG_ACK) {
        ACKMessage *ack = [[ACKMessage alloc] init];
        ack.seq = readInt32(p);
        p += 4;
        ack.status = *p;
        self.body = ack;
        return YES;
    } else if (self.cmd == MSG_GROUP_NOTIFICATION) {
        self.body = [[NSString alloc] initWithBytes:p length:data.length-HEAD_SIZE encoding:NSUTF8StringEncoding];
        return YES;
    } else if (self.cmd == MSG_ROOM_IM || self.cmd == MSG_RT) {
        RoomMessage *rm = [[RoomMessage alloc] init];
        rm.sender = readInt64(p);
        p += 8;
        rm.receiver = readInt64(p);
        p += 8;
        rm.content = [[NSString alloc] initWithBytes:p length:data.length-24 encoding:NSUTF8StringEncoding];
        self.body = rm;
        return YES;
    } else if (self.cmd == MSG_SYSTEM) {
        self.body = [[NSString alloc] initWithBytes:p length:data.length-HEAD_SIZE encoding:NSUTF8StringEncoding];
        return YES;
    } else if (self.cmd == MSG_SYNC_BEGIN ||
               self.cmd == MSG_SYNC_END ||
               self.cmd == MSG_SYNC_NOTIFY) {
        int64_t k = readInt64(p);
        p += 8;
        self.body = [NSNumber numberWithLongLong:k];
        return YES;
    } else if (self.cmd == MSG_SYNC_GROUP_BEGIN ||
               self.cmd == MSG_SYNC_GROUP_END ||
               self.cmd == MSG_SYNC_GROUP_NOTIFY) {
        GroupSyncKey *groupSyncKey = [[GroupSyncKey alloc] init];
        groupSyncKey.groupID = readInt64(p);
        p += 8;
        groupSyncKey.syncKey = readInt64(p);
        p += 8;
        self.body = groupSyncKey;
        return YES;
    } else if (self.cmd == MSG_METADATA) {
        Metadata *meta = [[Metadata alloc] init];
        meta.syncKey = readInt64(p);
        p += 8;
        meta.prevSyncKey = readInt64(p);
        p += 8;
        self.body = meta;
        return YES;
    } else {
        self.body = [NSData dataWithBytes:p length:data.length-8];
        return YES;
    }
}

@end
