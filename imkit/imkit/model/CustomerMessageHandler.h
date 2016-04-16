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
@end
