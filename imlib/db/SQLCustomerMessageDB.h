/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#import "ICustomerMessage.h"
#import "IMessageIterator.h"
#import "IMessageDB.h"

#import <fmdb/FMDB.h>


@interface SQLCustomerMessageDB : NSObject<IMessageDB>
+(SQLCustomerMessageDB*)instance;

@property(nonatomic, strong) FMDatabase *db;


-(id<IMessageIterator>)newMessageIterator:(int64_t)storeID;
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)storeID last:(int)lastMsgID;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int)lastMsgID;

-(IMessage*)getLastMessage:(int64_t)uid appID:(int64_t)appID;
-(IMessage*)getLastMessage:(int64_t)storeID;
-(IMessage*)getMessage:(int)msgID;
-(int)getMessageId:(NSString*)uuid;
-(BOOL)insertMessage:(IMessage*)msg;
-(BOOL)removeMessage:(int)msgLocalID;
-(BOOL)removeMessageIndex:(int)msgLocalID;

-(BOOL)clearConversation:(int64_t)storeID;
-(BOOL)clearConversation:(int64_t)uid appID:(int64_t)appID;
-(BOOL)clear;
-(BOOL)updateMessageContent:(int)msgLocalID content:(NSString*)content;
-(BOOL)acknowledgeMessage:(int)msgLocalID;
-(BOOL)markMessageFailure:(int)msgLocalID;
-(BOOL)markMesageListened:(int)msgLocalID;
-(BOOL)eraseMessageFailure:(int)msgLocalID;
-(BOOL)updateFlags:(int)msgLocalID flags:(int)flags;
@end
