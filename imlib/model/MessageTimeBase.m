//
//  MessageTimeBase.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageTimeBase.h"

@implementation MessageTimeBase

-(id)initWithTimestamp:(int)ts {
    NSDictionary *dic = @{@"timestamp":[NSNumber numberWithInt:ts]};
    self = [super initWithDictionary:dic];
    if (self) {

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

