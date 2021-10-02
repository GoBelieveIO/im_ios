//
//  CustomerMessageHandler.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageHandler.h"
#import "Message.h"
#import "CustomerMessageDB.h"

@implementation CustomerMessageHandler
+(CustomerMessageHandler*)instance {
    static CustomerMessageHandler *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[CustomerMessageHandler alloc] init];
        }
    });
    return m;
}


//将发送失败的消息置为成功
-(void)repairFailureMessage:(NSString*)uuid {
    CustomerMessageDB *db = [CustomerMessageDB instance];
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

-(BOOL)handleMessage:(CustomerMessage*)msg {
    int64_t peerAppId;
    int64_t peer;
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.senderAppID = msg.senderAppID;
    m.sender = msg.sender;
    m.receiverAppID = msg.receiverAppID;
    m.receiver = msg.receiver;
    m.rawContent = msg.content;
    m.timestamp = msg.timestamp;
    if (self.uid == msg.sender && self.appid == msg.senderAppID) {
        peerAppId = msg.receiverAppID;
        peer = msg.receiver;
        m.flags = m.flags | MESSAGE_FLAG_ACK;
        m.isOutgoing = YES;
    } else {
        peerAppId = msg.senderAppID;
        peer = msg.sender;
        m.isOutgoing = NO;
    }
    
    if (msg.isSelf) {
        [self repairFailureMessage:m.uuid];
        return YES;
    } else if (m.type == MESSAGE_REVOKE) {
        BOOL r = YES;
        MessageRevoke *revoke = m.revokeContent;
        int64_t msgId = [[CustomerMessageDB instance] getMessageId:revoke.msgid];
        if (msgId > 0) {
            r = [[CustomerMessageDB instance] updateMessageContent:msgId content:msg.content];
            [[CustomerMessageDB instance] removeMessageIndex:msgId];
        }
        return r;
    } else {
        BOOL r = [[CustomerMessageDB instance] insertMessage:m uid:peer appid:peerAppId];
        if (r) {
            msg.msgLocalID = m.msgId;
        }
        return r;
    }
}

-(BOOL)handleMessageACK:(CustomerMessage*)msg {
    if (msg.msgLocalID > 0) {
        return [[CustomerMessageDB instance] acknowledgeMessage:msg.msgLocalID];
    } else {
        MessageContent *content = [IMessage fromRaw:msg.content];
        if (content.type == MESSAGE_REVOKE) {
            MessageRevoke *revoke = (MessageRevoke*)content;
            int64_t revokedMsgId = [[CustomerMessageDB instance] getMessageId:revoke.msgid];
            if (revokedMsgId > 0) {
                [[CustomerMessageDB instance]  updateMessageContent:revokedMsgId content:msg.content];
                [[CustomerMessageDB instance] removeMessageIndex:revokedMsgId];
            }
        }
        return YES;
    }
}

-(BOOL)handleMessageFailure:(CustomerMessage*)msg {
    CustomerMessageDB *db = [CustomerMessageDB instance];
    return [db markMessageFailure:msg.msgLocalID];
}

@end
