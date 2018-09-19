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

-(BOOL)handleMessages:(NSArray *)msgs {
    NSMutableArray *imsgs = [NSMutableArray array];
    NSMutableArray *insertedMsgs = [NSMutableArray array];
    for (IMMessage *im in msgs) {
        IMessage *m = [[IMessage alloc] init];
        m.sender = im.sender;
        m.receiver = im.receiver;
        m.rawContent = im.content;
        m.timestamp = im.timestamp;
        if (self.uid == im.sender) {
            m.flags = m.flags | MESSAGE_FLAG_ACK;
        }
        
        if (m.type == MESSAGE_REVOKE) {
            MessageRevoke *revoke = m.revokeContent;
            int msgId = [[GroupMessageDB instance] getMessageId:revoke.msgid];
            if (msgId > 0) {
                [[GroupMessageDB instance] updateMessageContent:msgId content:im.content];
                [[GroupMessageDB instance] removeMessageIndex:msgId gid:im.receiver];
            }
        } else {
            [imsgs addObject:m];
            [insertedMsgs addObject:im];
        }
    }
    if (imsgs.count > 0) {
        [[GroupMessageDB instance] insertMessages:imsgs];
    }
    for (NSInteger i = 0; i < insertedMsgs.count; i++) {
        IMessage *imsg = [imsgs objectAtIndex:i];
        IMMessage *im = [insertedMsgs objectAtIndex:i];
        im.msgLocalID = imsg.msgLocalID;
    }
    return YES;
}

-(BOOL)handleMessageACK:(IMMessage*)msg {
    if (msg.msgLocalID > 0) {
        return [[GroupMessageDB instance] acknowledgeMessage:msg.msgLocalID gid:msg.receiver];
    } else {
        MessageContent *content = [IMessage fromRaw:msg.content];
        if (content.type == MESSAGE_REVOKE) {
            MessageRevoke *revoke = (MessageRevoke*)content;
            int revokedMsgId = [[GroupMessageDB instance] getMessageId:revoke.msgid];
            if (revokedMsgId > 0) {
                [[GroupMessageDB instance]  updateMessageContent:revokedMsgId content:msg.content];
                [[GroupMessageDB instance] removeMessageIndex:revokedMsgId gid:msg.receiver];
            }
        }
        return YES;
    }
}

-(BOOL)handleMessageFailure:(IMMessage*)msg {
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
