//
//  GroupMessageHandler.m
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "GroupMessageHandler.h"
#import "IMessage.h"
#import <imsdk/IMService.h>
#import "GroupMessageDB.h"

@implementation GroupMessageHandler
+(GroupMessageHandler*)instance {
    static GroupMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[GroupMessageHandler alloc] init];
        }
    });
    return m;
}

-(BOOL)handleMessage:(IMMessage*)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = time(NULL);
    BOOL r = [[GroupMessageDB instance] insertGroupMessage:m];
    if (r) {
        im.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(int)msgLocalID uid:(int64_t)uid {
    return [[GroupMessageDB instance] acknowledgeGroupMessage:msgLocalID gid:uid];
}
-(BOOL)handleMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    return [[GroupMessageDB instance] markGroupMessageFailure:msgLocalID gid:uid];
}
@end
