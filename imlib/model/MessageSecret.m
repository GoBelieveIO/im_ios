/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageSecret.h"


@implementation MessageSecret

-(id)initWithCiphertext:(NSString*)ciphertext cipherType:(int)type uuid:(NSString*)uuid {
    self = [super init];
    if (self) {
        NSDictionary *dic = @{@"secret":@{@"ciphertext":ciphertext, @"type":@(type)}, @"uuid":uuid ? uuid : @""};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(int)type {
    return MESSAGE_SECRET;
}

-(NSString*)ciphertext {
    return [[self.dict objectForKey:@"secret"] objectForKey:@"ciphertext"];
}

-(int)cipherType {
    return [[[self.dict objectForKey:@"secret"] objectForKey:@"type"] intValue];
}
@end
