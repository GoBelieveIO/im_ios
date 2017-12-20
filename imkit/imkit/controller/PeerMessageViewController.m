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
#import "DraftDB.h"
#import "IMessage.h"
#import "PeerMessageDB.h"
#import "DraftDB.h"
#import "PeerOutbox.h"
#import "UIImage+Resize.h"
#import "SDImageCache.h"
#import "IPeerMessageDB.h"


@interface PeerMessageViewController ()
@end

@implementation PeerMessageViewController
- (void)dealloc {
    NSLog(@"peermessageviewcontroller dealloc");
}

- (void)viewDidLoad {
    IPeerMessageDB *db = [[IPeerMessageDB alloc] init];
    db.currentUID = self.currentUID;
    db.peerUID = self.peerUID;
    self.messageDB = db;
    
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    if (self.peerName.length > 0) {
        self.navigationItem.title = self.peerName;
    } else {
        IUser *u = [self getUser:self.peerUID];
        if (u.name.length > 0) {
            self.navigationItem.title = u.name;
        } else {
            self.navigationItem.title = u.identifier;
            [self asyncGetUser:self.peerUID cb:^(IUser *u) {
                if (u.name.length > 0) {
                    self.navigationItem.title = u.name;
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
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_PEER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.peerUID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

#pragma mark - MessageObserver
- (void)onPeerMessage:(IMMessage*)im {
    if (im.sender != self.peerUID && im.receiver != self.peerUID) {
        return;
    }
    NSLog(@"receive msg:%@",im);
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
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
    
    [self loadSenderInfo:m];
    [self downloadMessageContent:m];

    [self insertMessage:m];
}

//服务器ack
- (void)onPeerMessageACK:(int)msgLocalID uid:(int64_t)uid {
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
}

- (void)onPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
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
    [[PeerOutbox instance] uploadImage:msg withImage:image];
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_MESSAGE object:msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage*)message {
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[PeerOutbox instance] uploadAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[PeerOutbox instance] uploadImage:message];
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgLocalID;
        im.content = message.rawContent;
        [[IMService instance] sendPeerMessage:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_MESSAGE object:message userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

@end
