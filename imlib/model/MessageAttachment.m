//
//  MessageAttachment.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageAttachment.h"


@implementation MessageAttachment

- (id)initWithAttachment:(int64_t)msgLocalID address:(NSString*)address {
    NSDictionary *attachment = @{@"address":address,
                                 @"msg_id":@(msgLocalID)};
    NSDictionary *dic = @{@"attachment":attachment};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
    
}

- (id)initWithAttachment:(int64_t)msgLocalID url:(NSString*)url {
    NSDictionary *attachment = @{@"url":url,
                                 @"msg_id":@(msgLocalID)};
    NSDictionary *dic = @{@"attachment":attachment};
    self = [super initWithDictionary:dic];
    if (self) {

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
