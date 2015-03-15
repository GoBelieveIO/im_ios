//
//  IM.m
//  im
//
//  Created by houxh on 14-6-21.
//  Copyright (c) 2014年 potato. All rights reserved.
//

#import "Message.h"
#import "util.h"

#define HEAD_SIZE 8

@implementation IMMessage

@end

@implementation MessageInputing

@end
@implementation MessageOnlineState

@end
@implementation MessagePeerACK

@end

@implementation MessageSubsribe

@end



@implementation AuthenticationToken

@end

@implementation Message
-(NSData*)pack {
    char buf[64*1024] = {0};
    char *p = buf;

    writeInt32(self.seq, p);
    p += 4;
    *p = (uint8_t)self.cmd;
    p += 4;
    
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
    }  else if (self.cmd == MSG_IM) {
        IMMessage *m = (IMMessage*)self.body;
        writeInt64(m.sender, p);
        p += 8;
        writeInt64(m.receiver, p);
        p += 8;
        writeInt32(m.msgLocalID, p);
        p += 4;
        const char *s = [m.content UTF8String];
        int l = strlen(s);
        if ((l + 28) > 64*1024) {
            return nil;
        }
        memcpy(p, s, l);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 20 +l];
    } else if (self.cmd == MSG_ACK) {
        writeInt32([(NSNumber*)self.body intValue], p);
        return [NSData dataWithBytes:buf length:HEAD_SIZE+4];
    } else if (self.cmd == MSG_SUBSCRIBE_ONLINE_STATE) {
        MessageSubsribe *sub = (MessageSubsribe*)self.body;
        writeInt32([sub.uids count], p);
        p += 4;
        for (NSNumber *n in sub.uids) {
            writeInt64([n longLongValue], p);
            p += 8;
        }
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 4 + [sub.uids count]*8];
    } else if (self.cmd == MSG_INPUTING) {
        MessageInputing *inputing = (MessageInputing*)self.body;
        writeInt64(inputing.sender, p);
        p += 8;
        writeInt64(inputing.receiver, p);
        return [NSData dataWithBytes:buf length:HEAD_SIZE + 16];
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
    } else if (self.cmd == MSG_IM) {
        IMMessage *m = [[IMMessage alloc] init];
        m.sender = readInt64(p);
        p += 8;
        m.receiver = readInt64(p);
        p += 8;
        m.msgLocalID = readInt32(p);
        p += 4;
        m.content = [[NSString alloc] initWithBytes:p length:data.length-28 encoding:NSUTF8StringEncoding];
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
    } else if (self.cmd == MSG_ONLINE_STATE) {
        MessageOnlineState *state = [[MessageOnlineState alloc] init];
        state.sender = readInt64(p);
        p += 8;
        state.online = readInt32(p);
        self.body = state;
        return YES;
    } else {
        self.body = [NSData dataWithBytes:p length:data.length-8];
        return YES;
    }
    return NO;
}

@end
