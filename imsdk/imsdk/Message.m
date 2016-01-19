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
#define VERSION 1

@implementation IMMessage

@end

@implementation CustomerMessage

@end

@implementation RoomMessage

@end

@implementation MessageInputing

@end

@implementation MessagePeerACK

@end


@implementation AuthenticationToken

@end

@implementation LoginPoint

@end

@implementation NatPortMap

@end

@implementation VOIPControl

@end

@implementation Message
-(NSData*)pack {
    char buf[64*1024] = {0};
    char *p = buf;

    writeInt32(self.seq, p);
    p += 4;
    *p++ = (uint8_t)self.cmd;
    *p++ = (uint8_t)VERSION;
    p += 2;
    
    if (self.cmd == MSG_HEARTBEAT || self.cmd == MSG_PING) {
        return [NSData dataWithBytes:buf length:HEAD_SIZE];
    } else if (self.cmd == MSG_AUTH) {
        int64_t uid = [(NSNumber*)self.body longLongValue];
        writeInt64(uid, p);
        return [NSData dataWithBytes:buf length:HEAD_SIZE+8];
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
        writeInt32(m.msgLocalID, p);
        p += 4;
        const char *s = [m.content UTF8String];
        size_t l = strlen(s);
        if ((l + 36) > 64*1024) {
            return nil;
        }
        memcpy(p, s, l);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 24 +l];
    } else if (self.cmd == MSG_CUSTOMER_SERVICE) {
        CustomerMessage *m = (CustomerMessage*)self.body;
        writeInt64(m.customer, p);
        p += 8;
        writeInt64(m.sender, p);
        p += 8;
        writeInt64(m.receiver, p);
        p += 8;
        writeInt32(m.timestamp, p);
        p += 4;
        const char *s = [m.content UTF8String];
        size_t l = strlen(s);
        if ((l + 28) >= 32*1024) {
            return nil;
        }
        memcpy(p, s, l);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 28 + l];
    } else if (self.cmd == MSG_ACK) {
        writeInt32([(NSNumber*)self.body intValue], p);
        return [NSData dataWithBytes:buf length:HEAD_SIZE+4];
    } else if (self.cmd == MSG_INPUTING) {
        MessageInputing *inputing = (MessageInputing*)self.body;
        writeInt64(inputing.sender, p);
        p += 8;
        writeInt64(inputing.receiver, p);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 16];
    } else if (self.cmd == MSG_ENTER_ROOM || self.cmd == MSG_LEAVE_ROOM) {
        NSNumber *n = (NSNumber*)self.body;
        int64_t roomID = [n longLongValue];
        writeInt64(roomID, p);
        p += 8;
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 8];
    } else if (self.cmd == MSG_ROOM_IM) {
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
    } else if (self.cmd == MSG_VOIP_CONTROL) {
        VOIPControl *ctl = (VOIPControl*)self.body;
        writeInt64(ctl.sender, p);
        p += 8;
        writeInt64(ctl.receiver, p);
        p += 8;
        
        writeInt32(ctl.cmd, p);
        p += 4;
        if (ctl.cmd == VOIP_COMMAND_DIAL || ctl.cmd == VOIP_COMMAND_DIAL_VIDEO) {
            writeInt32(ctl.dialCount, p);
            p += 4;
            return [NSData dataWithBytes:buf length:HEAD_SIZE+24];
        } else if (ctl.cmd == VOIP_COMMAND_ACCEPT) {
            NSLog(@"nat map ip:%x", ctl.natMap.ip);
            writeInt32(ctl.natMap.ip, p);
            p += 4;
            writeInt16(ctl.natMap.port, p);
            p += 2;
            return [NSData dataWithBytes:buf length:HEAD_SIZE+26];
        } else if (ctl.cmd == VOIP_COMMAND_CONNECTED) {
            NSLog(@"nat map ip:%x", ctl.natMap.ip);
            writeInt32(ctl.natMap.ip, p);
            p += 4;
            writeInt16(ctl.natMap.port, p);
            p += 2;
            writeInt32(ctl.relayIP, p);
            p += 4;
            return [NSData dataWithBytes:buf length:HEAD_SIZE+30];
        } else {
            return [NSData dataWithBytes:buf length:HEAD_SIZE+20];
        }
    }
    return nil;
}

