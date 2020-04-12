/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"


//最近发出的消息
#define LATEST_GROUP_MESSAGE       @"latest_group_message"

//清空会话的未读消息数
#define CLEAR_GROUP_NEW_MESSAGE @"clear_group_single_conv_new_message_notify"

@interface GroupMessageViewController : MessageViewController<GroupMessageObserver, TCPConnectionObserver>
@property(nonatomic) int64_t groupID;
@property(nonatomic, copy) NSString *groupName;
@property(nonatomic) BOOL disbanded;

@end
