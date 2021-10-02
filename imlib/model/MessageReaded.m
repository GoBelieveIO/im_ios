//
//  MessageReaded.m
//  gobelieve
//
//  Created by houxh on 2020/4/25.
//

#import "MessageReaded.h"

@implementation MessageReaded
-(id)initWithMsgId:(NSString*)msgid {
    NSDictionary *dic = @{@"readed":@{@"msgid":msgid}};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

-(NSString*)msgid {
    return [[self.dict objectForKey:@"readed"] objectForKey:@"msgid"];
}


-(int)type {
    return MESSAGE_READED;
}
@end
