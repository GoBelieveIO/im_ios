//
//  MessageText.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageText.h"

@implementation MessageText

-(id)initWithText:(NSString*)text {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *dic = @{@"text":text, @"uuid":uuid};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
        NSString* newStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(id)initWithText:(NSString*)text at:(NSArray*)at atNames:(NSArray*)atNames {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:text forKey:@"text"];
        [dict setObject:uuid forKey:@"uuid"];
        if (at.count > 0) {
            [dict setObject:at forKey:@"at"];
        }
        if (atNames.count > 0) {
            [dict setObject:atNames forKey:@"at_name"];
        }
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
        NSString* newStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
    }
    return self;
}

-(NSString*)text {
    return [self.dict objectForKey:@"text"];
}

-(NSArray*)at {
    return [self.dict objectForKey:@"at"];
}

-(NSArray*)atNames {
    return [self.dict objectForKey:@"at_name"];
}

-(int)type {
    return MESSAGE_TEXT;
}
@end


