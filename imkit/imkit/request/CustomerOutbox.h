//
//  CustomerOutbox.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "Outbox.h"

@interface CustomerOutbox : Outbox

+(CustomerOutbox*)instance;

//当前登录用户是否为客服人员,默认为NO
@property(nonatomic) BOOL  isStaff;

@end
