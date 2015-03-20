//
//  PeerMessageViewController.m
//  imkit
//
//  Created by houxh on 15/3/18.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

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
    self.navigationItem.title = self.peerName;
    
    DraftDB *db = [DraftDB instance];
    NSString *draft = [db getDraft:self.receiver];
    [self setDraft:draft];
    
    [self addObserver];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (int64_t)sender {
    return self.currentUID;
}

- (int64_t)receiver {
    return self.peerUID;
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
    return [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:cid];
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
    
    if (self.messages.count > 0) {
        
        IMessage *msg = [self.messages lastObject];
        
        if (msg.sender == self.currentUID) {
            NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_PEER_MESSAGE object: msg userInfo:nil];
            
            [[NSNotificationCenter defaultCenter] postNotification:notification];
        }
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_PEER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.peerUID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
    

    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - MessageObserver
- (void)onPeerMessage:(IMMessage*)im {
    if (im.sender != self.peerUID) {
        return;
    }
    [[self class] playMessageReceivedSound];
    
    NSLog(@"receive msg:%@",im);
    
    IMessage *m = [[IMessage alloc] init];
    m.sender = im.sender;
    m.receiver = im.receiver;
    m.msgLocalID = im.msgLocalID;
    MessageContent *content = [[MessageContent alloc] init];
    content.raw = im.content;
    m.content = content;
    m.timestamp = (int)time(NULL);
    
    if (self.textMode && m.content.type != MESSAGE_TEXT) {
        return;
    }
    
    if (m.content.type == MESSAGE_AUDIO) {
        AudioDownloader *downloader = [AudioDownloader instance];
        [downloader downloadAudio:m];
    }
    
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

//接受方ack
- (void)onPeerMessageRemoteACK:(int)msgLocalID uid:(int64_t)uid {
    if (uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_PEER_ACK;
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


- (void)loadConversationData {
    int count = 0;
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newMessageIterator: self.peerUID];
    IMessage *msg = [iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.content.type == MESSAGE_TEXT) {
                [self.messages insertObject:msg atIndex:0];
                if (++count >= PAGE_COUNT) {
                    break;
                }
            }
        } else {
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    
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
        [self.messages insertObject:msg atIndex:0];
        if (++count >= PAGE_COUNT) {
            break;
        }
        msg = [iterator next];
    }
    if (count == 0) {
        return;
    }
    
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

- (void)sendMessage:(IMessage*)msg {
    IMMessage *im = [[IMMessage alloc] init];
    im.sender = msg.sender;
    im.receiver = msg.receiver;
    im.msgLocalID = msg.msgLocalID;
    im.content = msg.content.raw;
    [[IMService instance] sendPeerMessage:im];
}


@end
