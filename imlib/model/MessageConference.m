//
//  MessageConference.m
//  gobelieve
//
//  Created by houxh on 2020/8/2.
//

#import "MessageConference.h"

@implementation MessageConference

-(int64_t)masterID {
    return [[[self.dict objectForKey:@"conference"] objectForKey:@"master_id"] longLongValue];
}
-(NSString*)channelID {
    return [[self.dict objectForKey:@"conference"] objectForKey:@"channel_id"];
}
-(int64_t)serverID {
    return [[[self.dict objectForKey:@"conference"] objectForKey:@"server_id"] longLongValue];;
}

-(NSString*)micMode {
    return [[self.dict objectForKey:@"conference"] objectForKey:@"mic_mode"];
}


-(int)type {
    return MESSAGE_CONFERENCE;
}

@end
