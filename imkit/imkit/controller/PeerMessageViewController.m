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
#import "Constants.h"
#import "PeerOutbox.h"
#import "UIImage+Resize.h"
#import "SDImageCache.h"

#define PAGE_COUNT 10

//当前appid
#define APPID 7

@interface PeerMessageViewController ()<OutboxObserver, AudioDownloaderObserver>
@property(nonatomic, readonly) int64_t peerID;
@end

@implementation PeerMessageViewController

-(int64_t)peerID {
    int64_t appid = self.peerAppID;
    return (appid << 56) | self.peerUID;
}
-(int64_t)currentID {
    int64_t appid = APPID;
    return (appid<<56) | self.currentUID;
}

- (void)dealloc {
    NSLog(@"peermessageviewcontroller dealloc");
}

- (void)viewDidLoad {
    if (self.peerAppID == 0) {
        self.peerAppID = APPID;
    }
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setNormalNavigationButtons];
    
    if (self.peerName.length > 0) {
        self.navigationItem.title = self.peerName;
    } else {
        IUser *u = [self.userDelegate getUser:self.peerID];
        if (u.name.length > 0) {
            self.navigationItem.title = u.name;
        } else {
            self.navigationItem.title = u.identifier;
            [self.userDelegate asyncGetUser:self.peerID cb:^(IUser *u) {
                if (u.name.length > 0) {
                    self.navigationItem.title = u.name;
                }
            }];
        }
    }

    [self addObserver];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)addObserver {
    [[AudioDownloader instance] addDownloaderObserver:self];
    [[PeerOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addPeerMessageObserver:self];
}

-(void)removeObserver {
    [[AudioDownloader instance] removeDownloaderObserver:self];
    [[PeerOutbox instance] removeBoxObserver:self];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removePeerMessageObserver:self];
}


- (BOOL)isMessageSending:(IMessage*)msg {
    return [[IMService instance] isPeerMessageSending:self.peerID id:msg.msgLocalID];
}

- (BOOL)isInConversation:(IMessage*)msg {
   BOOL r =  (msg.sender == self.currentID && msg.receiver == self.peerID) ||
                (msg.receiver == self.currentID && msg.sender == self.peerID);
    return r;
}

-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    IMessage *attachment = [[IMessage alloc] init];
    attachment.senderAppID = msg.senderAppID;
    attachment.receiverAppID = msg.receiverAppID;
    attachment.senderID = msg.senderID;
    attachment.receiverID = msg.receiverID;
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
}


-(BOOL)saveMessage:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] insertMessage:msg uid:cid];
}

-(BOOL)removeMessage:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] removeMessage:msg.msgLocalID uid:cid];

}
-(BOOL)markMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] markMessageFailure:msg.msgLocalID uid:cid];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentID) {
        cid = msg.receiver;
    } else {
        cid = msg.sender;
    }
    return [[PeerMessageDB instance] markMesageListened:msg.msgLocalID uid:cid];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    int64_t cid = 0;
    if (msg.sender == self.currentID) {
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
    [self removeObserver];
    [self stopPlayer];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_PEER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.peerID]
                                                               userInfo:nil];
    [[NSNotificationCenter defaultCenter] postNotification:notification];

    [self.navigationController popViewControllerAnimated:YES];
}



