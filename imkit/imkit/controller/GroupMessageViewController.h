//
//  GroupMessageViewController.h
//  imkit
//
//  Created by houxh on 15/3/19.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "MessageViewController.h"
#import "TextMessageViewController.h"

#define TEXT_MODE
#ifdef TEXT_MODE
@interface GroupMessageViewController : TextMessageViewController
#else
@interface GroupMessageViewController : MessageViewController
#endif

@property(nonatomic) int64_t currentUID;
@property(nonatomic) int64_t groupID;
@property(nonatomic, copy) NSString *groupName;
@property(nonatomic) BOOL disbanded;


@end
