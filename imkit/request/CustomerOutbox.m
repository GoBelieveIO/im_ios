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

    im.senderAppID = msg.senderAppID;
    im.receiverAppID = msg.receiverAppID;
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgId;
    im.content = msg.rawContent;
    
    [[IMService instance] sendCustomerMessageAsync:im];
}

-(void)markMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    [[CustomerMessageDB instance] markMessageFailure:cm.msgId];
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url {
    if (msg.audioContent) {
        MessageAudioContent *audioContent = [msg.audioContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgId content:audioContent.raw];
    } else if (msg.imageContent) {
        MessageImageContent *imageContent = [msg.imageContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgId content:imageContent.raw];
    } else if (msg.fileContent) {
        MessageFileContent *fileContent = [msg.fileContent cloneWithURL:url];
        [[CustomerMessageDB instance] updateMessageContent:msg.msgId content:fileContent.raw];
    }
}

-(void)saveMessageAttachment:(IMessage*)msg url:(NSString*)url thumbnail:(NSString*)thumbnail {
    MessageVideoContent *videoContent = [msg.videoContent cloneWithURL:url thumbnail:thumbnail];
    [[CustomerMessageDB instance] updateMessageContent:msg.msgId content:videoContent.raw];
}

@end
