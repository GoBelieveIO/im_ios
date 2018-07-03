//
//  MessageRevoke.m
//  Pods
//
//  Created by houxh on 2018/6/26.
//

#import "MessageRevoke.h"

@implementation MessageRevoke
-(id)initWithMsgId:(NSString*)msgid {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"revoke":@{@"msgid":msgid}};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
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
