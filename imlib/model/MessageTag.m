//
//  MessageTag.m
//  gobelieve
//
//  Created by houxh on 2020/5/13.
//

#import "MessageTag.h"

@implementation MessageTag
- (id)initWithMsgId:(NSString*)msgid addTag:(NSString*)tag {
    NSDictionary *dic = @{@"tag":@{@"msgid":msgid, @"add_tag":tag}};
     self = [super initWithDictionary:dic];
     if (self) {

     }
     return self;
}
- (id)initWithMsgId:(NSString*)msgid deleteTag:(NSString*)tag {
    NSDictionary *dic = @{@"tag":@{@"msgid":msgid, @"delete_tag":tag}};
     self = [super initWithDictionary:dic];
     if (self) {

     }
     return self;
}

-(NSString*)msgid {
    return [[self.dict objectForKey:@"tag"] objectForKey:@"msgid"];
}

-(NSString*)addTag {
    return [[self.dict objectForKey:@"tag"] objectForKey:@"add_tag"];
}

-(NSString*)deleteTag {
    return [[self.dict objectForKey:@"tag"] objectForKey:@"delete_tag"];
}

-(int)type {
    return MESSAGE_TAG;
}
@end
