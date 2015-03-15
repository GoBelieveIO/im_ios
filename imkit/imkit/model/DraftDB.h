//
//  DraftDB.h
//  Message
//
//  Created by houxh on 14-11-28.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DraftDB : NSObject
+(DraftDB*)instance;
-(NSString*)getDraft:(int64_t)uid;
-(void)setDraft:(int64_t)uid draft:(NSString*)draft;
@end
