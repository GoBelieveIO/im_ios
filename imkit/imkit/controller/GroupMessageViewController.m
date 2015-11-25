/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "GroupMessageViewController.h"

#import "FileCache.h"
#import "Outbox.h"
#import "AudioDownloader.h"
#import "DraftDB.h"
#import "IMessage.h"
#import "GroupMessageDB.h"
#import "DraftDB.h"
#import "Constants.h"

#define PAGE_COUNT 10

@interface GroupMessageViewController ()

@end

@implementation GroupMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setNormalNavigationButtons];
    self.navigationItem.title = self.groupName;
    
    DraftDB *db = [DraftDB instance];
    NSString *draft = [db getGroupDraft:self.groupID];
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
    [[IMService instance] addGroupMessageObserver:self];
    [[IMService instance] addLoginPointObserver:self];
}

-(void)removeObserver {
    [super removeObserver];
    [[IMService instance] removeGroupMessageObserver:self];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeLoginPointObserver:self];
}

- (int64_t)sender {
    return self.currentUID;
}

- (int64_t)receiver {
    return self.groupID;
}

- (BOOL)isMessageSending:(IMessage*)msg {
    return [[IMService instance] isGroupMessageSending:msg.msgLocalID];
}

- (BOOL)isInConversation:(IMessage*)msg {
    BOOL r = (msg.receiver == self.groupID);
    return r;
}

-(BOOL)saveMessage:(IMessage*)msg {
    return [[GroupMessageDB instance] insertMessage:msg];
}

-(BOOL)removeMessage:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] removeMessage:msg.msgLocalID gid:cid];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID gid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] markMesageListened:msg.msgLocalID gid:cid];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    int64_t cid = msg.receiver;
    return [[GroupMessageDB instance] markMessageFailure:msg.msgLocalID gid:cid];
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
    [db setGroupDraft:self.groupID draft:[self getDraft]];
    
    [self removeObserver];
    [self stopPlayer];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_GROUP_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.groupID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    [self.navigationController popViewControllerAnimated:YES];
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


#pragma mark - MessageObserver
-(void)onGroupMessage:(IMMessage*)im {
    if (im.receiver != self.groupID) {
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
    
    if (self.textMode && m.type != MESSAGE_TEXT && m.type != MESSAGE_GROUP_NOTIFICATION) {
        return;
    }
    
    [self downloadMessageContent:m];
    
    [self insertMessage:m];
}

-(void)onGroupMessageACK:(int)msgLocalID gid:(int64_t)gid {
    if (gid != self.groupID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
    [self reloadMessage:msgLocalID];
}

-(void)onGroupMessageFailure:(int)msgLocalID gid:(int64_t)gid {
    if (gid != self.groupID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
    [self reloadMessage:msgLocalID];
}


-(void)onGroupNotification:(NSString *)text {
    MessageNotificationContent *notification = [[MessageNotificationContent alloc] initWithNotification:text];
    int64_t groupID = notification.groupID;
    if (groupID != self.groupID) {
        return;
    }
    
    IMessage *msg = [[IMessage alloc] init];
    msg.sender = 0;
    msg.receiver = groupID;
    if (notification.timestamp > 0) {
        msg.timestamp = notification.timestamp;
    } else {
        msg.timestamp = (int)time(NULL);
    }
    msg.rawContent = notification.raw;
    
    //update notification description
    [self downloadMessageContent:msg];
    
    [self insertMessage:msg];
}


- (void)loadConversationData {
    int count = 0;
    id<IMessageIterator> iterator =  [[GroupMessageDB instance] newMessageIterator: self.groupID];
    IMessage *msg = [iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.type == MESSAGE_TEXT || msg.type == MESSAGE_GROUP_NOTIFICATION) {
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
    id<IMessageIterator> iterator =  [[GroupMessageDB instance] newMessageIterator:self.groupID last:last.msgLocalID];
    
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (self.textMode) {
            if (msg.type == MESSAGE_TEXT || msg.type == MESSAGE_GROUP_NOTIFICATION) {
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

- (void)sendMessage:(IMessage*)message {
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[Outbox instance] uploadGroupAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[Outbox instance] uploadGroupImage:message];
    } else {
        IMMessage *im = [[IMMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgLocalID;
        im.content = message.rawContent;
        [[IMService instance] sendGroupMessage:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_GROUP_MESSAGE
                                                                 object:message userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    [[Outbox instance] uploadGroupImage:msg withImage:image];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_GROUP_MESSAGE
                                                                 object:msg userInfo:nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}


@end
