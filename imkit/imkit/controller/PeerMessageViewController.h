/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"
#import "TextMessageViewController.h"

//最近发出的消息
#define LATEST_PEER_MESSAGE        @"latest_peer_message"

//清空会话的未读消息数
#define CLEAR_PEER_NEW_MESSAGE @"clear_peer_single_conv_new_message_notify"

@interface PeerMessageViewController : MessageViewController<PeerMessageObserver, TCPConnectionObserver>
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, copy) NSString *peerName;
@property(nonatomic, copy) NSString *peerAvatar;
@end
