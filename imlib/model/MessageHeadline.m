//
//  MessageHeadline.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageHeadline.h"


@implementation MessageHeadline
-(id)initWithHeadline:(NSString*)headline {
    NSDictionary *dic = @{@"headline":headline};
    self = [super initWithDictionary:dic];
    if (self) {

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
