//
//  ICustomerMessage.m
//  gobelieve
//
//  Created by houxh on 2018/5/26.
//

#import "ICustomerMessage.h"

@implementation ICustomerMessage
- (instancetype)copyWithZone:(NSZone *)zone {
    ICustomerMessage *m = [[[self class] allocWithZone:zone] init];
    m.msgId = self.msgId;
    m.secret = self.secret;
    m.flags = self.flags;
    m.sender = self.sender;
    m.receiver = self.receiver;

    m.senderAppID = self.senderAppID;
    m.receiverAppID = self.receiverAppID;
    
    m.timestamp = self.timestamp;
    m.content = self.content;
    m.isOutgoing = self.isOutgoing;
    m.senderInfo = self.senderInfo;
    return m;
}


@end
