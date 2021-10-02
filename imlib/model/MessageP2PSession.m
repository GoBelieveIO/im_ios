//
//  MessageP2PSession.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageP2PSession.h"


@implementation MessageP2PSession
-(id)initWithDeviceID:(NSString*)deviceID channelID:(NSString*)channelID {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDictionary *dic = @{@"p2p_session":@{@"device_id":deviceID, @"channel_id":channelID}, @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

-(int)type {
    return MESSAGE_P2P_SESSION;
}

-(NSString*)deviceID {
    return [[self.dict objectForKey:@"p2p_session"] objectForKey:@"device_id"];
}

-(NSString*)channelID {
    return [[self.dict objectForKey:@"p2p_session"] objectForKey:@"channel_id"];
}

@end

