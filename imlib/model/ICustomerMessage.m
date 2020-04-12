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
    m.msgLocalID = self.msgLocalID;
    m.secret = self.secret;
    m.flags = self.flags;
    m.sender = self.sender;
    m.receiver = self.receiver;

    m.customerID = self.customerID;
    m.customerAppID = self.customerAppID;
    m.sellerID = self.sellerID;
    m.storeID = self.storeID;
    
    m.timestamp = self.timestamp;
    m.content = self.content;
    m.isOutgoing = self.isOutgoing;
    m.senderInfo = self.senderInfo;
    return m;
}


-(int64_t)sender {
    if (self.isSupport) {
        return self.storeID;
    } else {
        return self.customerID;
    }
}

-(int64_t)receiver {
    if (self.isSupport) {
        return self.customerID;
    } else {
        return self.storeID;
    }
}
@end
