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
#import "EPeerMessageDB.h"

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


    if (im.isSelf) {
        NSAssert(im.sender == self.uid, @"");
        [self repairFailureMessage:m.uuid];
        return true;
    } else if (m.type == MESSAGE_REVOKE) {
        BOOL r = YES;
        MessageRevoke *revoke = m.revokeContent;
        int msgId = [[PeerMessageDB instance] getMessageId:revoke.msgid];
        if (msgId > 0) {
            r = [[PeerMessageDB instance] updateMessageContent:msgId content:msg.content];
            [[PeerMessageDB instance] removeMessageIndex:msgId uid:pid];
        }
        return r;
    } else {
        BOOL r = [[PeerMessageDB instance] insertMessage:m uid:pid];
        if (r) {
            msg.msgLocalID = m.msgLocalID;
        }
        return r;
    }
}

-(BOOL)handleMessageACK:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    if (msg.msgLocalID > 0) {
        return [[PeerMessageDB instance] acknowledgeMessage:msg.msgLocalID uid:pid];
    } else {
        MessageContent *content = [IMessage fromRaw:msg.plainContent];
        if (content.type == MESSAGE_REVOKE) {
            MessageRevoke *revoke = (MessageRevoke*)content;
            int revokedMsgId = [[PeerMessageDB instance] getMessageId:revoke.msgid];
            if (revokedMsgId > 0) {
                [[PeerMessageDB instance]  updateMessageContent:revokedMsgId content:content.raw];
                [[PeerMessageDB instance] removeMessageIndex:revokedMsgId uid:pid];
            }
        }
        return YES;
    }
}

-(BOOL)handleMessageFailure:(IMMessage*)msg {
    int64_t pid = self.uid == msg.sender ? msg.receiver : msg.sender;
    PeerMessageDB *db = [PeerMessageDB instance];
    return [db markMessageFailure:msg.msgLocalID uid:pid];
}

@end
