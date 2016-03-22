//
//  RoomViewController.h
//  im_demo
//
//  Created by houxh on 15/7/2.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <gobelieve/TextMessageViewController.h>

@interface RoomViewController : TextMessageViewController
@property(nonatomic) int64_t uid;
@property(nonatomic) int64_t roomID;
@end
