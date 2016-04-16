//
//  ConversationIterator.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"
#include <dirent.h>

@protocol ConversationIterator
-(Conversation*)next;
@end

@interface ConversationIterator : NSObject<ConversationIterator>
@property(nonatomic, assign)DIR *dirp;
@property(nonatomic, copy) NSString *path;

-(id)initWithPath:(NSString*)path;

@end
