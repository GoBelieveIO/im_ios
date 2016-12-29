//
//  CustomerMessageDB.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "FileCustomerMessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#import "util.h"
#import "ReverseFile.h"

@interface FileCustomerMessageIterator : IMessageIterator

@end

@implementation FileCustomerMessageIterator


-(IMessage*)nextMessage {
    if (!self.file) return nil;
    return [FileCustomerMessageDB readMessage:self.file];
}

@end

@interface FileCustomerConversationIterator : FileConversationIterator

@end

@implementation FileCustomerConversationIterator

-(IMessage*)getLastMessage:(NSString*)path {
    FileCustomerMessageIterator *iter = [[FileCustomerMessageIterator alloc] initWithPath:path];
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
            if ([name hasPrefix:@"c_"]) {
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

@implementation FileCustomerMessageDB
+(FileCustomerMessageDB*)instance {
    static FileCustomerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[FileCustomerMessageDB alloc] init];
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
//消息主体：4字节标志 ＋ 4字节时间戳 ＋ 8字节客户appid ＋
//8字节客户id ＋ 8字节商店id ＋ 8字节客服id ＋ 1字节消息是否来自客服＋ 消息内容
+(BOOL)writeMessage:(IMessage*)m fd:(int)fd {
    ICustomerMessage *msg = (ICustomerMessage*)m;
    char buf[64*1024];
    char *p = buf;
    
    const char *raw = [msg.rawContent UTF8String];
    size_t len = strlen(raw) + 4 + 4 + 8 + 8 + 8 + 8 + 1;
    
    if (4 + 4 + len + 4 + 4 > 64*1024) return NO;
    
    writeInt32(IMMAGIC, p);
    p += 4;
    writeInt32((int32_t)len, p);
    p += 4;
    
    writeInt32(msg.flags, p);
    p += 4;
    writeInt32(msg.timestamp, p);
    p += 4;
    
    writeInt64(msg.customerAppID, p);
    p += 8;
    writeInt64(msg.customerID, p);
    p += 8;
    writeInt64(msg.storeID, p);
    p += 8;
    writeInt64(msg.sellerID, p);
    p += 8;
    
    *p = msg.isSupport ? 1 : 0;
    p++;
    
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
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.msgLocalID = file.pos;
    char *p = buf + 8;
    msg.flags = readInt32(p);
    p += 4;
    msg.timestamp = readInt32(p);
    p += 4;
    
    msg.customerAppID = readInt64(p);
    p += 8;
    msg.customerID = readInt64(p);
    p += 8;
    msg.storeID = readInt64(p);
    p += 8;
    msg.sellerID = readInt64(p);
    p += 8;
    
    msg.isSupport = *p;
    p++;
    
    if (msg.isSupport) {
        msg.sender = msg.storeID;
        msg.receiver = msg.customerID;
    } else {
        msg.sender = msg.customerID;
        msg.receiver = msg.storeID;
    }

    msg.rawContent = [[NSString alloc] initWithBytes:p length:len - 41 encoding:NSUTF8StringEncoding];
    return msg;
}


-(void)setDbPath:(NSString *)dbPath {
    _dbPath = [dbPath copy];
    
    [[self class] mkdir:dbPath];
}

-(id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

-(NSString*)getMessagePath {
    return self.dbPath;
}

-(NSString*)getPeerPath:(int64_t)uid {
    NSString *s = self.dbPath;
    return [NSString stringWithFormat:@"%@/c_%lld", s, uid];
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
    return [[FileCustomerMessageIterator alloc] initWithPath:path];
}

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID {
    NSString *path = [self getPeerPath:uid];
    return [[FileCustomerMessageIterator alloc] initWithPath:path position:lastMsgID];
}

-(id<ConversationIterator>)newConversationIterator {
    NSString *path = [self getMessagePath];
    return [[FileCustomerMessageIterator alloc] initWithPath:path];
}

@end
