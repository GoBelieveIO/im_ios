//
//  MessageACK.m
//  gobelieve
//
//  Created by houxh on 2019/7/25.
//

#import "MessageACK.h"

@implementation MessageACK
-(id)initWithError:(int)err {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"ack":@{@"error":[NSNumber numberWithInt:err]}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
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
