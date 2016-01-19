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
        
    }
    return self;
}


- (void)sendMessage:(IMessage*)msg{
    
    IMMessage *im = [[IMMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    
    im.content = msg.rawContent;
    
    [[IMService instance] sendCustomerMessage:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    [[CustomerMessageDB instance] markMessageFailure:msg.msgLocalID uid:msg.receiver];
}

@end
