//
//  ConversationIterator.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "ConversationIterator.h"
#import "IMessageIterator.h"
#include <sys/stat.h>
#include <dirent.h>

@interface ConversationIterator()
@property(nonatomic, assign)DIR *dirp;
@property(nonatomic) int type;
@property(nonatomic, copy) NSString *path;
@end

@implementation ConversationIterator
-(id)initWithPath:(NSString*)path type:(int)type {
    self = [super init];
    if (self) {
        self.path = path;
        self.type = type;
        [self openDir:path];
    }
    return self;
}

-(void)dealloc {
    if (self.dirp) {
        closedir(self.dirp);
    }
}
-(void)openDir:(NSString*)path {
    DIR *dirp = opendir([path UTF8String]);
    if (dirp == NULL) {
        NSLog(@"readdir error:%d", errno);
        return;
    }
    self.dirp = dirp;
}

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
            if (self.type == CONVERSATION_PEER && [name hasPrefix:@"p_"]) {
                Conversation *c = [[Conversation alloc] init];
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                c.cid = uid;
                c.type = self.type;
                NSString *path = [NSString stringWithFormat:@"%@/%@", self.path, name];
                c.message = [self getLastMessage:path];
                return c;
            } else if (self.type == CONVERSATION_GROUP && [name hasPrefix:@"g_"]) {
                Conversation *c = [[Conversation alloc] init];
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                c.cid = uid;
                c.type = self.type;
                NSString *path = [NSString stringWithFormat:@"%@/%@", self.path, name];
                c.message = [self getLastMessage:path];
                return c;
            } else if (self.type == CONVERSATION_CUSTOMER_SERVICE && [name hasPrefix:@"c_"]) {
                Conversation *c = [[Conversation alloc] init];
                int64_t uid = [[name substringFromIndex:2] longLongValue];
                c.cid = uid;
                c.type = self.type;
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

