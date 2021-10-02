//
//  Database.h
//  contact
//
//  Created by houxh on 2018/10/8.
//  Copyright © 2018年 momo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@interface Database : NSObject
+ (FMDatabase*)openMessageDB:(NSString*)dbPath;

@end
