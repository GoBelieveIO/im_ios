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

//将发送失败的消息置为成功
-(void)repairFailureMessage:(NSString*)uuid {
    GroupMessageDB *db = [GroupMessageDB instance];
    if (uuid.length > 0) {
        int msgId = [db getMessageId:uuid];
        IMessage *mm = [db getMessage:msgId];
        if (mm != nil) {
            if ((mm.flags & MESSAGE_FLAG_FAILURE) != 0 || (mm.flags & MESSAGE_FLAG_ACK) == 0) {
                mm.flags = mm.flags & (~MESSAGE_FLAG_FAILURE);
                mm.flags = mm.flags | MESSAGE_FLAG_ACK;
                [db updateFlags:mm.msgLocalID flags:mm.flags];
            }
        }
    }
}


-(BOOL)handleMessages:(NSArray *)msgs {
    NSMutableArray *imsgs = [NSMutableArray array];
    NSMutableArray *insertedMsgs = [NSMutableArray array];
    for (IMMessage *im in msgs) {
        IMessage *m = [[IMessage alloc] init];
        m.sender = im.sender;
        m.receiver = im.receiver;
        m.timestamp = im.timestamp;
        if (self.uid == im.sender) {
            m.flags = m.flags | MESSAGE_FLAG_ACK;
        }
        if (im.isGroupNotification) {
            MessageGroupNotificationContent *obj = [[MessageGroupNotificationContent alloc] initWithNotification:im.content];
            im.receiver = obj.groupID;
            im.timestamp = obj.timestamp;
            
            m.rawContent = obj.raw;
            m.receiver = obj.groupID;
            if (obj.timestamp > 0) {
                m.timestamp = obj.timestamp;
            } else {
                m.timestamp = (int)time(NULL);
            }
        } else {
            m.rawContent = im.content;
        }

        if (im.isSelf) {
            NSAssert(im.sender == self.uid, @"");
            [self repairFailureMessage:m.uuid];
        } else if (m.type == MESSAGE_REVOKE) {
            MessageRevoke *revoke = m.revokeContent;
            int msgId = [[GroupMessageDB instance] getMessageId:revoke.msgid];
            if (msgId > 0) {
                [[GroupMessageDB instance] updateMessageContent:msgId content:im.content];
                [[GroupMessageDB instance] removeMessageIndex:msgId];
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


-(BOOL)handleMessageACK:(IMMessage*)msg error:(int)error {
    if (error == MSG_ACK_SUCCESS) {
        if (msg.msgLocalID > 0) {
            return [[GroupMessageDB instance] acknowledgeMessage:msg.msgLocalID];
        } else {
            MessageContent *content = [IMessage fromRaw:msg.content];
            if (content.type == MESSAGE_REVOKE) {
                MessageRevoke *revoke = (MessageRevoke*)content;
                int revokedMsgId = [[GroupMessageDB instance] getMessageId:revoke.msgid];
                if (revokedMsgId > 0) {
                    [[GroupMessageDB instance]  updateMessageContent:revokedMsgId content:msg.content];
                    [[GroupMessageDB instance] removeMessageIndex:revokedMsgId];
                }
            }
            return YES;
        }
    } else {
        if (msg.msgLocalID > 0) {
            return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID];
        }
        return YES;
    }
}

-(BOOL)handleMessageFailure:(IMMessage*)msg {
    return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID];
}

@end
