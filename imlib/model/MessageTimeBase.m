//
//  MessageTimeBase.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageTimeBase.h"

@implementation MessageTimeBase

-(id)initWithTimestamp:(int)ts {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"timestamp":[NSNumber numberWithInt:ts]};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)timestamp {
    return [[self.dict objectForKey:@"timestamp"] intValue];
}

-(int)type {
    return MESSAGE_TIME_BASE;
}
@end

