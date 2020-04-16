/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageViewController.h"
#import "FileCache.h"
#import "AudioDownloader.h"
#import "IMessage.h"
#import "PeerMessageDB.h"
#import "PeerOutbox.h"
#import "UIImage+Resize.h"
#import "SDImageCache.h"
#import "PeerMessageDB.h"
#import "EPeerMessageDB.h"

#import "UIView+Toast.h"

@interface PeerMessageViewController ()
@end

@implementation PeerMessageViewController
- (void)dealloc {
    NSLog(@"peermessageviewcontroller dealloc");
}

- (void)viewDidLoad {
    if (self.secret) {
        self.messageDB = [EPeerMessageDB instance];
    } else {
        self.messageDB = [PeerMessageDB instance];
    }
    self.conversationID = self.peerUID;

    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    if (self.peerName.length > 0) {
        if (self.secret) {
            self.navigationItem.title = [NSString stringWithFormat:@"%@(密)", self.peerName];
        } else {
            self.navigationItem.title = self.peerName;
        }
    } else {
        IUser *u = [self getUser:self.peerUID];
        if (u.name.length > 0) {
            if (self.secret) {
                self.navigationItem.title = [NSString stringWithFormat:@"%@(密)", u.name];
            }
        } else {
            self.navigationItem.title = u.identifier;
            [self asyncGetUser:self.peerUID cb:^(IUser *u) {
                if (u.name.length > 0) {
                    self.navigationItem.title = [NSString stringWithFormat:@"%@(密)", u.name];
                }
            }];
        }
    }
}


-(void)addObserver {
    [super addObserver];
    [[PeerOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addPeerMessageObserver:self];
}

-(void)removeObserver {
    [super removeObserver];
    [[PeerOutbox instance] removeBoxObserver:self];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removePeerMessageObserver:self];
}

-(void)onBack {
    [super onBack];
    if (self.secret) {
        NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_PEER_SECRET_NEW_MESSAGE
                                                                     object:[NSNumber numberWithLongLong:self.peerUID]
                                                                   userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } else {
        NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_PEER_NEW_MESSAGE
                                                                     object:[NSNumber numberWithLongLong:self.peerUID]
                                                                   userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

-(void)handleP2PSession:(IMessage*)msg {
    
}


#pragma mark - MessageObserver
- (void)onPeerMessage:(IMMessage*)im {
    if (im.sender != self.peerUID && im.receiver != self.peerUID) {
        return;
    }
    if (self.secret) {
        return;
    }
    NSLog(@"receive msg:%@",im);
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.secret = NO;
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    IMessage *mm = [self getMessageWithUUID:m.uuid];
    //判断消息是否重复
    if (mm) {
        NSLog(@"receive repeat peer msg:%@", m.uuid);
        //清空消息失败标志位
        if (im.sender == self.currentUID) {
            int flags = mm.flags;
            flags = flags & ~MESSAGE_FLAG_FAILURE;
            flags = flags | MESSAGE_FLAG_ACK;
            mm.flags = flags;
        }
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

-(void)onPeerSecretMessage:(IMMessage*)im {
    if (im.sender != self.peerUID && im.receiver != self.peerUID) {
        return;
    }
    if (!self.secret) {
        return;
    }
    NSLog(@"receive msg:%@",im);
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.secret = YES;
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentUID);
    if (im.sender == self.currentUID) {
        m.flags = m.flags | MESSAGE_FLAG_ACK;
    }
    //判断消息是否重复
    if (m.uuid.length > 0 && [self getMessageWithUUID:m.uuid]) {
        return;
    }
    
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    
    if (m.type == MESSAGE_P2P_SESSION) {
        [self handleP2PSession:m];
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
- (void)onPeerMessageACK:(IMMessage*)im error:(int)error {
    int msgLocalID = im.msgLocalID;
    int64_t uid = im.receiver;
    
    if (uid != self.peerUID) {
        return;
    }
    
    if (error == MSG_ACK_SUCCESS) {
        if (im.msgLocalID > 0) {
            IMessage *msg = [self getMessageWithID:msgLocalID];
            msg.flags = msg.flags|MESSAGE_FLAG_ACK;
        } else {
            MessageContent *content = [IMessage fromRaw:im.plainContent];
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
    } else {
        if (msgLocalID > 0) {
            IMessage *msg = [self getMessageWithID:msgLocalID];
            msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        } else {
            MessageContent *content = [IMessage fromRaw:im.content];
            if (content.type == MESSAGE_REVOKE) {
                [self.view makeToast:@"撤回失败" duration:0.7 position:@"bottom"];
            }
        }
        
        MessageACK *ack = [[MessageACK alloc] initWithError:error];
        IMessage *ackMsg = [[IMessage alloc] init];
        ackMsg.sender = 0;
        ackMsg.receiver = im.sender;
        ackMsg.timestamp = (int)time(NULL);
        ackMsg.content = ack;
        [self updateNotificationDesc:ackMsg];
        [self insertMessage:ackMsg];
    }
}

- (void)onPeerMessageFailure:(IMMessage*)im {
    int msgLocalID = im.msgLocalID;
    int64_t uid = im.receiver;
    
    if (uid != self.peerUID) {
        return;
    }
    if (msgLocalID > 0) {
        IMessage *msg = [self getMessageWithID:msgLocalID];
        msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    } else {
        MessageContent *content = [IMessage fromRaw:im.content];
        if (content.type == MESSAGE_REVOKE) {
            [self.view makeToast:@"撤回失败" duration:0.7 position:@"bottom"];
        }
    }
}


//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state{
    if(state == STATE_CONNECTED){
        [self enableSend];
    } else {
        [self disableSend];
    }
}


- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    if (self.secret) {
        [[PeerOutbox instance] uploadSecretImage:msg withImage:image];
    } else {
        [[PeerOutbox instance] uploadImage:msg withImage:image];
    }
    if (self.secret) {
        NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_SECRET_MESSAGE object:msg userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } else {
        NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_MESSAGE object:msg userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }
}

- (BOOL)encrypt:(IMMessage*)msg {
    return NO;
}

- (void)sendMessage:(IMessage*)message {
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        if (self.secret) {
            [[PeerOutbox instance] uploadSecretAudio:message];
        } else {
            [[PeerOutbox instance] uploadAudio:message];
        }
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        if (self.secret) {
            [[PeerOutbox instance] uploadSecretImage:message];
        } else {
            [[PeerOutbox instance] uploadImage:message];
        }
    } else if (message.type == MESSAGE_VIDEO) {
        message.uploading = YES;
        if (self.secret) {
            [[PeerOutbox instance] uploadSecretVideo:message];
        } else {
            [[PeerOutbox instance] uploadVideo:message];
        }
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgLocalID;
        im.isText = YES;
        im.content = message.rawContent;
        im.plainContent = message.rawContent;
        
        BOOL r = YES;
        if (self.secret) {
            r = [self encrypt:im];
        }
        if (r) {
            [[IMService instance] sendPeerMessageAsync:im];
        }
    }
    
    if (self.secret) {
        NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_SECRET_MESSAGE object:message userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    } else {
        NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_MESSAGE object:message userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotification:notification];
    }

}

-(IMessage*)newOutMessage {
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = self.currentUID;
    msg.receiver = self.peerUID;
    msg.secret = self.secret;
    return msg;
}

@end
