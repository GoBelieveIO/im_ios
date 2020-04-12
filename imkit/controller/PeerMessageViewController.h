/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"

//最近发出的消息
#define LATEST_PEER_MESSAGE        @"latest_peer_message"
#define LATEST_PEER_SECRET_MESSAGE        @"latest_peer_secret_message"

//清空会话的未读消息数
#define CLEAR_PEER_NEW_MESSAGE @"clear_peer_single_conv_new_message_notify"
#define CLEAR_PEER_SECRET_NEW_MESSAGE @"clear_peer_secret_single_conv_new_message_notify"

@interface PeerMessageViewController : MessageViewController<PeerMessageObserver, TCPConnectionObserver>
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, copy) NSString *peerName;
@property(nonatomic, copy) NSString *peerAvatar;
@property(nonatomic, assign) BOOL secret;//点对点加密
@property(nonatomic, assign) int state;//加密会话的状态
@end
