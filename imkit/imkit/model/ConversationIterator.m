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


@interface ConversationIterator()

@end

@implementation ConversationIterator
-(id)initWithPath:(NSString*)path {
    self = [super init];
    if (self) {
        self.path = path;
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

-(Conversation*)next {
    return nil;
}
@end

