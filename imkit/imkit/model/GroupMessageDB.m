//
//  GroupMessageDB.m
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "GroupMessageDB.h"
#import "MessageDB.h"
#include <sys/stat.h>
#include <dirent.h>

@implementation GroupMessageDB

+(GroupMessageDB*)instance {
    static GroupMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[GroupMessageDB alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        NSString *path = [self getMessagePath];
        int r = mkdir([path UTF8String], 0755);
        if (r == -1 && errno != EEXIST) {
            NSLog(@"mkdir error:%d", errno);
        }
    }
    return self;
}
-(NSString*)getMessagePath {
    NSString *s = [MessageDB getDocumentPath];
    return [NSString stringWithFormat:@"%@/group", s];
}

-(NSString*)getGroupPath:(int64_t)gid {
    NSString *s = [MessageDB getDocumentPath];
    return [NSString stringWithFormat:@"%@/group/g_%lld", s, gid];
}

-(BOOL)clearGroupConversation:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    int r = unlink([path UTF8String]);
    if (r == -1) {
        NSLog(@"unlink error:%d", errno);
        return (errno == ENOENT);
    }
    return YES;
}

-(BOOL)insertGroupMessage:(IMessage*)msg {
    NSString *path = [self getGroupPath:msg.receiver];
    return [MessageDB insertIMessage:msg path:path];
}

-(BOOL)removeGroupMessage:(int)msgLocalID gid:(int64_t)gid{
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_DELETE];
}

-(BOOL)acknowledgeGroupMessage:(int)msgLocalID gid:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markGroupMessageFailure:(int)msgLocalID gid:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
}

@end
