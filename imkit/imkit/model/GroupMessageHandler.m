/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupMessageHandler.h"
#import "IMessage.h"
#import "IMService.h"
#import "GroupMessageDB.h"

@implementation GroupMessageHandler
+(GroupMessageHandler*)instance {
    static GroupMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[GroupMessageHandler alloc] init];
        }
    });
    return m;
}

-(BOOL)handleMessage:(IMMessage*)im {
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    if (self.uid == im.sender) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    BOOL r = [[GroupMessageDB instance] insertMessage:m];
    if (r) {
        im.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(IMessage*)msg {
    return [[GroupMessageDB instance] acknowledgeMessage:msg.msgLocalID gid:msg.receiver];
}

-(BOOL)handleMessageFailure:(IMessage*)msg {
    return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID gid:msg.receiver];
}

-(BOOL)handleGroupNotification:(NSString*)notification {
    MessageGroupNotificationContent *obj = [[MessageGroupNotificationContent alloc] initWithNotification:notification];
    
    IMessage *m = [[IMessage alloc] init];
    m.sender = 0;
    m.receiver = obj.groupID;
    m.rawContent = obj.raw;

    if (obj.timestamp > 0) {
        m.timestamp = obj.timestamp;
    } else {
        m.timestamp = (int)time(NULL);
    }
    BOOL r = [[GroupMessageDB instance] insertMessage:m];
    return r;
}
@end
