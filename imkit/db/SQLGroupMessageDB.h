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
#import "IMessageDB.h"

#import <fmdb/FMDB.h>

@interface SQLGroupMessageDB : NSObject<IMessageDB>
+(SQLGroupMessageDB*)instance;

@property(nonatomic, strong) FMDatabase *db;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)gid messageID:(int)messageID;
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)gid messageID:(int)messageID;


-(IMessage*)getLastMessage:(int64_t)gid;
-(int)getMessageId:(NSString*)uuid;
-(IMessage*)getMessage:(int64_t)msgID;
-(BOOL)insertMessage:(IMessage*)msg;
-(BOOL)insertMessages:(NSArray*)msgs;
-(BOOL)removeMessage:(int)msgLocalID;
-(BOOL)removeMessageIndex:(int)msgLocalID;
-(BOOL)clearConversation:(int64_t)gid;
-(NSArray*)search:(NSString*)key;
-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content;
-(BOOL)acknowledgeMessage:(int)msgLocalID;
-(BOOL)markMessageFailure:(int)msgLocalID;
-(BOOL)markMesageListened:(int)msgLocalID;
-(BOOL)updateFlags:(int)msgLocalID flags:(int)flags;
@end
