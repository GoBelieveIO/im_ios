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
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)storeID last:(int64_t)lastMsgID;

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid appID:(int64_t)appID;
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)uid appID:(int64_t)appID last:(int64_t)lastMsgID;

-(IMessage*)getLastMessage:(int64_t)uid appID:(int64_t)appID;
-(IMessage*)getLastMessage:(int64_t)storeID;
-(IMessage*)getMessage:(int64_t)msgID;
-(int64_t)getMessageId:(NSString*)uuid;
-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)peer appid:(int64_t)peerAppId;
-(BOOL)removeMessage:(int64_t)msgLocalID;
-(BOOL)removeMessageIndex:(int64_t)msgLocalID;

-(BOOL)clearConversation:(int64_t)storeID;
-(BOOL)clearConversation:(int64_t)uid appID:(int64_t)appID;
-(BOOL)clear;
-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content;
-(BOOL)acknowledgeMessage:(int64_t)msgLocalID;
-(BOOL)markMessageFailure:(int64_t)msgLocalID;
-(BOOL)markMesageListened:(int64_t)msgLocalID;
-(BOOL)eraseMessageFailure:(int64_t)msgLocalID;
-(BOOL)updateFlags:(int64_t)msgLocalID flags:(int)flags;
@end