-(BOOL)unpack:(NSData*)data {
    const char *p = [data bytes];
    self.seq = readInt32(p);
    p += 4;
    self.cmd = *p;
    p += 4;
    NSLog(@"seq:%d cmd:%d", self.seq, self.cmd);
    if (self.cmd == MSG_RST || self.cmd == MSG_PONG) {
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
        m.msgLocalID = readInt32(p);
        p += 4;
        m.content = [[NSString alloc] initWithBytes:p length:data.length-32 encoding:NSUTF8StringEncoding];
        self.body = m;
        return YES;
    } else if (self.cmd == MSG_CUSTOMER_SERVICE) {
        CustomerMessage *m = [[CustomerMessage alloc] init];
        m.customer = readInt64(p);
        p += 8;
        m.sender = readInt64(p);
        p += 8;
        m.receiver = readInt64(p);
        p += 8;
        m.timestamp = readInt32(p);
        p += 4;
        m.content = [[NSString alloc] initWithBytes:p length:data.length-36 encoding:NSUTF8StringEncoding];
        self.body = m;
        return YES;
    } else if (self.cmd == MSG_ACK) {
        int seq = readInt32(p);
        self.body = [NSNumber numberWithInt:seq];
        return YES;
    } else if (self.cmd == MSG_PEER_ACK) {
        MessagePeerACK *ack = [[MessagePeerACK alloc] init];
        ack.sender = readInt64(p);
        p += 8;
        ack.receiver = readInt64(p);
        p += 8;
        ack.msgLocalID = readInt32(p);
        self.body = ack;
        return YES;
    } else if (self.cmd == MSG_INPUTING) {
        MessageInputing *inputing = [[MessageInputing alloc] init];
        inputing.sender = readInt64(p);
        p += 8;
        inputing.receiver = readInt64(p);
        p += 8;
        self.body = inputing;
        return YES;
    } else if (self.cmd == MSG_GROUP_NOTIFICATION) {
        self.body = [[NSString alloc] initWithBytes:p length:data.length-HEAD_SIZE encoding:NSUTF8StringEncoding];
        return YES;
    } else if (self.cmd == MSG_LOGIN_POINT) {
        LoginPoint *lp = [[LoginPoint alloc] init];
        lp.upTimestamp = readInt32(p);
        p += 4;
        lp.platformID = *p;
        p++;
        lp.deviceID = [[NSString alloc] initWithBytes:p length:data.length-13 encoding:NSUTF8StringEncoding];
        self.body = lp;
        return YES;
    } else if (self.cmd == MSG_ROOM_IM) {
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
    } else if (self.cmd == MSG_VOIP_CONTROL) {
        VOIPControl *ctl = [[VOIPControl alloc] init];
        ctl.sender = readInt64(p);
        p += 8;
        ctl.receiver = readInt64(p);
        p += 8;
        ctl.cmd = readInt32(p);
        p += 4;
        if (ctl.cmd == VOIP_COMMAND_DIAL || ctl.cmd == VOIP_COMMAND_DIAL_VIDEO) {
            ctl.dialCount = readInt32(p);
        } else if (ctl.cmd == VOIP_COMMAND_ACCEPT) {
            if (data.length >= HEAD_SIZE + 26) {
                ctl.natMap = [[NatPortMap alloc] init];
                ctl.natMap.ip = readInt32(p);
                p += 4;
                ctl.natMap.port = readInt16(p);
                p += 2;
            }
        } else if (ctl.cmd == VOIP_COMMAND_CONNECTED) {
            if (data.length >= HEAD_SIZE + 26) {
                ctl.natMap = [[NatPortMap alloc] init];
                ctl.natMap.ip = readInt32(p);
                p += 4;
                ctl.natMap.port = readInt16(p);
                p += 2;
            }
            if (data.length >= HEAD_SIZE + 30) {
                ctl.relayIP = readInt32(p);
                p += 4;
            }
        }
        self.body = ctl;
        return YES;
    } else {
        self.body = [NSData dataWithBytes:p length:data.length-8];
        return YES;
    }
    return NO;
}

@end
