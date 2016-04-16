/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupMessageDB.h"
#import "MessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#import "ReverseFile.h"


@interface GroupConversationIterator : ConversationIterator

@end

@implementation GroupConversationIterator

-(IMessage*)getLastMessage:(NSString*)path {
    IMessageIterator *iter = [[IMessageIterator alloc] initWithPath:path];
    IMessage *msg;
    //返回第一条不是附件的消息
    while (YES) {
        msg = [iter next];
        if (msg == nil) {
            break;
        }
        if (msg.type != MESSAGE_ATTACHMENT) {
            break;
        }
    }
    
    return msg;
}

-(Conversation*)next {
    if (!self.dirp) return nil;
    
    struct dirent *dp;
    while ((dp = readdir(self.dirp)) != NULL) {
        NSString *name = [[NSString alloc] initWithBytes:dp->d_name length:dp->d_namlen encoding:NSUTF8StringEncoding];
        NSLog(@"type:%d name:%@", dp->d_type, name);
        if (dp->d_type == DT_REG) {
            if ([name hasPrefix:@"g_"]) {
                Conversation *c = [[Conversation alloc] init];
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                c.cid = uid;
                c.type = CONVERSATION_GROUP;
                NSString *path = [NSString stringWithFormat:@"%@/%@", self.path, name];
                c.message = [self getLastMessage:path];
                return c;
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return nil;
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

    }
    return self;
}


+(BOOL)mkdir:(NSString*)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *err;
    BOOL r = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
    
    if (!r) {
        NSLog(@"mkdir err:%@", err);
    }
    return r;
}



-(void)setDbPath:(NSString *)dbPath {
    _dbPath = [dbPath copy];
    
    [[self class] mkdir:dbPath];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)gid {
    NSString *path = [self getGroupPath:gid];
    return [[IMessageIterator alloc] initWithPath:path];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)gid last:(int)lastMsgID {
    NSString *path = [self getGroupPath:gid];
    return [[IMessageIterator alloc] initWithPath:path position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    NSString *path = [self getMessagePath];
    return [[GroupConversationIterator alloc] initWithPath:path];
}


-(NSString*)getMessagePath {
    return self.dbPath;
}

-(NSString*)getGroupPath:(int64_t)gid {
    NSString *s = self.dbPath;
    return [NSString stringWithFormat:@"%@/g_%lld", s, gid];
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

