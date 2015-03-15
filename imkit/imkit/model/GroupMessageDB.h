//
//  GroupMessageDB.h
//  Message
//
//  Created by houxh on 14-7-22.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IMessage.h"

@interface GroupMessageDB : NSObject
+(GroupMessageDB*)instance;

-(BOOL)insertGroupMessage:(IMessage*)msg;
-(BOOL)removeGroupMessage:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)clearGroupConversation:(int64_t)gid;
-(BOOL)acknowledgeGroupMessage:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)markGroupMessageFailure:(int)msgLocalID gid:(int64_t)gid;

@end