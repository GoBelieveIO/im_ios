//
//  IMessageIterator.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "IMessageIterator.h"
#import "ReverseFile.h"
#import "MessageDB.h"

@interface IMessageIterator()
-(id)initWithPath:(NSString*)path;
@end


@implementation IMessageIterator

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


