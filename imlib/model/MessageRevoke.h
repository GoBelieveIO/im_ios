//
//  MessageRevoke.h
//  Pods
//
//  Created by houxh on 2018/6/26.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

@interface MessageRevoke : MessageNotificationContent
- (id)initWithMsgId:(NSString*)msgid;

@property(nonatomic, readonly) NSString* msgid;//撤回消息的uuid
@end

typedef MessageRevoke MessageRevokeContent;
