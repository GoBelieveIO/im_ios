//
//  MessageGroupVOIP.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageGroupVOIP.h"




@implementation MessageGroupVOIP
-(id)initWithInitiator:(int64_t)initiator finished:(BOOL)finished {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"group_voip":@{@"initiator":@(initiator), @"finished":@(finished)}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)type {
    return MESSAGE_GROUP_VOIP;
}

-(int64_t)initiator {
    return [[[self.dict objectForKey:@"group_voip"] objectForKey:@"initiator"] longLongValue];
}

-(BOOL)finished {
    return [[[self.dict objectForKey:@"group_voip"] objectForKey:@"finished"] boolValue];
}

@end
