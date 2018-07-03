/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "FilePeerMessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#include <sys/stat.h>
#import "util.h"
#import "ReverseFile.h"
#import "ConversationIterator.h"

@interface FilePeerConversationIterator : FileConversationIterator

@end

@implementation FilePeerConversationIterator



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

-(IMessage*)next {
    if (!self.dirp) return nil;
    struct dirent *dp;
    while ((dp = readdir(self.dirp)) != NULL) {
        NSString *name = [[NSString alloc] initWithBytes:dp->d_name length:dp->d_namlen encoding:NSUTF8StringEncoding];
        NSLog(@"type:%d name:%@", dp->d_type, name);
        if (dp->d_type == DT_REG) {
            if ([name hasPrefix:@"p_"]) {
                NSString *path = [NSString stringWithFormat:@"%@/%@", self.path, name];
                IMessage *message = [self getLastMessage:path];
                return message;
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return nil;
}

@end


@implementation FilePeerMessageDB
+(FilePeerMessageDB*)instance {
    static FilePeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[FilePeerMessageDB alloc] init];
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


//4字节magic + 4字节消息长度 + 消息主体 + 4字节消息长度 + 4字节magic
//消息主体：4字节标志 ＋ 4字节时间戳 + 8字节发送者id + 8字节接受者id ＋ 消息内容
+(BOOL)writeMessage:(IMessage*)msg fd:(int)fd {
    char buf[64*1024];
    char *p = buf;
    
    const char *raw = [msg.rawContent UTF8String];
    size_t len = strlen(raw) + 8 + 8 + 4 + 4;
    
    if (4 + 4 + len + 4 + 4 > 64*1024) return NO;
    
    writeInt32(IMMAGIC, p);
    p += 4;
    writeInt32((int32_t)len, p);
    p += 4;
    writeInt32(msg.flags, p);
    p += 4;
    writeInt32(msg.timestamp, p);
    p += 4;
    writeInt64(msg.sender, p);
    p += 8;
    writeInt64(msg.receiver, p);
    p += 8;
    memcpy(p, raw, strlen(raw));
    p += strlen(raw);
    writeInt32((int32_t)len, p);
    p += 4;
    writeInt32(IMMAGIC, p);
    p += 4;
    long size = p - buf;
    ssize_t n = write(fd, buf, size);
    if (n != size) return NO;
    return YES;
}


+(IMessage*)readMessage:(ReverseFile*)file {
    char buf[64*1024];
    
    int n = [file read:buf length:8];
    if (n != 8) {
        return nil;
    }
    int len = readInt32(buf);
    int magic = readInt32(buf + 4);
    if (magic != IMMAGIC) {
        return nil;
    }
    if (len + 8 > 64*1024) {
        return nil;
    }
    
    n = [file read:buf length:len+8];
    if (n != len + 8) {
        return nil;
    }
    IMessage *msg = [[IMessage alloc] init];
    msg.msgLocalID = file.pos;
    char *p = buf + 8;
    msg.flags = readInt32(p);
    p += 4;
    msg.timestamp = readInt32(p);
    p += 4;
    msg.sender = readInt64(p);
    p += 8;
    msg.receiver = readInt64(p);
    p += 8;
    msg.rawContent = [[NSString alloc] initWithBytes:p length:len - 24 encoding:NSUTF8StringEncoding];
    return msg;
}

-(id)init {
    self = [super init];
    if (self) {
    }
    return self;
}


-(void)setDbPath:(NSString *)dbPath {
    _dbPath = [dbPath copy];
    
    [[self class] mkdir:dbPath];
}

-(NSString*)getMessagePath {
    return self.dbPath;
}
-(NSString*)getPeerPath:(int64_t)uid {
    NSString *s = self.dbPath;
    return [NSString stringWithFormat:@"%@/p_%lld", s, uid];
}


-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [[self class] insertIMessage:msg path:path];
}

-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [[self class] addFlag:msgLocalID path:path flag:MESSAGE_FLAG_DELETE];
}

-(BOOL)clearConversation:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [[self class] clearMessages:path];
}

-(BOOL)clear {
    NSString *path = [[FilePeerMessageDB instance] getMessagePath];
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
            if ([name hasPrefix:@"p_"]) {
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                NSString *path = [self getPeerPath:uid];
                [[self class] clearMessages:path];
            } else {
                NSLog(@"skip file:%@", name);
            }
        }
    }
    return YES;
}

-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [[self class] addFlag:msgLocalID path:path flag:MESSAGE_FLAG_ACK];
}


-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [[self class] addFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
}

-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)uid{
    NSString *path = [self getPeerPath:uid];
    return [[self class] addFlag:msgLocalID path:path flag:MESSAGE_FLAG_LISTENED];
}

-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    NSString *path = [self getPeerPath:uid];
    return [[self class] eraseFlag:msgLocalID path:path flag:MESSAGE_FLAG_FAILURE];
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
    return [[FilePeerConversationIterator alloc] initWithPath:path];
}

@end


