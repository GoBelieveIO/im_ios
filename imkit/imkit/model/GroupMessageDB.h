//
//  GroupMessageDB.h
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IMessage.h"
#import "MessageDB.h"

@interface GroupConversationIterator : NSObject<ConversationIterator>

@end

@interface GroupMessageIterator : NSObject<IMessageIterator>

@end

@interface GroupMessageDB : NSObject
+(GroupMessageDB*)instance;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(BOOL)insertMessage:(IMessage*)msg;
-(BOOL)removeMessage:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)clearConversation:(int64_t)gid;
-(BOOL)acknowledgeMessage:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)markMessageFailure:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)markMesageListened:(int)msgLocalID gid:(int64_t)gid;
@end