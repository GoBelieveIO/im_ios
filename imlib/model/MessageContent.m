/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageContent.h"
@interface MessageContent()
@property(nonatomic) NSMutableDictionary *mutableDict;
@end

@implementation MessageContent
- (id)initWithRaw:(NSString*)raw {
    self = [super init];
    if (self) {
        self.raw = raw;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary*)dict {
    self = [super init];
    if (self) {
        self.mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:0 error:nil] encoding:NSUTF8StringEncoding];
        _raw = [newStr copy];
    }
    return self;
}

-(void)setRaw:(NSString *)raw {
    _raw = [raw copy];
    const char *utf8 = [raw UTF8String];
    if (utf8 == nil) return;
    NSData *data = [NSData dataWithBytes:utf8 length:strlen(utf8)];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    self.mutableDict = [NSMutableDictionary dictionaryWithDictionary:dict];
}

-(NSDictionary*)dict {
    return self.mutableDict;
}

-(NSString*)uuid {
    return [self.dict objectForKey:@"uuid"];
}

-(void)setUuid:(NSString *)uuid {
    [self.mutableDict setObject:uuid forKey:@"uuid"];
}
-(NSString*)reference {
    return [self.dict objectForKey:@"reference"];
}

-(void)setReference:(NSString *)reference {
    [self.mutableDict setObject:reference forKey:@"reference"];
}

-(int64_t)groupId {
    return [[self.dict objectForKey:@"group_id"] longLongValue];
}

-(void)setGroupId:(int64_t)groupId {
    [self.mutableDict setObject:@(groupId) forKey:@"group_id"];
}



-(int)type {
    return MESSAGE_UNKNOWN;
}

-(void)generateRaw {
    NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:self.dict options:0 error:nil] encoding:NSUTF8StringEncoding];
    _raw = [newStr copy];
}


@end


@implementation MessageContent(Customer)


-(int64_t)storeId {
    return [[self.dict objectForKey:@"store_id"] longLongValue];
}

-(NSString*)storeName {
    return [self.dict objectForKey:@"store_name"];
}

-(NSString*)name {
    return [self.dict objectForKey:@"name"];
}

-(NSString*)appName {
    return [self.dict objectForKey:@"app_name"];
}

-(NSString*)sessionId {
    return [self.dict objectForKey:@"session_id"];
}


-(void)setStoreId:(int64_t)storeId {
    [self.mutableDict setObject:@(storeId) forKey:@"store_id"];
}

-(void)setStoreName:(NSString *)storeName {
    [self.mutableDict setObject:storeName?storeName:@"" forKey:@"store_name"];
}

-(void)setName:(NSString*)name {
    [self.mutableDict setObject:name?name:@"" forKey:@"name"];
}

-(void)setAppName:(NSString *)appName {
    [self.mutableDict setObject:appName?appName:@"" forKey:@"app_name"];
}

-(void)setSessionId:(NSString *)sessionId {
    [self.mutableDict setObject:sessionId?sessionId:@"" forKey:@"session_id"];
}
@end
