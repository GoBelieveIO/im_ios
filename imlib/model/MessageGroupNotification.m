//
//  MessageGroupNotification.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageGroupNotification.h"


@implementation MessageGroupNotification
- (id)initWithDictionary:(NSDictionary*)dict {
    self = [super initWithDictionary:dict];
    if (self) {
        NSString *notification = [self.dict objectForKey:@"notification"];
        self.rawNotification = notification;
    }
    return self;
}

- (id)initWithRaw:(NSString *)raw {
    self = [super initWithRaw:raw];
    if (self) {
        NSString *notification = [self.dict objectForKey:@"notification"];
        self.rawNotification = notification;
    }
    return self;
}

- (id)initWithNotification:(NSString*)notification {
    NSDictionary *dic = @{@"notification":notification};
    self = [super initWithDictionary:dic];
    if (self) {
        self.rawNotification = notification;
    }
    return self;
}

- (void)setRawNotification:(NSString *)rawNotification {
    _rawNotification = [rawNotification copy];
    const char *utf8 = [rawNotification UTF8String];
    if (utf8 == nil) {
        utf8 = "";
    }
    
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    
    if ([dict objectForKey:@"create"]) {
        self.notificationType = NOTIFICATION_GROUP_CREATED;
        NSDictionary *d = [dict objectForKey:@"create"];
        self.master = [[d objectForKey:@"master"] longLongValue];
        self.groupName = [d objectForKey:@"name"];
        self.groupID = [[d objectForKey:@"group_id"] longLongValue];
        self.members = [d objectForKey:@"members"];
        self.timestamp = [[d objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"disband"]) {
        self.notificationType = NOTIFICATION_GROUP_DISBANDED;
        NSDictionary *obj = [dict objectForKey:@"disband"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"quit_group"]) {
        self.notificationType = NOTIFICATION_GROUP_MEMBER_LEAVED;
        NSDictionary *obj = [dict objectForKey:@"quit_group"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.member =[[obj objectForKey:@"member_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"add_member"]) {
        self.notificationType = NOTIFICATION_GROUP_MEMBER_ADDED;
        NSDictionary *obj = [dict objectForKey:@"add_member"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.member =[[obj objectForKey:@"member_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
    } else if ([dict objectForKey:@"update_name"]) {
        self.notificationType = NOTIFICATION_GROUP_NAME_UPDATED;
        NSDictionary *obj = [dict objectForKey:@"update_name"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
        self.groupName = [obj objectForKey:@"name"];
    } else if ([dict objectForKey:@"update_notice"]) {
        self.notificationType = NOTIFICATION_GROUP_NOTICE_UPDATED;
        NSDictionary *obj = [dict objectForKey:@"update_notice"];
        self.groupID = [[obj objectForKey:@"group_id"] longLongValue];
        self.timestamp = [[obj objectForKey:@"timestamp"] intValue];
        self.notice = [obj objectForKey:@"notice"];
    }
}

-(int)type {
    return MESSAGE_GROUP_NOTIFICATION;
}
@end

