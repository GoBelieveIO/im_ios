//
//  DraftDB.m
//  Message
//
//  Created by houxh on 14-11-28.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

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

@end
