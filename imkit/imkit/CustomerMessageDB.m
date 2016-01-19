//
//  CustomerMessageDB.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageDB.h"
#import "MessageDB.h"
#include <sys/stat.h>
#include <dirent.h>

@implementation CustomerMessageDB
+(CustomerMessageDB*)instance {
    static CustomerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[CustomerMessageDB alloc] init];
        }
    });
    return m;
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

-(id)init {
    self = [super init];
    if (self) {
        self.aggregationMode = YES;
    }
    return self;
}

-(NSString*)getMessagePath {
    return self.dbPath;
}

-(NSString*)getPeerPath:(int64_t)uid {
    NSString *s = self.dbPath;
    if (self.aggregationMode) {
        return [NSString stringWithFormat:@"%@/c_%lld", s, 0LL];
    } else {
        return [NSString stringWithFormat:@"%@/c_%lld", s, uid];
    }
}


-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [MessageDB insertIMessage:msg path:path];
}

-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_DELETE];
}

-(BOOL)clearConversation:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB clearMessages:path];
}

-(BOOL)clear {
    NSString *path = [self getMessagePath];
    DIR *dirp = opendir([path UTF8String]);
    if (dirp == NULL) {
        NSLog(@"readdir error:%d", errno);
        return NO;
    }
    
    struct dirent *dp;
    while ((dp = readdir(dirp)) != NULL) {
        NSString *name = [[NSString alloc] initWithBytes:dp->d_name length:dp->d_namlen encoding:NSUTF8StringEncoding];
        NSLog(@"type:%d name:%@", dp->d_type, name);
        if (dp->d_type == DT_REG) {
            if ([name hasPrefix:@"c_"]) {
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                NSString *path = [self getPeerPath:uid];
                [MessageDB clearMessages:path];
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return YES;
}

-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_ACK];
}


-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [MessageDB addFlag:msgLocalID path:path flag:MESSAGE_FLAG_LISTENED];
}

-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [MessageDB eraseFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [[IMessageIterator alloc] initWithPath:path];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID {
    NSString *path = [self getPeerPath:uid];
    return [[IMessageIterator alloc] initWithPath:path position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    NSString *path = [self getMessagePath];
    return [[ConversationIterator alloc] initWithPath:path type:CONVERSATION_CUSTOMER_SERVICE];
}

@end
