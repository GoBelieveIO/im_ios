//
//  Model.m
//  im
//
//  Created by houxh on 14-6-28.
//  Copyright (c) 2014年 potato. All rights reserved.
//

#import "MessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#import <imsdk/util.h>
#import "ReverseFile.h"

#define HEADER_SIZE 32
#define IMMAGIC 0x494d494d
#define IMVERSION (1<<16) //1.0


static NSString *dbPath = nil;
@implementation MessageDB

+(void)setDBPath:(NSString *)dir {
    dbPath = dir;
}

+(NSString*)getDBPath {
    return dbPath;
}

+(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


//4字节magic ＋ 4字节version ＋ 24字节padding
+(BOOL)writeHeader:(int)fd {
    char buf[HEADER_SIZE] = {0};
    writeInt32(IMMAGIC, buf);
    writeInt32(IMVERSION, buf + 4);
    ssize_t n = write(fd, buf, HEADER_SIZE);
    if (n != HEADER_SIZE) return NO;
    return YES;
}

+(BOOL)checkHeader:(int)fd {
    char header[HEADER_SIZE];
    ssize_t n = read(fd, header, HEADER_SIZE);
    if (n != HEADER_SIZE) {
        return NO;
    }
    int32_t magic = readInt32(header);
    int32_t version = readInt32(header + 4);
    if (magic != IMMAGIC || version != IMVERSION) {
        NSLog(@"file damage");
        return NO;
    }
    return YES;
}

//4字节magic + 4字节消息长度 + 消息主体 + 4字节消息长度 + 4字节magic
//消息主体：4字节标志 ＋ 4字节时间戳 + 8字节发送者id + 8字节接受者id ＋ 消息内容
+(BOOL)writeMessage:(IMessage*)msg fd:(int)fd {
    char buf[64*1024];
    char *p = buf;
    
    const char *raw = [msg.content.raw UTF8String];
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

+(BOOL)insertIMessage:(IMessage*)msg path:(NSString*)path {
    int fd = open([path UTF8String], O_WRONLY|O_APPEND|O_CREAT, 0644);
    if (fd == -1) {
        NSLog(@"open file fail:%@", path);
        return NO;
    }

    off_t size = lseek(fd, 0, SEEK_END);
    if (size < HEADER_SIZE && size > 0) {
        ftruncate(fd, 0);
        size = 0;
    }
    
    if (size == 0) {
        [self writeHeader:fd];
    }
    off_t seq = lseek(fd, 0, SEEK_CUR);
    msg.msgLocalID = (int)seq;
    [self writeMessage:msg fd:fd];
    close(fd);
    return YES;
}

+(BOOL)addFlag:(int)msgLocalID path:(NSString*)path flag:(int)flag {
    int fd = open([path UTF8String], O_RDWR);
    if (fd == -1) {
        NSLog(@"open file fail:%@", path);
        return NO;
    }
    char buf[8+4];
    ssize_t n = pread(fd, buf, 12, msgLocalID);
    if (n != 12) {
        return NO;
    }
    int magic = readInt32(buf);
    if (magic != IMMAGIC) {
        NSLog(@"invalid message local id:%d", msgLocalID);
        return NO;
    }
    int flags = readInt32(buf + 8);
    flags |= flag;
    writeInt32(flags, buf);
    n = pwrite(fd, buf, 4, msgLocalID + 8);
    if (n != 4) {
        NSLog(@"write error:%d", errno);
        return NO;
    }
    return YES;
}
+(BOOL)eraseFlag:(int)msgLocalID path:(NSString*)path flag:(int)flag {
    int fd = open([path UTF8String], O_RDWR);
    if (fd == -1) {
        NSLog(@"open file fail:%@", path);
        return NO;
    }
    char buf[8+4];
    ssize_t n = pread(fd, buf, 12, msgLocalID);
    if (n != 12) {
        return NO;
    }
    int magic = readInt32(buf);
    if (magic != IMMAGIC) {
        NSLog(@"invalid message local id:%d", msgLocalID);
        return NO;
    }
    int flags = readInt32(buf + 8);
    flags &= ~flag;
    writeInt32(flags, buf);
    n = pwrite(fd, buf, 4, msgLocalID + 8);
    if (n != 4) {
        NSLog(@"write error:%d", errno);
        return NO;
    }
    return YES;
}

+(BOOL)clearMessages:(NSString*)path {
    int fd = open([path UTF8String], O_WRONLY);
    if (fd == -1) {
        NSLog(@"open file fail:%@", path);
        return NO;
    }
    if (![MessageDB checkHeader:fd]) {
        close(fd);
        unlink([path UTF8String]);
        return YES;
    }
    ftruncate(fd, HEADER_SIZE);
    close(fd);
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
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = [[NSString alloc] initWithBytes:p length:len - 24 encoding:NSUTF8StringEncoding];
    msg.content = content;
    return msg;
}

@end
