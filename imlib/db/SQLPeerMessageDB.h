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
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid messageID:(int64_t)lastMsgID;

-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)uid messageID:(int64_t)messageID;

//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)uid messageID:(int64_t)messageID;


//获取最新的消息
-(IMessage*)getLastMessage:(int64_t)uid;
-(IMessage*)getMessage:(int64_t)msgID;
-(int64_t)getMessageId:(NSString*)uuid;
-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid;
-(BOOL)removeMessage:(int64_t)msgLocalID;
//删除全文搜索索引
-(BOOL)removeMessageIndex:(int64_t)msgLocalID;
-(BOOL)clearConversation:(int64_t)uid;
-(BOOL)clear;
-(NSArray*)search:(NSString*)key;
-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content;
-(int)acknowledgeMessage:(int64_t)msgLocalID;
-(int)markMessageFailure:(int64_t)msgLocalID;
-(int)markMesageListened:(int64_t)msgLocalID;
-(int)markMessageReaded:(int64_t)msgLocalID;
-(BOOL)eraseMessageFailure:(int64_t)msgLocalID;
-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags;
@end
