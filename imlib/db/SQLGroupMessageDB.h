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

-(id<IMessageIterator>)newMessageIterator:(int64_t)gid;
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)gid messageID:(int64_t)lastMsgID;
-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)gid messageID:(int64_t)messageID;
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)gid messageID:(int64_t)messageID;
-(id<IMessageIterator>)newTopicMessageIterator:(int64_t)gid topic:(NSString*)uuid;

-(IMessage*)getLastMessage:(int64_t)gid;
-(int64_t)getMessageId:(NSString*)uuid;
-(IMessage*)getMessage:(int64_t)msgID;
-(int)getMessageReferenceCount:(NSString*)uuid;
-(int)getMessageReaderCount:(int64_t)msgID;

-(BOOL)insertMessage:(IMessage*)msg;
-(BOOL)insertMessages:(NSArray*)msgs;
-(BOOL)removeMessage:(int64_t)msgLocalID;
-(BOOL)removeMessageIndex:(int64_t)msgLocalID;
-(BOOL)clearConversation:(int64_t)gid;
-(NSArray*)search:(NSString*)key;
-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content;
-(int)acknowledgeMessage:(int64_t)msgLocalID;
-(int)markMessageFailure:(int64_t)msgLocalID;
-(int)markMesageListened:(int64_t)msgLocalID;
-(int)markMessageReaded:(int64_t)msg;
-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags;

-(BOOL)addMessage:(int64_t)msgId tag:(NSString*)tag;
-(BOOL)removeMessage:(int64_t)msgId tag:(NSString*)tag;
//记录已读
-(BOOL)addMessage:(int64_t)msgId reader:(int64_t)uid;
-(NSArray*)getMessageReaders:(int64_t)msgId;
@end
