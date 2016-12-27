//
//  CustomerMessageHandler.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMService.h"

@interface CustomerMessageHandler : NSObject<IMCustomerMessageHandler>
+(CustomerMessageHandler*)instance;

//当前登录的用户id
@property(nonatomic, assign) int64_t uid;
@end
