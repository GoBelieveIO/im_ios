//
//  MessageAttachment.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageAttachment.h"


@implementation MessageAttachment

- (id)initWithAttachment:(int)msgLocalID address:(NSString*)address {
    self = [super init];
    if (self) {
        NSDictionary *attachment = @{@"address":address,
                                     @"msg_id":[NSNumber numberWithInt:msgLocalID]};
        NSDictionary *dic = @{@"attachment":attachment};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
    
}

- (id)initWithAttachment:(int)msgLocalID url:(NSString*)url {
    self = [super init];
    if (self) {
        NSDictionary *attachment = @{@"url":url,
                                     @"msg_id":[NSNumber numberWithInt:msgLocalID]};
        NSDictionary *dic = @{@"attachment":attachment};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

- (int)msgLocalID {
    return [[[self.dict objectForKey:@"attachment"] objectForKey:@"msg_id"] intValue];
}

- (NSString*)address {
    return [[self.dict objectForKey:@"attachment"] objectForKey:@"address"];
}

- (NSString*)url {
    return [[self.dict objectForKey:@"attachment"] objectForKey:@"url"];
}

-(int)type {
    return MESSAGE_ATTACHMENT;
}
@end
