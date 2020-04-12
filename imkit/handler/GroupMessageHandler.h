/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import "IMService.h"
@interface GroupMessageHandler : NSObject<IMGroupMessageHandler>
+(GroupMessageHandler*)instance;

//当前用户id
@property(nonatomic, assign) int64_t uid;
@end