#pragma mark - MessageObserver
- (void)onPeerMessage:(IMMessage*)im {
    if (im.sender != self.peerID && im.receiver != self.peerID) {
        return;
    }
    NSLog(@"receive msg:%@",im);
    IMessage *m = [[IMessage alloc] init];
    m.senderID = im.senderID;
    m.receiverID = im.receiverID;
    m.senderAppID = im.senderAppID;
    m.receiverAppID = im.receiverAppID;
    
    
    m.msgLocalID = im.msgLocalID;
    m.rawContent = im.content;
    m.timestamp = im.timestamp;
    m.isOutgoing = (im.sender == self.currentID);
    if (im.sender == self.currentID) {
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
    
    [self downloadMessageContent:m];
    [self insertMessage:m];
}

//服务器ack
- (void)onPeerMessageACK:(int)msgLocalID uid:(int64_t)uid {
    if (uid != self.peerID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
}

- (void)onPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid {
    if (uid != self.peerID) {
        return;
    }
    IMessage *msg = [self getMessageWithID:msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
}

//对方正在输入
- (void)onPeerInputing:(int64_t)uid {
    if (uid != self.peerID) {
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
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    NSLog(@"peerid:%lld %lld %lld", self.peerID, self.peerUID, self.peerAppID);
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newMessageIterator: self.peerID];
    IMessage *msg = [iterator next];
    while (msg) {
        //重复的消息
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            msg = [iterator next];
            continue;
        }
        
        if (msg.uuid.length > 0){
            [uuidSet addObject:msg.uuid];
        }

        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentID);
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }

        msg = [iterator next];
    }
  

    [self downloadMessageContent:self.messages count:count];
    [self loadSenderInfo:self.messages count:count];
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
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (IMessage *msg in self.messages) {
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    id<IMessageIterator> iterator =  [[PeerMessageDB instance] newMessageIterator:self.peerID last:last.msgLocalID];
    
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        //重复的消息
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            msg = [iterator next];
            continue;
        }
        
        if (msg.uuid.length > 0){
            [uuidSet addObject:msg.uuid];
        }
        
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = (msg.sender == self.currentID);
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

    [self loadSenderInfo:self.messages count:count];
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
    if (msg.isOutgoing) {
        if (msg.type == MESSAGE_AUDIO) {
            msg.uploading = [[PeerOutbox instance] isUploading:msg];
        } else if (msg.type == MESSAGE_IMAGE) {
            msg.uploading = [[PeerOutbox instance] isUploading:msg];
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


#pragma mark - Audio Downloader Observer
- (void)onAudioDownloadSuccess:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.downloading = NO;
    }
}

- (void)onAudioDownloadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        IMessage *m = [self getMessageWithID:msg.msgLocalID];
        m.downloading = NO;
    }
}


#pragma mark - send message
- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.senderAppID = APPID;
    msg.receiverAppID = self.peerAppID;
    msg.senderID = self.currentUID;
    msg.receiverID = self.peerUID;

    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
    msg.rawContent = content.raw;
    
    content = msg.locationContent;
    content.address = address;
    
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;

    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self createMapSnapshot:msg];
    if (content.address.length == 0) {
        [self reverseGeocodeLocation:msg];
    } else {
        [self saveMessageAttachment:msg address:content.address];
    }
    [self insertMessage:msg];
}

- (void)sendAudioMessage:(NSString*)path second:(int)second {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.senderAppID = APPID;
    msg.receiverAppID = self.peerAppID;
    msg.senderID = self.currentUID;
    msg.receiverID = self.peerUID;

    MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
    
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:path];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:content.url];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


- (void)sendImageMessage:(UIImage*)image {
    if (image.size.height == 0) {
        return;
    }
    
    IMessage *msg = [[IMessage alloc] init];
    
    msg.senderAppID = APPID;
    msg.receiverAppID = self.peerAppID;
    msg.senderID = self.currentUID;
    msg.receiverID = self.peerUID;

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    float newHeight = screenHeight;
    float newWidth = newHeight*image.size.width/image.size.height;
    
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    UIImage *sizeImage = [image resizedImage:CGSizeMake(128, 128) interpolationQuality:kCGInterpolationDefault];
    image = [image resizedImage:CGSizeMake(newWidth, newHeight) interpolationQuality:kCGInterpolationDefault];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL];
    NSString *littleUrl =  [content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg withImage:image];
    
    [self insertMessage:msg];
    
    [[self class] playMessageSentSound];
}

-(void) sendTextMessage:(NSString*)text {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.senderAppID = APPID;
    msg.receiverAppID = self.peerAppID;
    msg.senderID = self.currentUID;
    msg.receiverID = self.peerUID;

    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


-(void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    [self eraseMessageFailure:message];
    [self sendMessage:message];
}


@end
