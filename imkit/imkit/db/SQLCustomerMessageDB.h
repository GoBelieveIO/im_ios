/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "ICustomerMessage.h"
#import "MessageDB.h"
#import "IMessageIterator.h"
#import "ConversationIterator.h"

#import <FMDB/FMDB.h>


@interface SQLCustomerMessageDB : NSObject
+(SQLCustomerMessageDB*)instance;

@property(nonatomic, strong) FMDatabase *db;


-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(IMessage*)getLastMessage:(int64_t)storeID;
-(IMessage*)getMessage:(int)msgID;
-(int)getMessageId:(NSString*)uuid;
-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)storeID;
-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)storeID;
-(BOOL)removeMessageIndex:(int)msgLocalID uid:(int64_t)storeID;
-(BOOL)clearConversation:(int64_t)storeID;
-(BOOL)clear;
-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content;
-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)storeID;
-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)storeID;
-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)storeID;
-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)storeID;
-(BOOL)updateFlags:(int)msgLocalID flags:(int)flags;
@end
