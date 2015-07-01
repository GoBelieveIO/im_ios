/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"
#import "TextMessageViewController.h"

#undef TEXT_MODE
#ifdef TEXT_MODE
@interface GroupMessageViewController : TextMessageViewController<GroupMessageObserver,  TCPConnectionObserver, LoginPointObserver>
#else
@interface GroupMessageViewController : MessageViewController<GroupMessageObserver,  TCPConnectionObserver, LoginPointObserver>
#endif

@property(nonatomic) int64_t currentUID;
@property(nonatomic) int64_t groupID;
@property(nonatomic, copy) NSString *groupName;
@property(nonatomic) BOOL disbanded;


@end
