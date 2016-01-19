//
//  CustomerOutbox.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerOutbox.h"
#import <imsdk/IMService.h>
#import "CustomerMessageDB.h"

@implementation CustomerOutbox
+(CustomerOutbox*)instance {
    static CustomerOutbox *box;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!box) {
            box = [[CustomerOutbox alloc] init];
        }
    });
    return box;
}

-(id)init {
    self = [super init];
    if (self) {
        self.isStaff = NO;
    }
    return self;
}


- (void)sendMessage:(IMessage*)msg{
    CustomerMessage *im = [[CustomerMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    im.content = msg.rawContent;
    
    if (self.isStaff) {
        im.customer = msg.receiver;
    } else {
        im.customer = msg.sender;
    }
    
    [[IMService instance] sendCustomerMessage:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    [[CustomerMessageDB instance] markMessageFailure:msg.msgLocalID uid:msg.receiver];
}

@end
