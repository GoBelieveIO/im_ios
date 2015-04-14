/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "DraftDB.h"
@interface DraftDB()
@property(nonatomic) NSMutableDictionary *dict;
@end

@implementation DraftDB
+(DraftDB*)instance {
    static DraftDB *db;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!db) {
            db = [[DraftDB alloc] init];
        }
    });
    return db;
}
-(id)init {
    self = [super init];
    if (self) {
        self.dict = [NSMutableDictionary dictionary];
    }
    return self;
}

-(NSString*)getDraft:(int64_t)uid {
    NSString *key = [NSString stringWithFormat:@"draft_%lld", uid];
    return [self.dict objectForKey:key];
}

-(void)setDraft:(int64_t)uid draft:(NSString*)draft {
    NSString *key = [NSString stringWithFormat:@"draft_%lld", uid];
    [self.dict setObject:draft forKey:key];
}

-(NSString*)getGroupDraft:(int64_t)gid {
    NSString *key = [NSString stringWithFormat:@"group_draft_%lld", gid];
    return [self.dict objectForKey:key];
}
-(void)setGroupDraft:(int64_t)gid draft:(NSString*)draft {
    NSString *key = [NSString stringWithFormat:@"group_draft_%lld", gid];
    [self.dict setObject:draft forKey:key];
}

@end
