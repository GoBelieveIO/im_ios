//
//  MessageNotification.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageContent.h"

@interface MessageNotification : MessageContent
@property(nonatomic, copy) NSString *notificationDesc;
@end


typedef MessageNotification MessageNotificationContent;
