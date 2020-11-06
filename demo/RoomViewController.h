//
//  RoomViewController.h
//  im_demo
//
//  Created by houxh on 15/7/2.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/MessageViewController.h>

@interface RoomViewController : MessageViewController
@property(nonatomic) int64_t uid;
@property(nonatomic) int64_t roomID;
@end
