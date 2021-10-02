//
//  IMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"
#import "IMessageIterator.h"

#define PAGE_COUNT 10
@protocol IMessageDB<NSObject>
-(id<IMessageIterator>)newMessageIterator:(int64_t)conversationID;
//下拉刷新
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID;

-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID;

//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID messageID:(int64_t)messageID;

-(IMessage*)getMessage:(int64_t)msgID;
-(BOOL)saveMessage:(IMessage*)msg;
-(BOOL)updateMessageContent:(int64_t)msgLocalID content:(NSString*)content;
-(BOOL)removeMessage:(int64_t)msg;
-(BOOL)markMessageFailure:(int64_t)msg;
-(BOOL)markMesageListened:(int64_t)msg;
-(BOOL)markMessageReaded:(int64_t)msg;
-(BOOL)eraseMessageFailure:(int64_t)msg;
@end


