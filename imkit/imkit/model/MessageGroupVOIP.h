//
//  MessageGroupVOIP.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

@interface MessageGroupVOIP : MessageNotificationContent

@property(nonatomic) int64_t initiator;
@property(nonatomic) BOOL finished;

-(id)initWithInitiator:(int64_t)initiator finished:(BOOL)finished;
@end

typedef MessageGroupVOIP MessageGroupVOIPContent;
