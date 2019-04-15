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
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)conversationID last:(int)lastMsgID;

-(id<IMessageIterator>)newMiddleMessageIterator:(int64_t)conversationID messageID:(int)messageID;

//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)conversationID messageID:(int)messageID;

-(IMessage*)getMessage:(int64_t)msgID;
-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
-(BOOL)saveMessage:(IMessage*)msg;
-(BOOL)removeMessage:(int)msg;
-(BOOL)markMessageFailure:(int)msg;
-(BOOL)markMesageListened:(int)msg;
-(BOOL)eraseMessageFailure:(int)msg;

@end


