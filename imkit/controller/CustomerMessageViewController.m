//
//  CustomerMessageViewController.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageViewController.h"
#import "CustomerOutbox.h"
#import "ICustomerMessage.h"
#import "CustomerMessageDB.h"
#import "UIView+Toast.h"

#define PAGE_COUNT 10

@interface CustomerMessageViewController ()<OutboxObserver, CustomerMessageObserver, AudioDownloaderObserver>
@end

@implementation CustomerMessageViewController

- (void)dealloc {
    NSLog(@"CustomerMessageViewController dealloc");
}


- (void)viewDidLoad {
    self.messageDB = [CustomerMessageDB instance];
    self.conversationID = self.storeID;
    
    self.callEnabled = NO;
    
    [super viewDidLoad];
    if (self.peerName.length > 0) {
        self.navigationItem.title = self.peerName;
    }
}


-(void)addObserver {
    [super addObserver];
    [[CustomerOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addCustomerMessageObserver:self];
}

-(void)removeObserver {
    [super removeObserver];
    [[CustomerOutbox instance] removeBoxObserver:self];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeCustomerMessageObserver:self];
}

-(void)onBack {
    [super onBack];
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_CUSTOMER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.storeID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}
//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    if(state == STATE_CONNECTED){
        [self enableSend];
    } else {
        [self disableSend];
    }
}


-(void)onCustomerSupportMessage:(CustomerMessage*)im {
    if (self.storeID != im.storeID) {
        return;
    }
    
    NSLog(@"receive msg:%@",im);
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.customerAppID = im.customerAppID;
    m.customerID = im.customerID;
    m.storeID = im.storeID;
    m.sellerID = im.sellerID;
    m.sender = im.storeID;
    m.receiver = im.customerID;
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isSupport = YES;
    m.isOutgoing = NO;
    
    if (m.uuid.length > 0 && [self getMessageWithUUID:m.uuid]) {
        NSLog(@"receive repeat msg:%@", m.uuid);
        return;
    }
    
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    [self loadSenderInfo:m];
    [self downloadMessageContent:m];
    [self updateNotificationDesc:m];
    
    if (m.type == MESSAGE_REVOKE) {
        MessageRevoke *r = m.revokeContent;
        IMessage *revokedMsg = [self getMessageWithUUID:r.msgid];
        [self replaceMessage:revokedMsg dest:m];
    } else {
        [self insertMessage:m];
    }
}

-(void)onCustomerMessage:(CustomerMessage*)im {
    if (self.storeID != im.storeID) {
        return;
    }
    
    NSLog(@"receive msg:%@",im);
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.customerAppID = im.customerAppID;
    m.customerID = im.customerID;
    m.storeID = im.storeID;
    m.sellerID = im.sellerID;
    m.sender = im.customerID;
    m.receiver = im.storeID;
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isSupport = NO;
    
    //必定自己发出的消息
    m.isOutgoing = YES;
    m.flags = m.flags | MESSAGE_FLAG_ACK;

    
    if (m.uuid.length > 0 && [self getMessageWithUUID:m.uuid]) {
        NSLog(@"receive repeat msg:%@", m.uuid);
        return;
    }

    if (im.isSelf) {
        return;
    }
    
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    
    [self loadSenderInfo:m];
    [self downloadMessageContent:m];
    [self updateNotificationDesc:m];
    
    if (m.type == MESSAGE_REVOKE) {
        MessageRevoke *r = m.revokeContent;
        IMessage *revokedMsg = [self getMessageWithUUID:r.msgid];
        [self replaceMessage:revokedMsg dest:m];
    } else {
        [self insertMessage:m];
    }
}

//服务器ack
-(void)onCustomerMessageACK:(CustomerMessage*)cm {
    if (self.storeID != cm.storeID) {
        return;
    }
    if (cm.msgLocalID > 0) {
        IMessage *msg = [self getMessageWithID:cm.msgLocalID];
        msg.flags = msg.flags|MESSAGE_FLAG_ACK;
    } else {
        MessageContent *content = [IMessage fromRaw:cm.content];
        if (content.type == MESSAGE_REVOKE) {
            MessageRevoke *r = (MessageRevoke*)content;
            IMessage *revokedMsg = [self getMessageWithUUID:r.msgid];
            if (!revokedMsg) {
                return;
            }
            IMessage *revokeMsg = [revokedMsg copy];
            revokeMsg.content = r;
            [self updateNotificationDesc:revokeMsg];
            [self replaceMessage:revokedMsg dest:revokeMsg];
        }
    }
}

//消息发送失败
- (void)onCustomerMessageFailure:(CustomerMessage*)cm {
    if (self.storeID != cm.storeID) {
        return;
    }
    if (cm.msgLocalID > 0) {
    IMessage *msg = [self getMessageWithID:cm.msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    } else {
        MessageContent *content = [IMessage fromRaw:cm.content];
        if (content.type == MESSAGE_REVOKE) {
            [self.view makeToast:@"撤回失败" duration:0.7 position:@"bottom"];
        }
    }
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    [[CustomerOutbox instance] uploadImage:msg withImage:image];
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_MESSAGE object:msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage*)message {
    ICustomerMessage *msg = (ICustomerMessage*)message;
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[CustomerOutbox instance] uploadAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[CustomerOutbox instance] uploadImage:message];
    } else {
        CustomerMessage *im = [[CustomerMessage alloc] init];
        im.customerAppID = msg.customerAppID;
        im.customerID = msg.customerID;
        im.storeID = msg.storeID;
        im.sellerID = msg.sellerID;
        im.msgLocalID = message.msgLocalID;
        im.content = message.rawContent;
        
        [[IMService instance] sendCustomerMessageAsync:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_MESSAGE object:message userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(IMessage*)newOutMessage {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerID = self.currentUID;
    msg.customerAppID = self.appID;
    msg.storeID = self.storeID;
    msg.sellerID = self.sellerID;
    return msg;
}

@end
