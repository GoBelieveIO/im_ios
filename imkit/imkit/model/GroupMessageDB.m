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
    return [[ConversationIterator alloc] initWithPath:path type:CONVERSATION_GROUP];
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

