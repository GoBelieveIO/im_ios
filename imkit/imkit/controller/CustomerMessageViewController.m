//
//  CustomerMessageViewController.m
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerMessageViewController.h"
#import "CustomerOutbox.h"
#import "AudioDownloader.h"
#import "CustomerMessageDB.h"
#import "SDImageCache.h"
#import "FileCache.h"
#import "UIImage+Resize.h"

#define PAGE_COUNT 10

@interface CustomerMessageViewController ()<OutboxObserver, CustomerMessageObserver, AudioDownloaderObserver>
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
                                                            action:@selector(onBack)];
    
    self.navigationItem.leftBarButtonItem = item;
    
    if (self.peerName.length > 0) {
        self.navigationItem.title = self.peerName;
    }
    
    [self addObserver];
    
}

-(void)addObserver {
    [[AudioDownloader instance] addDownloaderObserver:self];
    [[CustomerOutbox instance] addBoxObserver:self];
    [[IMService instance] addConnectionObserver:self];
    [[IMService instance] addCustomerMessageObserver:self];
}

-(void)removeObserver {
    [[AudioDownloader instance] removeDownloaderObserver:self];
    [[CustomerOutbox instance] removeBoxObserver:self];
    [[IMService instance] removeConnectionObserver:self];
    [[IMService instance] removeCustomerMessageObserver:self];
}

- (int64_t)sender {
    return self.currentUID;
}

- (int64_t)receiver {
    return self.storeID;
}

- (BOOL)isMessageSending:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[IMService instance] isCustomerMessageSending:msg.msgLocalID storeID:cm.storeID];
}

- (BOOL)isInConversation:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return self.storeID == cm.storeID;
}

- (void)onBack {
    [self removeObserver];
    [self stopPlayer];
    
    NSNotification* notification = [[NSNotification alloc] initWithName:CLEAR_CUSTOMER_NEW_MESSAGE
                                                                 object:[NSNumber numberWithLongLong:self.storeID]
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
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    id<IMessageIterator> iterator =  [[CustomerMessageDB instance] newMessageIterator:self.storeID];
    ICustomerMessage *msg = (ICustomerMessage*)[iterator next];
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
            msg.isOutgoing = !msg.isSupport;
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }

        msg = (ICustomerMessage*)[iterator next];
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
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (IMessage *msg in self.messages) {
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    id<IMessageIterator> iterator =  [[CustomerMessageDB instance] newMessageIterator:self.storeID last:last.msgLocalID];
    
    int count = 0;
    ICustomerMessage *msg = (ICustomerMessage*)[iterator next];
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
            msg.isOutgoing = !msg.isSupport;
            [self.messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = (ICustomerMessage*)[iterator next];
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
    if (msg.isOutgoing) {
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

-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    MessageAttachmentContent *att = [[MessageAttachmentContent alloc] initWithAttachment:msg.msgLocalID address:address];
    ICustomerMessage *attachment = [[ICustomerMessage alloc] init];
    attachment.rawContent = att.raw;
    [self saveMessage:attachment];
}


-(BOOL)saveMessage:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[CustomerMessageDB instance] insertMessage:msg uid:cm.storeID];
}

-(BOOL)removeMessage:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[CustomerMessageDB instance] removeMessage:msg.msgLocalID uid:cm.storeID];
    
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[CustomerMessageDB instance] markMessageFailure:msg.msgLocalID uid:cm.storeID];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[CustomerMessageDB instance] markMesageListened:msg.msgLocalID uid:cm.storeID];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    ICustomerMessage *cm = (ICustomerMessage*)msg;
    return [[CustomerMessageDB instance] eraseMessageFailure:msg.msgLocalID uid:cm.storeID];
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
    
    if (self.textMode && m.type != MESSAGE_TEXT) {
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
    
    if (self.textMode && m.type != MESSAGE_TEXT) {
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
-(void)onCustomerMessageACK:(CustomerMessage*)cm {
    if (self.storeID != cm.storeID) {
        return;
    }
    
    IMessage *msg = [self getMessageWithID:cm.msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_ACK;
}

//消息发送失败
- (void)onCustomerMessageFailure:(CustomerMessage*)cm {
    if (self.storeID != cm.storeID) {
        return;
    }
    
    IMessage *msg = [self getMessageWithID:cm.msgLocalID];
    msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
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
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = self.appID;
    msg.customerID = self.currentUID;
    msg.storeID = self.storeID;
    msg.sellerID = self.sellerID;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
    msg.rawContent = content.raw;
    
    content = msg.locationContent;
    content.address = address;
    
    msg.timestamp = (int)time(NULL);
    msg.isSupport = NO;
    msg.isOutgoing = YES;
    
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
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = self.appID;
    msg.customerID = self.currentUID;
    msg.storeID = self.storeID;
    msg.sellerID = self.sellerID;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
    
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isSupport = NO;
    msg.isOutgoing = YES;
    
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
    
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    msg.customerAppID = self.appID;
    msg.customerID = self.currentUID;
    msg.storeID = self.storeID;
    msg.sellerID = self.sellerID;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    
    float newHeight = screenHeight;
    float newWidth = newHeight*image.size.width/image.size.height;
    
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isSupport = NO;
    msg.isOutgoing = YES;
    
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
    ICustomerMessage *msg = [[ICustomerMessage alloc] init];
    
    msg.customerAppID = self.appID;
    msg.customerID = self.currentUID;
    msg.storeID = self.storeID;
    msg.sellerID = self.sellerID;
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isSupport = NO;
    msg.isOutgoing = YES;
    
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
