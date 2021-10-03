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
#import "IMHttpAPI.h"
#import <Toast/UIView+Toast.h>

@interface CustomerMessageViewController ()<OutboxObserver, CustomerMessageObserver, AudioDownloaderObserver>
@end

@implementation CustomerMessageViewController

- (void)dealloc {
    NSLog(@"CustomerMessageViewController dealloc");
}


- (void)viewDidLoad {
    self.messageDB = [CustomerMessageDB instance];
    self.callEnabled = NO;
    self.isShowReaded = NO;
    self.isShowUserName = YES;
    
    [super viewDidLoad];
    if (self.storeName.length > 0) {
        self.navigationItem.title = self.storeName;
    }
    
    if (self.peerAppID == 0 && self.peerUID == 0) {
        [self disableSend];
        [IMHttpAPI getCustomerSupporter:self.storeID success:^(NSDictionary *resp) {
            NSLog(@"resp:%@", resp);
            self.peerAppID = [[resp objectForKey:@"appid"] longLongValue];
            self.peerUID = [[resp objectForKey:@"id"] longLongValue];
            self.peerName = [resp objectForKey:@"name"];
            self.peerAppName = [resp objectForKey:@"appname"];
            
            if ([IMService instance].connectState == STATE_CONNECTED) {
                [self enableSend];
            }
        } fail:^(NSString *err) {
            NSLog(@"get customer supporter err:%@", err);
        }];
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
        if (self.peerAppID && self.peerUID) {
            [self enableSend];
        }
    } else {
        [self disableSend];
    }
}

-(void)onCustomerMessage:(CustomerMessage*)im {
    NSLog(@"receive msg:%@",im);
    ICustomerMessage *m = [[ICustomerMessage alloc] init];
    m.senderAppID = im.senderAppID;
    m.sender = im.sender;
    m.receiverAppID = im.receiverAppID;
    m.receiver = im.receiver;
    m.msgId = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    
    
    if (m.senderAppID == self.appid && m.sender == self.currentUID) {
        m.isOutgoing = YES;
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    } else {
        m.isOutgoing = NO;
    }
    
    if (m.uuid.length > 0 && [self getMessageWithUUID:m.uuid]) {
        NSLog(@"receive repeat msg:%@", m.uuid);
        return;
    }

    if (im.isSelf) {
        return;
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

-(BOOL)getMessageOutgoing:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return (cm.senderAppID == self.appid && cm.sender == self.currentUID);
}

-(id<IMessageIterator>)newMessageIterator {
    return [self.messageDB newMessageIterator: self.storeID];
}

//下拉刷新
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)messageID {
    return [self.messageDB newForwardMessageIterator:self.storeID messageID:messageID];
}

//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)messageID {
    return [self.messageDB newBackwardMessageIterator:self.storeID messageID:messageID];
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
        im.senderAppID = msg.senderAppID;
        im.sender = msg.sender;
        im.receiverAppID = msg.receiverAppID;
        im.receiver = msg.receiver;
        im.msgLocalID = message.msgId;
        im.content = message.rawContent;
        
        [[IMService instance] sendCustomerMessageAsync:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_MESSAGE object:message userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

-(IMessage*)newOutMessage:(MessageContent*)content {
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.senderAppID = self.appid;
    msg.sender = self.currentUID;
    msg.receiverAppID = self.peerAppID;
    msg.receiver = self.peerUID;
    msg.uuid = [[NSUUID UUID] UUIDString];

    
    content.name = self.name;
    content.appName = self.appName;
    content.storeId = self.storeID;
    content.storeName = self.storeName;
    content.sessionId = self.sessionID;
    msg.content = content;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    [msg generateRaw];
    return msg;
}

- (void)loadSenderInfo:(IMessage*)msg {
    IUser *u = [[IUser alloc] init];
    u.name = msg.content.name;
    if (u.name.length == 0) {
        u.name = [NSString stringWithFormat:@"%lld", msg.sender];
    }
    msg.senderInfo = u;
}
@end
