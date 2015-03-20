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
#import "ReverseFile.h"

@interface GroupMessageIterator()
@property(nonatomic)ReverseFile *file;
-(id)initWithPath:(NSString*)path;
@end


@implementation GroupMessageIterator

-(id)initWithPath:(NSString*)path {
    self = [super init];
    if (self) {
        [self openFile:path position:-1];
    }
    return self;
}

-(id)initWithPath:(NSString*)path position:(int)position {
    self = [super init];
    if (self) {
        [self openFile:path position:position];
    }
    return self;
}

-(void)openFile:(NSString*)path position:(int)position {
    
    int fd = open([path UTF8String], O_RDONLY);
    if (fd == -1) {
        NSLog(@"open file fail:%@", path);
        return;
    }
    if (![MessageDB checkHeader:fd]) {
        close(fd);
        return;
    }
    if (position == -1) {
        position = (int)lseek(fd, 0, SEEK_END);
    }
    self.file = [[ReverseFile alloc] initWithFD:fd];
    self.file.pos = position;
}

-(IMessage*)nextMessage {
    if (!self.file) return nil;
    return [MessageDB readMessage:self.file];
}

-(IMessage*)next {
    while (YES) {
        IMessage *msg = [self nextMessage];
        if (msg.flags & MESSAGE_FLAG_DELETE) {
            continue;
        }
        return msg;
    }
}
@end


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

-(id<IMessageIterator>)newMessageIterator:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    return [[GroupMessageIterator alloc] initWithPath:path];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)gid last:(int)lastMsgID {
    NSString *path = [self getGroupPath:gid];
    return [[GroupMessageIterator alloc] initWithPath:path position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    return [[GroupConversationIterator alloc] init];
}


-(NSString*)getMessagePath {
    NSString *s = [MessageDB getDocumentPath];
    return [NSString stringWithFormat:@"%@/group", s];
}

-(NSString*)getGroupPath:(int64_t)gid {
    NSString *s = [MessageDB getDocumentPath];
    return [NSString stringWithFormat:@"%@/group/g_%lld", s, gid];
}

-(BOOL)clearConversation:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    int r = unlink([path UTF8String]);
    if (r == -1) {
        NSLog(@"unlink error:%d", errno);
        return (errno == ENOENT);
    }
    return YES;
}

-(BOOL)insertMessage:(IMessage*)msg {
    NSString *path = [self getGroupPath:msg.receiver];
    return [MessageDB insertIMessage:msg path:path];
}

-(BOOL)removeMessage:(int)msgLocalID gid:(int64_t)gid{
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_DELETE];
}

-(BOOL)acknowledgeMessage:(int)msgLocalID gid:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_ACK];
}

-(BOOL)markMessageFailure:(int)msgLocalID gid:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID gid:(int64_t)gid{
    NSString *path = [self getGroupPath:gid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_LISTENED];
}

@end


@interface GroupConversationIterator()
@property(nonatomic, assign)DIR *dirp;
@end

@implementation GroupConversationIterator
-(id)init {
    self = [super init];
    if (self) {
        [self openDir];
    }
    return self;
}

-(void)dealloc {
    if (self.dirp) {
        closedir(self.dirp);
    }
}
-(void)openDir {
    NSString *path = [[GroupMessageDB instance] getMessagePath];
    DIR *dirp = opendir([path UTF8String]);
    if (dirp == NULL) {
        NSLog(@"readdir error:%d", errno);
        return;
    }
    self.dirp = dirp;
}

-(IMessage*)getLastGroupMessage:(int64_t)gid {
    id<IMessageIterator> iter = [[GroupMessageDB instance] newMessageIterator:gid];
    IMessage *msg;
    msg = [iter next];
    return msg;
}

-(Conversation*)next {
    if (!self.dirp) return nil;
    
    struct dirent *dp;
    while ((dp = readdir(self.dirp)) != NULL) {
        NSString *name = [[NSString alloc] initWithBytes:dp->d_name length:dp->d_namlen encoding:NSUTF8StringEncoding];
        NSLog(@"type:%d name:%@", dp->d_type, name);
        if (dp->d_type == DT_REG) {
            if ([name hasPrefix:@"p_"]) {
 
            } else if ([name hasPrefix:@"g_"]) {
                Conversation *c = [[Conversation alloc] init];
                int64_t gid = [[name substringFromIndex:2] longLongValue];
                c.cid = gid;
                c.type = CONVERSATION_GROUP;
                c.message = [self getLastGroupMessage:gid];
                return c;
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return nil;
}
@end


