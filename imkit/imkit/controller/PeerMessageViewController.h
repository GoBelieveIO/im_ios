/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageViewController.h"
#import "TextMessageViewController.h"
#define TEXT_MODE1
#ifdef TEXT_MODE
@interface PeerMessageViewController : TextMessageViewController<PeerMessageObserver,  TCPConnectionObserver, LoginPointObserver>
#else
@interface PeerMessageViewController : MessageViewController<PeerMessageObserver,  TCPConnectionObserver, LoginPointObserver>
#endif

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, copy) NSString *peerName;

@end
