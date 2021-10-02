//
//  MessageRevoke.m
//  Pods
//
//  Created by houxh on 2018/6/26.
//

#import "MessageRevoke.h"

@implementation MessageRevoke
-(id)initWithMsgId:(NSString*)msgid {
    NSDictionary *dic = @{@"revoke":@{@"msgid":msgid}};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

-(NSString*)msgid {
    return [[self.dict objectForKey:@"revoke"] objectForKey:@"msgid"];
}

-(int)type {
    return MESSAGE_REVOKE;
}

@end
