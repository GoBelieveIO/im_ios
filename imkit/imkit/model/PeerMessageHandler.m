/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageHandler.h"
#import "MessageDB.h"
#import "Message.h"
#import "PeerMessageDB.h"

@implementation PeerMessageHandler
+(PeerMessageHandler*)instance {
    static PeerMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[PeerMessageHandler alloc] init];
        }
    });
    return m;
}

-(BOOL)handleMessage:(IMMessage*)msg uid:(int64_t)uid{
    IMMessage *im = msg;
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.rawContent = im.content;
    m.timestamp = msg.timestamp;
    BOOL r = [[PeerMessageDB instance] insertMessage:m uid:uid];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(int)msgLocalID uid:(int64_t)uid {
    return [[PeerMessageDB instance] acknowledgeMessage:msgLocalID uid:uid];
}

-(BOOL)handleMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    PeerMessageDB *db = [PeerMessageDB instance];
    return [db markMessageFailure:msgLocalID uid:uid];
}

@end
