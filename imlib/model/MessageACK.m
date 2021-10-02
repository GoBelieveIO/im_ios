//
//  MessageACK.m
//  gobelieve
//
//  Created by houxh on 2019/7/25.
//

#import "MessageACK.h"

@implementation MessageACK
-(id)initWithError:(int)err {
    NSDictionary *dic = @{@"ack":@{@"error":[NSNumber numberWithInt:err]}};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

-(int)error {
    return [[[self.dict objectForKey:@"ack"] objectForKey:@"error"] intValue];
}

-(int)type {
    return MESSAGE_ACK;
}
@end
