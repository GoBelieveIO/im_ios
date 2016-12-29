//
//  CustomerMessageDB.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"
#import "ConversationIterator.h"
#import "IMessageIterator.h"
#import "FileMessageDB.h"

@interface FileCustomerMessageDB : FileMessageDB
+(FileCustomerMessageDB*)instance;

@property(nonatomic, copy) NSString *dbPath;
//普通用户客服消息存储使用聚合模式, 默认为YES
//@property(nonatomic) BOOL aggregationMode

-(id<IMessageIterator>)newMessageIterator:(int64_t)uid;
-(id<IMessageIterator>)newMessageIterator:(int64_t)uid last:(int)lastMsgID;
-(id<ConversationIterator>)newConversationIterator;

-(BOOL)insertMessage:(IMessage*)msg uid:(int64_t)uid;
-(BOOL)removeMessage:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)clearConversation:(int64_t)uid;
-(BOOL)clear;
-(BOOL)acknowledgeMessage:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)markMessageFailure:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)markMesageListened:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)eraseMessageFailure:(int)msgLocalID uid:(int64_t)uid;
@end
