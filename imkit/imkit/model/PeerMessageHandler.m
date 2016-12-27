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

-(BOOL)handleMessage:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    IMMessage *im = msg;
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.rawContent = im.content;
    m.timestamp = msg.timestamp;
    
    if (self.uid == msg.sender) {
        m.flags = m.flags|MESSAGE_FLAG_ACK;
    }
    BOOL r = [[PeerMessageDB instance] insertMessage:m uid:pid];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    return [[PeerMessageDB instance] acknowledgeMessage:msg.msgLocalID uid:pid];
}

-(BOOL)handleMessageFailure:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    PeerMessageDB *db = [PeerMessageDB instance];
    return [db markMessageFailure:msg.msgLocalID uid:pid];
}

@end
