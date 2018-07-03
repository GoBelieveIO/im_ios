/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "FileMessageDB.h"
#include <sys/stat.h>
#include <dirent.h>
#import "util.h"
#import "ReverseFile.h"




@implementation FileMessageDB

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


+(BOOL)writeMessage:(IMessage*)msg fd:(int)fd {
    NSAssert(NO, @"not implemented");
    return NO;
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
    if (![FileMessageDB checkHeader:fd]) {
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
    msg.rawContent = [[NSString alloc] initWithBytes:p length:len - 24 encoding:NSUTF8StringEncoding];
    return msg;
}

@end
