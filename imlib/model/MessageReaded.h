//
//  MessageReaded.h
//  gobelieve
//
//  Created by houxh on 2020/4/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageReaded : MessageContent
- (id)initWithMsgId:(NSString*)msgid;
@property(nonatomic, readonly) NSString *msgid; //已读消息的uuid
@end


