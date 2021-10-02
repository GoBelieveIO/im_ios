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
        int64_t msgId = [db getMessageId:uuid];
        IMessage *mm = [db getMessage:msgId];
        if (mm != nil) {
            if ((mm.flags & MESSAGE_FLAG_FAILURE) != 0 || (mm.flags & MESSAGE_FLAG_ACK) == 0) {
                mm.flags = mm.flags & (~MESSAGE_FLAG_FAILURE);
                mm.flags = mm.flags | MESSAGE_FLAG_ACK;
                [db updateFlags:mm.msgId flags:mm.flags];
            }
        }
    }
}


-(BOOL)handleMessages:(NSArray *)msgs {
    NSMutableArray *controlMsgs = [NSMutableArray array];
    NSMutableArray *cmsgs = [NSMutableArray array];
    
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
            m.isOutgoing = YES;
        }

        //improve json searialize performance
        im.dict = m.content.dict;
        if (im.isSelf) {
            NSAssert(im.sender == self.uid, @"");
            [self repairFailureMessage:m.uuid];
        } else if (m.type == MESSAGE_REVOKE ||
                   m.type == MESSAGE_TAG ||
                   m.type == MESSAGE_READED) {
            [controlMsgs addObject:m];
            [cmsgs addObject:im];
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
        im.msgLocalID = imsg.msgId;
        im.dict = imsg.content.dict;
    }
    for (NSInteger i = 0; i < controlMsgs.count; i++) {
        IMessage *m = [controlMsgs objectAtIndex:i];
        IMMessage *im = [cmsgs objectAtIndex:i];
        
        if (m.type == MESSAGE_REVOKE) {
            MessageRevoke *revoke = m.revokeContent;
            int64_t msgId = [[GroupMessageDB instance] getMessageId:revoke.msgid];
            if (msgId > 0) {
                [[GroupMessageDB instance] updateMessageContent:msgId content:m.rawContent];
                [[GroupMessageDB instance] removeMessageIndex:msgId];
            }
        } else if (m.type == MESSAGE_TAG) {
            MessageTag *tag = m.tagContent;
            int64_t msgId = [[GroupMessageDB instance] getMessageId:tag.msgid];
            if (msgId > 0) {
                if (tag.addTag.length > 0) {
                    [[GroupMessageDB instance] addMessage:msgId tag:tag.addTag];
                } else if (tag.deleteTag.length > 0) {
                    [[GroupMessageDB instance] removeMessage:msgId tag:tag.deleteTag];
                }
            }
        } else if (m.type == MESSAGE_READED) {
            MessageReaded *readed = m.readedContent;
            int64_t msgId = [[GroupMessageDB instance] getMessageId:readed.msgid];
            if (msgId > 0) {
                if (m.isOutgoing) {
                    int changes = [[GroupMessageDB instance] markMessageReaded:msgId];
                    im.decrementUnread = changes > 0;
                } else {
                    [[GroupMessageDB instance] addMessage:msgId reader:m.sender];
                }
            }
        }
    }
    return YES;
}

-(BOOL)handleMessageACK:(IMMessage*)msg error:(int)error {
    if (error == MSG_ACK_SUCCESS) {
        if (msg.msgLocalID > 0) {
            return [[GroupMessageDB instance] acknowledgeMessage:msg.msgLocalID];
        } else {
            MessageContent *content;
            if (msg.dict) {
                content = [IMessage fromRawDict:msg.dict];
            } else {
                content = [IMessage fromRaw:msg.content];
            }
            if (content.type == MESSAGE_REVOKE) {
                MessageRevoke *revoke = (MessageRevoke*)content;
                int64_t revokedMsgId = [[GroupMessageDB instance] getMessageId:revoke.msgid];
                if (revokedMsgId > 0) {
                    [[GroupMessageDB instance]  updateMessageContent:revokedMsgId content:msg.content];
                    [[GroupMessageDB instance] removeMessageIndex:revokedMsgId];
                }
            } else if (content.type == MESSAGE_TAG) {
                MessageTag *tag = (MessageTag*)content;
                int64_t msgId = [[GroupMessageDB instance] getMessageId:tag.msgid];
                if (msgId > 0) {
                    if (tag.addTag.length > 0) {
                        [[GroupMessageDB instance] addMessage:msgId tag:tag.addTag];
                    } else if (tag.deleteTag.length > 0) {
                        [[GroupMessageDB instance] removeMessage:msgId tag:tag.deleteTag];
                    }
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
    if (msg.msgLocalID > 0) {
        return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID];
    }
    return YES;
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
