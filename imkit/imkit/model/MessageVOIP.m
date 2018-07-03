//
//  MessageVOIP.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageVOIP.h"

@implementation MessageVOIP
-(id)initWithFlag:(int)flag duration:(int)duration videoEnabled:(BOOL)videoEnabled {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"voip":@{@"flag":@(flag), @"duration":@(duration), @"video_enabled":@(videoEnabled)}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)type {
    return MESSAGE_VOIP;
}

-(int)flag {
    return [[[self.dict objectForKey:@"voip"] objectForKey:@"flag"] intValue];
}

-(int)duration {
    return [[[self.dict objectForKey:@"voip"] objectForKey:@"duration"] intValue];
}

-(BOOL)videoEnabled {
    return [[[self.dict objectForKey:@"voip"] objectForKey:@"video_enabled"] boolValue];
}

@end
