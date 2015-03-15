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

-(id<IMessageIterator>)newPeerMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newPeerMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(BOOL)insertPeerMessage:(IMessage*)msg uid:(int64_t)uid;
-(BOOL)removePeerMessage:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)clearConversation:(int64_t)uid;
-(BOOL)clear;
-(BOOL)acknowledgePeerMessage:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)acknowledgePeerMessageFromRemote:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)markPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)markPeerMesageListened:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)erasePeerMessageFailure:(int)msgLocalID uid:(int64_t)uid;
@end
