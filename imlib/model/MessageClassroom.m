//
//  MessageClassroom.m
//  gobelieve
//
//  Created by houxh on 2020/3/3.
//

#import "MessageClassroom.h"

@implementation MessageClassroom
-(int64_t)masterID {
    return [[[self.dict objectForKey:@"classroom"] objectForKey:@"master_id"] longLongValue];
}
-(NSString*)channelID {
    return [[self.dict objectForKey:@"classroom"] objectForKey:@"channel_id"];
}
-(int64_t)serverID {
    return [[[self.dict objectForKey:@"classroom"] objectForKey:@"server_id"] longLongValue];;
}

-(NSString*)micMode {
    return [[self.dict objectForKey:@"classroom"] objectForKey:@"mic_mode"];
}

-(int)type {
    return MESSAGE_CLASSROOM;
}
@end


