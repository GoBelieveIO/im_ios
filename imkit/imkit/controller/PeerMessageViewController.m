/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "PeerMessageViewController.h"
#import "FileCache.h"
#import "Outbox.h"
#import "AudioDownloader.h"
#import "DraftDB.h"
#import "IMessage.h"
#import "PeerMessageDB.h"
#import "DraftDB.h"
#import "Constants.h"

#define PAGE_COUNT 10

@interface PeerMessageViewController ()

@end

@implementation PeerMessageViewController

- (void)dealloc {
    NSLog(@"peermessageviewcontroller dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setNormalNavigationButtons];
    
    if (self.peerName.length > 0) {
        self.navigationItem.title = self.peerName;
    } else {
        IUser *u = [self.userDelegate getUser:self.peerUID];
        if (u.name.length > 0) {
            self.navigationItem.title = u.name;
        } else {
            self.navigationItem.title = u.identifier;
            [self.userDelegate asyncGetUser:self.peerUID cb:^(IUser *u) {
                if (u.name.length > 0) {
                    self.navigationItem.title = u.name;
                }
            }];
        }
    }
    
    DraftDB *db = [DraftDB instance];
    NSString *draft = [db getDraft:self.receiver];
    [self setDraft:draft];
    
    [self addObserver];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)addObserver {
    [super addObserver];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addPeerMessageObserver:self];
    [[IMService instance] addLoginPointObserver:self];
}

-(void)removeObserver {
    [super removeObserver];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removePeerMessageObserver:self];
    [[IMService instance] removeLoginPointObserver:self];
}

- (int64_t)sender {
    return self.currentUID;
}

- (int64_t)receiver {
    return self.peerUID;
}

- (BOOL)isMessageSending:(IMessage*)msg {
    return [[IMService instance] isPeerMessageSending:msg.msgLocalID];
}

- (BOOL)isInConversation:(IMessage*)msg {
   BOOL r =  (msg.sender == self.currentUID && msg.receiver == self.peerUID) ||
                (msg.receiver == self.currentUID && msg.sender == self.peerUID);
    return r;
}


-(BOOL)saveMessage:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] insertMessage:msg uid:cid];
}

-(BOOL)removeMessage:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] removeMessage:msg.msgLocalID uid:cid];

}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] markMesageListened:msg.msgLocalID uid:cid];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] eraseMessageFailure:msg.msgLocalID uid:cid];
}

-(void) setNormalNavigationButtons{
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"对话"
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(returnMainTableViewController)];
    
    self.navigationItem.leftBarButtonItem = item;
}

- (void)returnMainTableViewController {
    DraftDB *db = [DraftDB instance];
    [db setDraft:self.peerUID draft:[self getDraft]];
    
    [self removeObserver];
    [self stopPlayer];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_PEER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.peerUID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MessageObserver
- (void)onPeerMessage:(IMMessage*)im {
    if (im.sender != self.peerUID && im.receiver != self.peerUID) {
        return;
    }
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    
    NSLog(@"receive msg:%@",im);
    
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    
    if (self.textMode && m.type != MESSAGE_TEXT) {
        return;
    }
    
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
    [self reloadMessage:msgLocalID];
}

- (void)onPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    [self reloadMessage:msgLocalID];
}

//对方正在输入
- (void)onPeerInputing:(int64_t)uid {
    if (uid != self.peerUID) {
        return;
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

-(void)onLoginPoint:(LoginPoint*)lp {
    NSLog(@"login point:%@, platform id:%d", lp.deviceID, lp.platformID);
}

- (void)loadConversationData {
    int count = 0;
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newMessageIterator: self.peerUID];
    IMessage *msg = [iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.type == MESSAGE_TEXT) {
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        } else {
            if (msg.type == MESSAGE_ATTACHMENT) {
                MessageAttachmentContent *att = msg.attachmentContent;
                [self.attachments setObject:att
                                     forKey:[NSNumber numberWithInt:att.msgLocalID]];
            } else {
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        }
        msg = [iterator next];
    }
    
    [self checkMessageFailureFlag:self.messages count:count];
    [self downloadMessageContent:self.messages count:count];
    
    [self initTableViewData];
}


- (void)loadEarlierData {
    
    IMessage *last = [self.messages firstObject];
    if (last == nil) {
        return;
    }
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newMessageIterator:self.peerUID last:last.msgLocalID];
    
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    if (count == 0) {
        return;
    }
    
    [self checkMessageFailureFlag:self.messages count:count];
    [self downloadMessageContent:self.messages count:count];
    
    [self initTableViewData];
    
    [self.tableView reloadData];
    
    int section = 0;
    int row = 0;
    for (NSArray *block in self.messageArray) {
        if (count < block.count) {
            row = count;
            break;
        }
        count -= [block count];
        section++;
    }
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    [[Outbox instance] uploadImage:msg withImage:image];
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_MESSAGE object:msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage*)message {
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[Outbox instance] uploadAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[Outbox instance] uploadImage:message];
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
