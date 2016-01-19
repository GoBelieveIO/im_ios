//
//  CustomerMessageHandler.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageHandler.h"
#import "MessageDB.h"
#import <imsdk/Message.h>
#import "CustomerMessageDB.h"

@implementation CustomerMessageHandler
+(CustomerMessageHandler*)instance {
    static CustomerMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[CustomerMessageHandler alloc] init];
        }
    });
    return m;
}

-(BOOL)handleMessage:(CustomerMessage*)msg {
    IMMessage *im = msg;
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.rawContent = im.content;
    m.timestamp = msg.timestamp;
    BOOL r = [[CustomerMessageDB instance] insertMessage:m uid:msg.customer];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(int)msgLocalID uid:(int64_t)uid {
    return [[CustomerMessageDB instance] acknowledgeMessage:msgLocalID uid:uid];
}

-(BOOL)handleMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    CustomerMessageDB *db = [CustomerMessageDB instance];
    return [db markMessageFailure:msgLocalID uid:uid];
}

@end
