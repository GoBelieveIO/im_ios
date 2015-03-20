//
//  PeerMessageDB.h
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"
#import "MessageDB.h"

@interface PeerConversationIterator : NSObject<ConversationIterator>

@end

@interface PeerMessageIterator : NSObject<IMessageIterator>

@end

@interface PeerMessageDB : NSObject

+(PeerMessageDB*)instance;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid;
-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)clearConversation:(int64_t)uid;
-(BOOL)clear;
-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)acknowledgeMessageFromRemote:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)uid;
@end
