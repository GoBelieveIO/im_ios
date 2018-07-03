/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageContent.h"


@implementation MessageContent
- (id)initWithRaw:(NSString*)raw {
    self = [super init];
    if (self) {
        self.raw = raw;
    }
    return self;
}

-(void)setRaw:(NSString *)raw {
    _raw = [raw copy];
    const char *utf8 = [raw UTF8String];
    if (utf8 == nil) return;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    self.dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
}

-(NSString*)uuid {
    return [self.dict objectForKey:@"uuid"];
}

-(int)type {
    return MESSAGE_UNKNOWN;
}

@end
