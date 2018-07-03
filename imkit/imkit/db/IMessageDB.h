//
//  IMessageDB.h
//  gobelieve
//
//  Created by houxh on 2017/11/12.
//

#import <Foundation/Foundation.h>
#import "IMessage.h"

#define PAGE_COUNT 10
@protocol IMessageDB<NSObject>


- (NSArray*)loadConversationData;
- (NSArray*)loadConversationData:(int)messageID;
- (NSArray*)loadEarlierData:(int)messageID;
- (NSArray*)loadLateData:(int)messageID;

-(IMessage*)newOutMessage;

-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
-(BOOL)saveMessage:(IMessage*)msg;
-(BOOL)removeMessage:(IMessage*)msg;
-(BOOL)markMessageFailure:(IMessage*)msg;
-(BOOL)markMesageListened:(IMessage*)msg;
-(BOOL)eraseMessageFailure:(IMessage*)msg;

@end


