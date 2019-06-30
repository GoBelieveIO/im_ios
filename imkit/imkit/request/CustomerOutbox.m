//
//  CustomerOutbox.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerOutbox.h"
#import "IMService.h"
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


- (void)sendMessage:(IMessage*)m{
    ICustomerMessage *msg = (ICustomerMessage*)m;
    CustomerMessage *im = [[CustomerMessage alloc] init];

    im.customerAppID = msg.customerAppID;
    im.customerID = msg.customerID;
    im.storeID = msg.storeID;
    im.sellerID = msg.sellerID;
    im.msgLocalID = msg.msgLocalID;
    im.content = msg.rawContent;
    
    [[IMService instance] sendCustomerMessageAsync:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    [[CustomerMessageDB instance] markMessageFailure:cm.msgLocalID];
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
    if (msg.audioContent) {
        MessageAudioContent *audioContent = [msg.audioContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgLocalID content:audioContent.raw];
    } else if (msg.imageContent) {
        MessageImageContent *imageContent = [msg.imageContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgLocalID content:imageContent.raw];
    }
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url thumbnail:(NSString*)thumbnail {
    MessageVideoContent *videoContent = [msg.videoContent cloneWithURL:url thumbnail:thumbnail];
    [[CustomerMessageDB instance] updateMessageContent:msg.msgLocalID content:videoContent.raw];
}

@end
