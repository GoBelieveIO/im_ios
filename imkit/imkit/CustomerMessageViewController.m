//
//  CustomerMessageViewController.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageViewController.h"
#import "CustomerOutbox.h"
#import "CustomerMessageDB.h"

#define PAGE_COUNT 10

@interface CustomerMessageViewController ()<OutboxObserver, CustomerMessageObserver>
@property(nonatomic) BOOL isStaff;
@end

@implementation CustomerMessageViewController

- (void)dealloc {
    NSLog(@"CustomerMessageViewController dealloc");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"对话"
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(returnMainTableViewController)];
    
    self.navigationItem.leftBarButtonItem = item;

    
    
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

    
    [self addObserver];
    
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

- (int64_t)sender {
    return self.currentUID;
}

- (int64_t)receiver {
    return self.peerUID;
}

- (BOOL)isMessageSending:(IMessage*)msg {
    return [[IMService instance] isCustomerMessageSending:msg.receiver id:msg.msgLocalID];
}

- (BOOL)isInConversation:(IMessage*)msg {
    if (self.isStaff) {
        return msg.receiver == self.peerUID;
    } else {
        return YES;
    }
}

- (void)returnMainTableViewController {
    [self removeObserver];
    [self stopPlayer];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_CUSTOMER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.peerUID]
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


- (void)loadConversationData {
    int count = 0;
    id<IMessageIterator> iterator =  [[CustomerMessageDB instance] newMessageIterator:self.peerUID];
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
    
    self.isStaff = (self.peerUID != 0);
    if (self.peerUID == 0) {
        for (NSInteger i = self.messages.count - 1 ; i >= 0; i--) {
            IMessage *msg = [self.messages objectAtIndex:i];
            if (msg.sender != self.currentUID) {
                self.peerUID = msg.sender;
            }
        }
    }

    [self downloadMessageContent:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    
    [self initTableViewData];
}


- (void)loadEarlierData {
    //找出第一条实体消息
    IMessage *last = nil;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.type != MESSAGE_TIME_BASE) {
            last = m;
            break;
        }
    }
    if (last == nil) {
        return;
    }
    
    id<IMessageIterator> iterator =  [[CustomerMessageDB instance] newMessageIterator:self.peerUID last:last.msgLocalID];
    
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
    
    [self downloadMessageContent:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    
    [self initTableViewData];
    
    [self.tableView reloadData];
    
    int c = 0;
    int section = 0;
    int row = 0;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        row++;
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.type == MESSAGE_TIME_BASE) {
            continue;
        }
        c++;
        if (c >= count) {
            break;
        }
    }
    NSLog(@"scroll to row:%d section:%d", row, section);
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

-(void)checkMessageFailureFlag:(IMessage*)msg {
    if ([self isMessageOutgoing:msg]) {
        if (msg.type == MESSAGE_AUDIO) {
            msg.uploading = [[CustomerOutbox instance] isUploading:msg];
        } else if (msg.type == MESSAGE_IMAGE) {
            msg.uploading = [[CustomerOutbox instance] isUploading:msg];
        }
        
        //消息发送过程中，程序异常关闭
        if (!msg.isACK && !msg.uploading &&
            !msg.isFailure && ![self isMessageSending:msg]) {
            [self markMessageFailure:msg];
            msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        }
    }
}

-(void)checkMessageFailureFlag:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkMessageFailureFlag:msg];
    }
}


-(BOOL)saveMessage:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[CustomerMessageDB instance] insertMessage:msg uid:cid];
}

-(BOOL)removeMessage:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[CustomerMessageDB instance] removeMessage:msg.msgLocalID uid:cid];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[CustomerMessageDB instance] markMessageFailure:msg.msgLocalID uid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[CustomerMessageDB instance] markMesageListened:msg.msgLocalID uid:cid];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentUID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[CustomerMessageDB instance] eraseMessageFailure:msg.msgLocalID uid:cid];
}


-(void)onCustomerMessage:(CustomerMessage*)im {
    if (self.isStaff && im.customer != self.peerUID) {
        return;
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
    

    if (!self.isStaff && m.sender != self.currentUID) {
        //普通用户收到客服的回复消息,记录下客服的id
        self.peerUID = m.sender;
    }
    
    int now = (int)time(NULL);
    if (now - self.lastReceivedTimestamp > 1) {
        [[self class] playMessageReceivedSound];
        self.lastReceivedTimestamp = now;
    }
    
    [self downloadMessageContent:m];
    [self insertMessage:m];
}

//服务器ack
-(void)onCustomerMessageACK:(int)msgLocalID uid:(int64_t)uid {
    if (self.isStaff && uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
}

//消息发送失败
-(void)onCustomerMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    if (self.isStaff && uid != self.peerUID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    msg.uploading = YES;
    [[CustomerOutbox instance] uploadImage:msg withImage:image];
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_MESSAGE object:msg userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}

- (void)sendMessage:(IMessage*)message {
    if (message.type == MESSAGE_AUDIO) {
        message.uploading = YES;
        [[CustomerOutbox instance] uploadAudio:message];
    } else if (message.type == MESSAGE_IMAGE) {
        message.uploading = YES;
        [[CustomerOutbox instance] uploadImage:message];
    } else {
        CustomerMessage *im = [[CustomerMessage alloc] init];
        im.sender = message.sender;
        im.receiver = message.receiver;
        im.msgLocalID = message.msgLocalID;
        im.content = message.rawContent;
        if (self.isStaff) {
            im.customer = message.receiver;
        } else {
            im.customer = message.sender;
        }
        [[IMService instance] sendCustomerMessage:im];
    }
    
    NSNotification* notification = [[NSNotification alloc] initWithName:LATEST_CUSTOMER_MESSAGE object:message userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];
}


#pragma mark - Outbox Observer
- (void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
    }
}

-(void)onAudioUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.flags = m.flags|MESSAGE_FLAG_FAILURE;
        m.uploading = NO;
    }
}

- (void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.uploading = NO;
    }
}

- (void)onImageUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.flags = m.flags|MESSAGE_FLAG_FAILURE;
        m.uploading = NO;
    }
}

@end
