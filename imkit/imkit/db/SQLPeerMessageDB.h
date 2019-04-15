/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import "IMessage.h"
#import "IMessageIterator.h"

#import <fmdb/FMDB.h>

@interface SQLPeerMessageDB : NSObject



@property(nonatomic, strong) FMDatabase *db;
@property(nonatomic, assign) BOOL secret;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
//下拉刷新
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid last:(int)lastMsgID;

-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)uid messageID:(int)messageID;

//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)uid messageID:(int)messageID;


//获取最新的消息
-(IMessage*)getLastMessage:(int64_t)uid;
-(IMessage*)getMessage:(int64_t)msgID;
-(int)getMessageId:(NSString*)uuid;
-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid;
-(BOOL)removeMessage:(int)msgLocalID;
-(BOOL)removeMessageIndex:(int)msgLocalID;
-(BOOL)clearConversation:(int64_t)uid;
-(BOOL)clear;
-(NSArray*)search:(NSString*)key;
-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content;
-(BOOL)acknowledgeMessage:(int)msgLocalID;
-(BOOL)markMessageFailure:(int)msgLocalID;
-(BOOL)markMesageListened:(int)msgLocalID;
-(BOOL)eraseMessageFailure:(int)msgLocalID;
-(BOOL)updateFlags:(int)msgLocalID flags:(int)flags;
@end
