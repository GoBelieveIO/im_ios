//
//  MessageGroupNotification.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import "MessageNotification.h"

//群组通知消息类型
#define NOTIFICATION_GROUP_CREATED 1
#define NOTIFICATION_GROUP_DISBANDED 2
#define NOTIFICATION_GROUP_MEMBER_ADDED 3
#define NOTIFICATION_GROUP_MEMBER_LEAVED 4
#define NOTIFICATION_GROUP_NAME_UPDATED 5
#define NOTIFICATION_GROUP_NOTICE_UPDATED 6

@interface MessageGroupNotification : MessageNotificationContent

@property(nonatomic) int notificationType;

@property(nonatomic) int64_t groupID;

@property(nonatomic) int timestamp;

//created
@property(nonatomic) int64_t master;
@property(nonatomic) NSArray *members;
//GROUP_CREATED,GROUP_NAME_UPDATED
@property(nonatomic) NSString *groupName;

@property(nonatomic) NSString *notice;

//GROUP_MEMBER_ADDED,GROUP_MEMBER_LEAVED
@property(nonatomic) int64_t member;

@property(nonatomic, copy) NSString *rawNotification;

-(id)initWithNotification:(NSString*)raw;

@end

typedef MessageGroupNotification MessageGroupNotificationContent;


