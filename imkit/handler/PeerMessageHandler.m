/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageHandler.h"
#import "PeerMessageDB.h"
#import "GroupMessageDB.h"

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


//将发送失败的消息置为成功
-(void)repairFailureMessage:(NSString*)uuid {
    PeerMessageDB *db = [PeerMessageDB instance];
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


-(BOOL)handleMessage:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    IMessage *m = [[IMessage alloc] init];
    m.sender = msg.sender;
    m.receiver = msg.receiver;
    m.rawContent = msg.content;
    m.timestamp = msg.timestamp;
    
    if (self.uid == msg.sender) {
        m.flags = m.flags|MESSAGE_FLAG_ACK;
        m.isOutgoing = YES;
    }
    //improve json searialize performance
    msg.dict = m.content.dict;
    
    if (m.groupId > 0) {
        msg.groupID = m.groupId;
        return true;
    }
    
    if (msg.isSelf) {
        NSAssert(msg.sender == self.uid, @"");
        [self repairFailureMessage:m.uuid];
        return true;
    } else if (m.type == MESSAGE_REVOKE) {
        BOOL r = YES;
        MessageRevoke *revoke = m.revokeContent;
        int64_t msgId = [[PeerMessageDB instance] getMessageId:revoke.msgid];
        if (msgId > 0) {
            r = [[PeerMessageDB instance] updateMessageContent:msgId content:msg.content];
            [[PeerMessageDB instance] removeMessageIndex:msgId];
        }
        return r;
    } else if (m.type == MESSAGE_READED) {
        MessageReaded *readed = m.readedContent;
        int64_t msgId = [[PeerMessageDB instance] getMessageId:readed.msgid];
        if (msgId > 0) {
            int changes = [[PeerMessageDB instance] markMessageReaded:msgId];
            msg.decrementUnread = changes > 0;
        }
        return YES;
    } else {
        BOOL r = [[PeerMessageDB instance] insertMessage:m uid:pid];
        if (r) {
            msg.msgLocalID = m.msgId;
            msg.dict = m.content.dict;
        }
        return r;
    }
}

-(BOOL)handleMessageACK:(IMMessage*)msg error:(int)error {
    if (error == MSG_ACK_SUCCESS) {
        if (msg.msgLocalID > 0) {
            return [[PeerMessageDB instance] acknowledgeMessage:msg.msgLocalID];
        } else {
            MessageContent *content = nil;
            if (msg.dict) {
                content = [IMessage fromRawDict:msg.dict];
            } else {
                content = [IMessage fromRaw:msg.content];
            }

            if (content.type == MESSAGE_REVOKE) {
                MessageRevoke *revoke = (MessageRevoke*)content;
                int64_t revokedMsgId = [[PeerMessageDB instance] getMessageId:revoke.msgid];
                if (revokedMsgId > 0) {
                    [[PeerMessageDB instance] updateMessageContent:revokedMsgId content:msg.content];
                    [[PeerMessageDB instance] removeMessageIndex:revokedMsgId];
                }
            } else if (content.type == MESSAGE_READED) {
                MessageReaded *readed = (MessageReaded*)content;
                if (readed.groupId > 0) {
                    int64_t msgId = [[GroupMessageDB instance] getMessageId:readed.msgid];
                    if (msgId > 0) {
                        [[GroupMessageDB instance] markMessageReaded:msgId];
                    }
                } else {
                    int64_t msgId = [[PeerMessageDB instance] getMessageId:readed.msgid];
                    if (msgId > 0) {
                        [[PeerMessageDB instance] markMessageReaded:msgId];
                    }
                }
            }
            return YES;
        }
    } else {
        PeerMessageDB *db = [PeerMessageDB instance];
        
        MessageACK *ack = [[MessageACK alloc] initWithError:error];
        IMessage *ackMsg = [[IMessage alloc] init];
        ackMsg.sender = 0;
        ackMsg.receiver = msg.sender;
        ackMsg.timestamp = (int)time(NULL);
        ackMsg.content = ack;
        [db insertMessage:ackMsg uid:msg.receiver];
        
        if (msg.msgLocalID > 0) {
            return [db markMessageFailure:msg.msgLocalID];
        }
        return true;
    }
}

-(BOOL)handleMessageFailure:(IMMessage*)msg {
    PeerMessageDB *db = [PeerMessageDB instance];
    return [db markMessageFailure:msg.msgLocalID];
}

@end
