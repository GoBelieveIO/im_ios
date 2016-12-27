//
//  CustomerMessageHandler.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageHandler.h"
#import "MessageDB.h"
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

-(BOOL)handleCustomerSupportMessage:(CustomerMessage*)msg {
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.customerAppID = msg.customerAppID;
    m.customerID = msg.customerID;
    m.storeID = msg.storeID;
    m.sellerID = msg.sellerID;
    m.isSupport = YES;
    m.sender = msg.customerID;
    m.receiver = msg.storeID;
    m.rawContent = msg.content;
    m.timestamp = msg.timestamp;
    BOOL r = [[CustomerMessageDB instance] insertMessage:m uid:msg.storeID];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessage:(CustomerMessage*)msg {
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.customerAppID = msg.customerAppID;
    m.customerID = msg.customerID;
    m.storeID = msg.storeID;
    m.sellerID = msg.sellerID;
    m.isSupport = NO;
    m.sender = msg.customerID;
    m.receiver = msg.storeID;
    m.rawContent = msg.content;
    m.timestamp = msg.timestamp;
    if (self.uid == msg.customerID) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    BOOL r = [[CustomerMessageDB instance] insertMessage:m uid:msg.storeID];
    if (r) {
        msg.msgLocalID = m.msgLocalID;
    }
    return r;
}

-(BOOL)handleMessageACK:(CustomerMessage*)msg {
    return [[CustomerMessageDB instance] acknowledgeMessage:msg.msgLocalID uid:msg.storeID];
}

-(BOOL)handleMessageFailure:(CustomerMessage*)msg {
    CustomerMessageDB *db = [CustomerMessageDB instance];
    return [db markMessageFailure:msg.msgLocalID uid:msg.storeID];
}

@end
