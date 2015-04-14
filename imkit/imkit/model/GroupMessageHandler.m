/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupMessageHandler.h"
#import "IMessage.h"
#import <imsdk/IMService.h>
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
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = im.timestamp;
    BOOL r = [[GroupMessageDB instance] insertMessage:m];
    if (r) {
        im.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(int)msgLocalID gid:(int64_t)uid {
    return [[GroupMessageDB instance] acknowledgeMessage:msgLocalID gid:uid];
}

-(BOOL)handleMessageFailure:(int)msgLocalID gid:(int64_t)uid {
    return [[GroupMessageDB instance] markMessageFailure:msgLocalID gid:uid];
}

-(BOOL)handleGroupNotification:(NSString*)notification {
    GroupNotification *obj = [[GroupNotification alloc] initWithRaw:notification];
    IMessage *m = [[IMessage alloc] init];
    m.sender = 0;
    m.receiver = obj.groupID;
    MessageContent *content = [[MessageContent alloc] initWithNotification:obj];
    m.content = content;
    m.timestamp = (int)time(NULL);
    BOOL r = [[GroupMessageDB instance] insertMessage:m];
    return r;
}
@end
