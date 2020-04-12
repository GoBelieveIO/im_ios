//
//  MessageHeadline.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageHeadline.h"


@implementation MessageHeadline
-(id)initWithHeadline:(NSString*)headline {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"headline":headline};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(NSString*)notificationDesc {
    return [self headline];
}

-(NSString*)headline {
    return [self.dict objectForKey:@"headline"];
}

-(int)type {
    return MESSAGE_HEADLINE;
}
@end
