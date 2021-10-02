/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "BaseMessageViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AudioToolbox/AudioServices.h>
#import <SDWebImage/SDWebImage.h>

#import "MEESImageViewController.h"
#import "NSString+JSMessagesView.h"
#import "AVURLAsset+Video.h"
#import "MapViewController.h"
#import "LocationPickerController.h"
#import "WebViewController.h"
#import "OverlayViewController.h"
#import "FileDownloadViewController.h"

#import "UIImage+Resize.h"
#import "NSDate+Format.h"
#import "UIView+Toast.h"
#import "AVURLAsset+Video.h"
#import "IMessage.h"
#import "FileCache.h"
#import "AudioDownloader.h"

//应用启动时间
static int uptime = 0;

@interface BaseMessageViewController ()<AVAudioPlayerDelegate, UIDocumentInteractionControllerDelegate, FileDownloadViewControllerDelegate>
@property(nonatomic) IMessage *playingMessage;
@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) NSTimer *playTimer;
@end

@implementation BaseMessageViewController

+(void)load {
    uptime = (int)time(NULL);
}

+ (void)playSoundWithName:(NSString *)name type:(NSString *)type {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        SystemSoundID sound;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &sound);
        AudioServicesPlaySystemSound(sound);
    }
    else {
        NSLog(@"Error: audio file not found at path: %@", path);
    }
}

+ (void)playMessageReceivedSound {
    [self playSoundWithName:@"messageReceived" type:@"aiff"];
}

+ (void)playMessageSentSound {
    [self playSoundWithName:@"messageSent" type:@"aiff"];
}


+ (BOOL)isHeadphone {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray array];
    }
    return self;
}

-(void)updateMessageContent:(IMessage*)msg {
    [self.messageDB updateMessageContent:msg.msgId content:msg.content.raw];
}


-(BOOL)saveMessage:(IMessage*)msg {
    return [self.messageDB saveMessage:msg];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [self.messageDB removeMessage:msg.msgId];
}

-(BOOL)markMessageFailure:(IMessage*)msg {
    return [self.messageDB markMessageFailure:msg.msgId];
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [self.messageDB markMesageListened:msg.msgId];
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [self.messageDB eraseMessageFailure:msg.msgId];
}

-(BOOL)markMessageReaded:(IMessage*)msg {
    return [self.messageDB markMessageReaded:msg.msgId];
}


-(void)initTableViewData {
    NSMutableArray *newMessages = [NSMutableArray array];
    NSDate *lastDate = nil;
    
    NSInteger count = [self.messages count];
    if (count == 0) {
        return;
    }
    
    for (NSInteger i = 0; i < count; i++) {
        IMessage *msg = [self.messages objectAtIndex:i];
        if (msg.type == MESSAGE_TIME_BASE) {
            continue;
        }
        
        if (lastDate == nil || msg.timestamp - lastDate.timeIntervalSince1970 > 1*60) {
            MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
            tb.notificationDesc = [[NSDate dateWithTimeIntervalSince1970:tb.timestamp] formatSectionTime];
            IMessage *m = [[IMessage alloc] init];
            m.content = tb;
            [newMessages addObject:m];
            lastDate = [NSDate dateWithTimeIntervalSince1970:msg.timestamp];
        }
        
        [newMessages addObject:msg];
    }
    
    self.messages = newMessages;
}

- (void)loadData {
    NSArray *messages;
    if (self.messageID > 0) {
        messages = [self loadConversationData:self.messageID];
    } else {
        messages = [self loadConversationData];
    }
    
    if (messages.count == 0) {
        return;
    }
    //去掉重复的消息
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (NSInteger i = 0; i < messages.count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            continue;
        }
        //不显示MESSAGE_P2P_SESSION 控制消息
        if (msg.type == MESSAGE_P2P_SESSION) {
            continue;
        }
        
        [self.messages addObject:msg];
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    int count = (int)self.messages.count;
    [self prepareMessage:self.messages count:count];
    [self initTableViewData];
}


- (int)loadEarlierData {
    if (!self.hasEarlierMore) {
        return 0;
    }
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
        return 0;
    }
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (IMessage *msg in self.messages) {
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    NSArray *newMessages = [self loadEarlierData:last.msgId];
    if (newMessages.count == 0) {
        self.hasEarlierMore = NO;
        return 0;
    }
    NSLog(@"load earlier messages:%zd", newMessages.count);
    
    //过滤掉重复的消息
    int count = 0;
    for (NSInteger i = newMessages.count - 1; i >= 0; i--) {
        IMessage *msg = [newMessages objectAtIndex:i];
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            continue;
        }
        //不显示MESSAGE_P2P_SESSION 控制消息
        if (msg.type == MESSAGE_P2P_SESSION) {
            continue;
        }
        
        count++;
        [self.messages insertObject:msg atIndex:0];
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    
    [self prepareMessage:self.messages count:count];
    
    [self initTableViewData];
    
    int c = 0;
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
    return row;
}

//加载后面的聊天记录
-(int)loadLaterData {
    int newCount = 0;
    if (!self.hasLaterMore || self.messages.count == 0) {
        return newCount;
    }
    int64_t messageID = 0;
    for (NSInteger i = self.messages.count - 1; i > 0; i--) {
        IMessage *msg = [self.messages objectAtIndex:i];
        if (msg.msgId) {
            messageID = msg.msgId;
            break;
        }
    }
    
    if (messageID == 0) {
        return newCount;
    }
    
    NSArray *newMessages = [self loadLaterData:messageID];
    
    if (newMessages.count == 0) {
        self.hasLaterMore = NO;
        return newCount;
    }
    
    //过滤掉重复的消息
    NSMutableArray *tmpMessages = [NSMutableArray array];
    int count = 0;
    NSMutableSet *uuidSet = [NSMutableSet set];
    for (IMessage *msg in newMessages) {
        if (msg.uuid.length > 0 && [uuidSet containsObject:msg.uuid]) {
            continue;
        }
        //不显示MESSAGE_P2P_SESSION 控制消息
        if (msg.type == MESSAGE_P2P_SESSION) {
            continue;
        }
        count++;
        [tmpMessages addObject:msg];
        if (msg.uuid.length > 0) {
            [uuidSet addObject:msg.uuid];
        }
    }
    newMessages = tmpMessages;
    
    NSLog(@"load late messages:%d", count);
    [self prepareMessage:newMessages count:count];
    [self insertMessages:newMessages];
    newCount = (int)newMessages.count;
    return newCount;
}

- (NSArray*)loadConversationData {
    NSMutableArray *messages = [NSMutableArray array];
    
    NSMutableSet *uuidSet = [NSMutableSet set];
    int count = 0;
    int pageSize;
    id<IMessageIterator> iterator;
    
    iterator = [self newMessageIterator];
    pageSize = self.pageSize > 0 ? self.pageSize : PAGE_COUNT;

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
        [messages insertObject:msg atIndex:0];
        if (++count >= pageSize) {
            break;
        }
        msg = [iterator next];
    }
    
    
    return messages;
}

//navigator from search
- (NSArray*)loadConversationData:(int64_t)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    int count = 0;
    id<IMessageIterator> iterator;
    
    IMessage *msg = [self.messageDB getMessage:messageID];
    if (!msg) {
        return nil;
    }
    [messages addObject:msg];
    
    int pageSize = self.pageSize > 0 ? self.pageSize : PAGE_COUNT;
    iterator = [self newBackwardMessageIterator:messageID];
    msg = [iterator next];
    while (msg) {
        [messages addObject:msg];
        if (++count >= pageSize) {
            break;
        }
        msg = [iterator next];
    }
    
    count = 0;
    iterator = [self newForwardMessageIterator:messageID];
    msg = [iterator next];
    while (msg) {
        [messages insertObject:msg atIndex:0];
        if (++count >= pageSize) {
            break;
        }
        msg = [iterator next];
    }
    return messages;
}


- (NSArray*)loadEarlierData:(int64_t)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    
    id<IMessageIterator> iterator = [self newForwardMessageIterator:messageID];
    
    int pageSize = self.pageSize > 0 ? self.pageSize : PAGE_COUNT;
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        [messages insertObject:msg atIndex:0];
        if (++count >= pageSize) {
            break;
        }
        msg = [iterator next];
    }
    NSLog(@"load earlier messages:%d", count);
    return messages;
}

//加载后面的聊天记录
-(NSArray*)loadLaterData:(int64_t)messageID {
    id<IMessageIterator> iterator = [self newBackwardMessageIterator:messageID];
    NSMutableArray *newMessages = [NSMutableArray array];
    int count = 0;
    int pageSize = self.pageSize > 0 ? self.pageSize : PAGE_COUNT;
    IMessage *msg = [iterator next];
    while (msg) {
        [newMessages addObject:msg];
        if (++count >= pageSize) {
            break;
        }
        msg = [iterator next];
    }
    
    NSLog(@"load late messages:%d", count);
    return newMessages;
}

-(void)clear {
    [self.messages removeAllObjects];
}



-(void)insertMessages:(NSArray*)messages {
    NSTimeInterval lastDate = 0;
    NSInteger count = [self.messages count];
    
    for (NSInteger i = count; i > 0; i--) {
        IMessage *m = [self.messages objectAtIndex:i-1];
        if (m.type == MESSAGE_TIME_BASE) {
            lastDate = m.timeBaseContent.timestamp;
            break;
        }
    }
    
    for (IMessage *msg in messages) {
        if (msg.timestamp - lastDate > 1*60) {
            MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
            tb.notificationDesc = [[NSDate dateWithTimeIntervalSince1970:tb.timestamp] formatSectionTime];
            IMessage *m = [[IMessage alloc] init];
            m.content = tb;
            [self.messages addObject:m];
            
            lastDate = msg.timestamp;
        }
        [self.messages addObject:msg];
    }
}

- (BOOL)insertMessage:(IMessage*)msg {
    NSDate *lastDate = nil;
    NSInteger count = [self.messages count];
    
    for (NSInteger i = count; i > 0; i--) {
        IMessage *m = [self.messages objectAtIndex:i-1];
        if (m.type == MESSAGE_TIME_BASE) {
            lastDate = [NSDate dateWithTimeIntervalSince1970:m.timeBaseContent.timestamp];
            break;
        }
    }
    
    BOOL newTimeBase = NO;
    if (lastDate == nil || msg.timestamp - lastDate.timeIntervalSince1970 > 1*60) {
        MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
        tb.notificationDesc = [[NSDate dateWithTimeIntervalSince1970:tb.timestamp] formatSectionTime];
        IMessage *m = [[IMessage alloc] init];
        m.content = tb;
        [self.messages addObject:m];
        newTimeBase = YES;

    }
    [self checkAtName:msg];
    [self.messages addObject:msg];
    
    return newTimeBase;
}

- (int)deleteMessage:(IMessage*)msg {
    NSInteger index = -1;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.msgId == msg.msgId) {
            index = i;
        }
    }
    if (index != -1) {
        [self.messages removeObjectAtIndex:index];
    }
    return (int)index;
}

-(int)replaceMessage:(IMessage*)msg dest:(IMessage*)other {
    NSInteger index = -1;
    for (NSInteger i = 0; i < self.messages.count; i++) {
        IMessage *m = [self.messages objectAtIndex:i];
        if (m.msgId == msg.msgId) {
            index = i;
        }
    }
    if (index != -1) {
        [self.messages replaceObjectAtIndex:index withObject:other];
    }
    return (int)index;
}

- (IMessage*)getMessageWithIndex:(NSInteger)index {
    IMessage *msg = [self.messages objectAtIndex:index];
    return msg;
}

- (IMessage*)getMessageWithID:(int64_t)msgLocalID {
    for (IMessage *msg in self.messages) {
        if (msg.msgId == msgLocalID) {
            return msg;
        }
    }
    return nil;
}

- (IMessage*)getMessageWithUUID:(NSString*)uuid {
    return [self getMessageWithUUID:uuid index:nil];
}

- (IMessage*)getMessageWithUUID:(NSString*)uuid index:(int*)index {
    if (uuid.length == 0) {
        return nil;
    }
    for (int i = 0; i < self.messages.count; i++) {
        IMessage *msg = [self.messages objectAtIndex:i];
        if ([msg.uuid isEqualToString:uuid]) {
            if (index){
                *index = i;
            }
            return msg;
        }
    }
    return nil;
}


- (void)prepareMessage:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self prepareMessage:msg];
    }
}


-(void)prepareMessage:(IMessage*)message {
    message.isOutgoing = [self getMessageOutgoing:message];
    [self loadSenderInfo:message];
    [self downloadMessageContent:message];
    [self updateNotificationDesc:message];
    [self checkMessageFailureFlag:message];
    [self checkAtName:message];
    [self sendReaded:message];
}

-(void)checkMessageFailureFlag:(IMessage*)msg {
    if (msg.isOutgoing) {
        if (msg.timestamp < uptime) {
            if (!msg.isACK) {
                //上次运行的时候，程序异常崩溃
                [self markMessageFailure:msg];
                msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
            }
        }
    }
}


-(void)checkAtName:(IMessage*)msg {

}

- (void)loadSenderInfo:(IMessage*)msg {
    msg.senderInfo = [self getUser:msg.sender];
    if (msg.senderInfo.name.length == 0) {
        [self asyncGetUser:msg.sender cb:^(IUser *u) {
            msg.senderInfo = u;
        }];
    }
}

- (void)updateNotificationDesc:(IMessage*)message {
    if (message.type == MESSAGE_REVOKE) {
        MessageRevoke *content = message.revokeContent;
        NSString *name;
        if (message.isOutgoing) {
            name = NSLocalizedString(@"you", nil);
        } else {
            IUser *u = [self getUser:message.sender];
            if (u.name.length > 0) {
                name = u.name;
            } else {
                name = u.identifier;
                [self asyncGetUser:message.sender cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:NSLocalizedString(@"message.revoked", nil), u.name];
                    content.notificationDesc = desc;
                }];
            }
        }
        
        NSString *desc = [NSString stringWithFormat:NSLocalizedString(@"message.revoked", nil), name];
        content.notificationDesc = desc;
        
    } else if (message.type == MESSAGE_ACK) {
        MessageACK *ack = message.ackContent;
        if (ack.error == MSG_ACK_NOT_YOUR_FRIEND) {
            ack.notificationDesc = NSLocalizedString(@"message.notFriend", nil);
        } else if (ack.error == MSG_ACK_IN_YOUR_BLACKLIST) {
            ack.notificationDesc = NSLocalizedString(@"message.refused", nil);
        } else if (ack.error == MSG_ACK_NOT_MY_FRIEND) {
            ack.notificationDesc = NSLocalizedString(@"message.notMyFriend", nil);
        }
    }
}

- (void)downloadMessageContent:(IMessage*)msg {
    FileCache *cache = [FileCache instance];
    AudioDownloader *downloader = [AudioDownloader instance];
    if (msg.type == MESSAGE_AUDIO) {
        MessageAudioContent *content = msg.audioContent;
        
        NSString *path = [cache queryCacheForKey:content.url];
        NSLog(@"url:%@, %@", content.url, path);
        if (!path && ![downloader isDownloading:msg]) {
            [downloader downloadAudio:msg];
        }
        msg.downloading = [downloader isDownloading:msg];
    } else if (msg.type == MESSAGE_LOCATION) {
        MessageLocationContent *content = msg.locationContent;
        NSString *url = content.snapshotURL;
        if(![[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] &&
           ![[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
            [self createMapSnapshot:msg];
        }
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:msg];
        }
    } else if (msg.type == MESSAGE_IMAGE) {
        NSLog(@"image url:%@", msg.imageContent.imageURL);
        if (msg.secret) {
            MessageImageContent *content = msg.imageContent;
            BOOL exists = [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:content.imageURL];
            BOOL downloading = [downloader isDownloading:msg];
            if (!exists && !downloading) {
                [downloader downloadImage:msg];
                msg.downloading = [downloader isDownloading:msg];
            }
        }
    } else if (msg.type == MESSAGE_VIDEO) {
        if (msg.secret) {
            MessageVideoContent *content = msg.videoContent;
            BOOL exists = [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:content.thumbnailURL];
            BOOL downloading = [downloader isDownloading:msg];
            if (!exists && !downloading) {
                [downloader downloadVideoThumbnail:msg];
                msg.downloading = [downloader isDownloading:msg];
            }
        }
    }
}

-(void)sendReaded:(IMessage*)message {
    NSLog(@"send readed not implement");
}

-(void)reverseGeocodeLocation:(IMessage*)msg {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    MessageLocationContent *content = msg.locationContent;
    CLLocationCoordinate2D location = content.location;
    msg.geocoding = YES;
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *array, NSError *error) {
        if (!error && array.count > 0) {
            CLPlacemark *placemark = [array objectAtIndex:0];
            msg.content = [content cloneWithAddress:placemark.name];
            [self updateMessageContent:msg];
        }
        msg.geocoding = NO;
    }];
}

- (void)createMapSnapshot:(IMessage*)msg {
    MessageLocationContent *content = msg.locationContent;
    CLLocationCoordinate2D location = content.location;
    NSString *url = content.snapshotURL;
    
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc] init];
    options.scale = [[UIScreen mainScreen] scale];
    options.showsPointsOfInterest = YES;
    options.showsBuildings = YES;
    options.region = MKCoordinateRegionMakeWithDistance(location, 360, 200);
    options.mapType = MKMapTypeStandard;
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc] initWithOptions:options];
    
    msg.downloading = YES;
    [snapshotter startWithCompletionHandler:^(MKMapSnapshot *snapshot, NSError *e) {
        if (e) {
            NSLog(@"error:%@", e);
        }
        else {
            NSLog(@"map snapshot success");
            [[SDImageCache sharedImageCache] storeImage:snapshot.image forKey:url completion:nil];
        }
        msg.downloading = NO;
    }];
    
}

-(void)playVideo:(NSString*)mpath {
    NSURL *url=[NSURL fileURLWithPath:mpath];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *avplayer = [AVPlayer playerWithPlayerItem:item];
    AVPlayerViewController *moviePlayer= [[AVPlayerViewController alloc] init];
    moviePlayer.player = avplayer;
    [self presentViewController:moviePlayer animated:YES completion:^{
        [avplayer play];
    }];
}

- (void)updateSlider {
    self.playingMessage.progress = 100*self.player.currentTime/self.player.duration;
}

- (void)stopPlayer {
    if (self.player && [self.player isPlaying]) {
        [self.player stop];
        if ([self.playTimer isValid]) {
            [self.playTimer invalidate];
            self.playTimer = nil;
        }
        self.playingMessage.progress = 0;
        self.playingMessage.playing = NO;
        self.playingMessage = nil;
    }
}

#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    NSLog(@"player finished");
    self.playingMessage.progress = 0;
    self.playingMessage.playing = NO;
    self.playingMessage = nil;
    if ([self.playTimer isValid]) {
        [self.playTimer invalidate];
        self.playTimer = nil;
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"player decode error");
    self.playingMessage.progress = 0;
    self.playingMessage.playing = NO;
    self.playingMessage = nil;
    
    if ([self.playTimer isValid]) {
        [self.playTimer invalidate];
        self.playTimer = nil;
    }
}


#pragma mark - Message click handler
-(void)handleMessageDoubleClick:(IMessage*)message {
    if (message.type == MESSAGE_TEXT) {
        OverlayViewController *ctrl = [[OverlayViewController alloc] init];
        ctrl.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        ctrl.modalPresentationStyle = UIModalPresentationOverFullScreen;
        NSString *text = message.textContent.text;
        ctrl.text = text;
        
        [self presentViewController:ctrl animated:YES completion:^{
            
        }];
    }
}

-(void)handleMesageClick:(IMessage*)message view:(UIView*)view {
    if (message.type == MESSAGE_IMAGE) {
        [self handleTapImageView:message view:view];
    } else if (message.type == MESSAGE_AUDIO) {
        [self handleTapAudioView:message];
    } else if (message.type == MESSAGE_LOCATION) {
        [self handleTapLocationView:message];
    } else if (message.type == MESSAGE_LINK) {
        [self handleTapLinkView:message];
    } else if (message.type == MESSAGE_VIDEO) {
        [self handleTapVideoView:message];
    } else if (message.type == MESSAGE_FILE) {
        [self handleTapFileView:message];
    }
}

- (void) handleTapImageView:(IMessage*)message view:(UIView*)view {
    MessageImageContent *content = message.imageContent;
    NSString *littleUrl = [content littleImageURL];
    
    if ([[SDImageCache sharedImageCache] diskImageDataExistsWithKey:content.imageURL]) {
        UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: content.imageURL];
        MEESImageViewController * imgcontroller = [[MEESImageViewController alloc] init];
        [imgcontroller setImage:cacheImg];
        [imgcontroller setTappedThumbnail:view];
        imgcontroller.isFullSize = YES;
        [self presentViewController:imgcontroller animated:YES completion:nil];
    } else if([[SDImageCache sharedImageCache] diskImageDataExistsWithKey:littleUrl]){
        UIImage *cacheImg = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey: littleUrl];
        MEESImageViewController * imgcontroller = [[MEESImageViewController alloc] init];
        [imgcontroller setImage:cacheImg];
        imgcontroller.isFullSize = NO;
        [imgcontroller setImgUrl:content.imageURL];
        [imgcontroller setTappedThumbnail:view];
        [self presentViewController:imgcontroller animated:YES completion:nil];
    }
}

- (void) handleTapAudioView:(IMessage*)message {
    if (self.playingMessage != nil && self.playingMessage.msgId == message.msgId) {
        [self stopPlayer];
    } else {
        [self stopPlayer];

        FileCache *fileCache = [FileCache instance];
        MessageAudioContent *content = message.audioContent;
        NSString *url = content.url;
        NSString *path = [fileCache queryCacheForKey:url];
        if (path != nil) {
            if (!message.isListened) {
                message.flags |= MESSAGE_FLAG_LISTENED;
                [self markMesageListened:message];
            }

            message.progress = 0;
            message.playing = YES;
            
            // Setup audio session
            AVAudioSession *session = [AVAudioSession sharedInstance];
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
            
            //设置为与当前音频播放同步的Timer
            self.playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
            self.playingMessage = message;
            
            if (![[self class] isHeadphone]) {
                //打开外放
                [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                           error:nil];
                
            }
            NSURL *u = [NSURL fileURLWithPath:path];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:u error:nil];
            [self.player setDelegate:self];
            [self.player play];

        }
    }
}
- (void)handleTapLinkView:(IMessage*)message {
    WebViewController *ctl = [[WebViewController alloc] init];
    ctl.url = message.linkContent.url;
    [self.navigationController pushViewController:ctl animated:YES];
}

- (void)handleTapLocationView:(IMessage*)message {
    MessageLocationContent *content = message.locationContent;
    MapViewController *ctl = [[MapViewController alloc] init];
    ctl.friendCoordinate = content.location;
    [self.navigationController pushViewController:ctl animated:YES];
}

- (void)handleTapVideoView:(IMessage*)message {
    MessageVideoContent *content = message.videoContent;
    if ([[FileCache instance] isCached:content.videoURL]) {
        if (message.secret) {
            NSString *path = [[FileCache instance] cachePathForKey:content.videoURL];
            NSString *mp4Path = [NSString stringWithFormat:@"%@.mp4", path];
            if (![[NSFileManager defaultManager] fileExistsAtPath:mp4Path]) {
                [[NSFileManager defaultManager] linkItemAtPath:path toPath:mp4Path error:nil];
            }
            [self playVideo:mp4Path];
        } else {
            NSString *path = [[FileCache instance] cachePathForKey:content.videoURL];
            [self playVideo:path];
        }
    } else {
        FileDownloadViewController *ctrl = [[FileDownloadViewController alloc] init];
        ctrl.url = content.videoURL;
        ctrl.size = content.size;
        ctrl.message = message;
        ctrl.delegate = self;
        [self.navigationController pushViewController:ctrl animated:YES];
    }
}

-(void)handleTapFileView:(IMessage*)message {
    MessageFileContent *content = message.fileContent;
    if ([[FileCache instance] isCached:content.fileURL]) {
        NSString *path = [[FileCache instance] cachePathForKey:content.fileURL];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        UIDocumentInteractionController *documentVc = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        documentVc.delegate = self;
        BOOL r = [documentVc presentPreviewAnimated:YES];
        if (!r) {
            [self.view makeToast:@"系统不支持预览此文件内容" duration:0.7 position:CSToastPositionBottom];
        }
    } else {
        //first download file to local storage
        FileDownloadViewController *ctrl = [[FileDownloadViewController alloc] init];
        ctrl.url = content.fileURL;
        ctrl.size = content.fileSize;
        ctrl.message = message;
        ctrl.delegate = self;
        [self.navigationController pushViewController:ctrl animated:YES];
    }
}

#pragma mark - FileDownloadViewControllerDelegate
-(void)fileDownloadSuccess:(NSString *)url message:(IMessage *)msg {
    //pop fileviewcontroller
    [self.navigationController popViewControllerAnimated:NO];

    if (msg.type == MESSAGE_FILE) {
        NSString *path = [[FileCache instance] cachePathForKey:url];
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        UIDocumentInteractionController *documentVc = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        documentVc.delegate = self;
        BOOL r = [documentVc presentPreviewAnimated:YES];
        if (!r) {
            [self.view makeToast:@"系统不支持预览此文件内容" duration:0.7 position:CSToastPositionBottom];
        }
    } else if (msg.type == MESSAGE_VIDEO) {
        NSString *path = [[FileCache instance] cachePathForKey:url];
        if (msg.secret) {
            NSString *mp4Path = [NSString stringWithFormat:@"%@.mp4", path];
            if (![[NSFileManager defaultManager] fileExistsAtPath:mp4Path]) {
                [[NSFileManager defaultManager] linkItemAtPath:path toPath:mp4Path error:nil];
            }
            [self playVideo:mp4Path];
        } else {
            [self playVideo:path];
        }
    }
}


#pragma mark - Outbox Observer
- (void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.uploading = NO;
}

-(void)onAudioUploadFail:(IMessage*)msg {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.flags = m.flags|MESSAGE_FLAG_FAILURE;
    m.uploading = NO;
}

- (void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.uploading = NO;
}

- (void)onImageUploadFail:(IMessage*)msg {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.flags = m.flags|MESSAGE_FLAG_FAILURE;
    m.uploading = NO;
}

- (void)onVideoUploadSuccess:(IMessage *)msg URL:(NSString *)url thumbnailURL:(NSString *)thumbURL {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.uploading = NO;
}

- (void)onVideoUploadFail:(IMessage *)msg {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.flags = m.flags|MESSAGE_FLAG_FAILURE;
    m.uploading = NO;
}

- (void)onFileUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.content = [m.fileContent cloneWithURL:url];
    m.uploading = NO;
}

-(void)onFileUploadFail:(IMessage*)msg {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.flags = m.flags|MESSAGE_FLAG_FAILURE;
    m.uploading = NO;
}

#pragma mark - Audio Downloader Observer
- (void)onAudioDownloadSuccess:(IMessage*)msg {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.downloading = NO;
}

- (void)onAudioDownloadFail:(IMessage*)msg {
    IMessage *m = [self getMessageWithUUID:msg.uuid];
    m.downloading = NO;
}


#pragma mark - UIDocumentInteractionController 代理方法
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self.navigationController;
}

- (UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller{
    return self.view;
}

- (CGRect)documentInteractionControllerRectForPreview:(UIDocumentInteractionController *)controller{
    return self.view.bounds;
}

#pragma mark - send message
- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address {
    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location address:address];
    IMessage *msg = [self newOutMessage:content];

    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    [self sendMessage:msg];
    
    [self createMapSnapshot:msg];
    if (content.address.length == 0) {
        [self reverseGeocodeLocation:msg];
    }
    [self insertMessage:msg];
}

- (void)sendAudioMessage:(NSString*)path second:(int)second {

    MessageAudioContent *content = [[MessageAudioContent alloc] initWithAudio:[self localAudioURL] duration:second];
    IMessage *msg = [self newOutMessage:content];
    
    [self loadSenderInfo:msg];
    
    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:path];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:content.url];
    
    [self saveMessage:msg];
    [self sendMessage:msg];
    [self insertMessage:msg];
}

-(UIImage*)resizeImage:(UIImage*)image {
    return [image resize];
}

- (void)sendVideoMessage:(NSURL*)url {
    int size = (int)[[[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil] fileSize];
    AVURLAsset * asset = [AVURLAsset assetWithURL:url];
    NSDictionary *d = [asset metadata];
    UIImage *thumb = [asset thumbnail];
    NSLog(@"video metadata:%@", d);
    if ([[d objectForKey:@"duration"] intValue] < 1) {
        [self.view makeToast:NSLocalizedString(@"message.recordVideoTimeShort", nil) duration:0.7 position:CSToastPositionBottom];
        return;
    }
    int width = [[d objectForKey:@"width"] intValue];
    int height = [[d objectForKey:@"height"] intValue];
    int duration = [[d objectForKey:@"duration"] intValue];
    
    NSString *thumbURL = [self localImageURL];
    NSString *videoURL = [self localVideoURL];
    
    [[SDImageCache sharedImageCache] storeImage:thumb forKey:thumbURL completion:nil];
    NSString *path = [[FileCache instance] cachePathForKey:videoURL];
    NSURL *mp4URL = [NSURL fileURLWithPath:path];
    [self convertVideoToLowQuailtyWithInputURL:url outputURL:mp4URL handler:^() {
        dispatch_async(dispatch_get_main_queue(), ^{
            MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                               thumbnail:thumbURL
                                                                                   width:width
                                                                                  height:height
                                                                                duration:duration
                                                                                    size:size];
            IMessage *msg = [self newOutMessage:content];
            [self loadSenderInfo:msg];
            [self saveMessage:msg];
            [self sendMessage:msg];
            [self insertMessage:msg];
        });
    }];
}

- (void)sendImageMessage:(UIImage*)image {
    if (image.size.height == 0) {
        return;
    }
    
    UIImage *sizeImage = [image resize:CGSizeMake(256, 256)];
    image = [self resizeImage:image];
    int newWidth = image.size.width;
    int newHeight = image.size.height;
    NSLog(@"image size:%f %f resize to %d %d", image.size.width, image.size.height, newWidth, newHeight);
    

    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
    IMessage *msg = [self newOutMessage:content];
    [self loadSenderInfo:msg];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL completion:nil];
    NSString *littleUrl =  [content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl completion:nil];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg withImage:image];
    [self insertMessage:msg];
}

-(void)sendTextMessage:(NSString*)text at:(NSArray*)atUsers atNames:(NSArray*)atNames {

    
    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text at:atUsers atNames:atNames];
    IMessage *msg = [self newOutMessage:content];
    [self loadSenderInfo:msg];
    [self saveMessage:msg];
    [self sendMessage:msg];
    [self insertMessage:msg];
}

-(void)sendFileMessage:(NSURL*)url {
    NSString *fileName = [url lastPathComponent];
    NSString *filePath = [url absoluteString];
    NSString *ext = [fileName pathExtension];
    NSLog(@"file path:%@ ext:%@", filePath, ext);
    
    NSString *fileURL = [self localFileURL:ext];
    NSString *cachePath = [[FileCache instance] cachePathForKey:fileURL];
    NSURL *cacheURL = [NSURL fileURLWithPath:cachePath];

    BOOL r = [[NSFileManager defaultManager] copyItemAtURL:url toURL:cacheURL error:nil];
    if (!r) {
        return;
    }
    
    NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:cachePath error:nil];
    if (attr.fileSize == 0) {
        return;
    }
    
    MessageFileContent *content = [[MessageFileContent alloc] initWithFileURL:fileURL name:fileName size:(int)(attr.fileSize)];
    IMessage *msg = [self newOutMessage:content];
    [self loadSenderInfo:msg];
    [self saveMessage:msg];
    [self sendMessage:msg];
    [self insertMessage:msg];
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(void))handler {
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
#if 1
    NSError *err = nil;
    BOOL r = [[NSFileManager defaultManager] copyItemAtURL:inputURL toURL:outputURL error:&err];
    if (!r) {
        NSLog(@"copy video from:%@ to:%@ err:%@", inputURL, outputURL, err);
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler();
        });
    }
#else
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        NSLog(@"convert video asset export session status:%d", (int)exportSession.status);
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            handler();
        }
    }];
#endif
}

-(NSString*)guid {
    CFUUIDRef    uuidObj = CFUUIDCreate(nil);
    NSString    *uuidString = (__bridge NSString *)CFUUIDCreateString(nil, uuidObj);
    CFRelease(uuidObj);
    return uuidString;
}
-(NSString*)localImageURL {
    return [NSString stringWithFormat:@"http://localhost/images/%@.png", [self guid]];
}

-(NSString*)localAudioURL {
    return [NSString stringWithFormat:@"http://localhost/audios/%@.m4a", [self guid]];
}

-(NSString*)localVideoURL {
    return [NSString stringWithFormat:@"http://localhost/videos/%@.mp4", [self guid]];
}

-(NSString*)localFileURL:(NSString*)ext {
    if (ext.length > 0) {
        return [NSString stringWithFormat:@"http://localhost/files/%@.%@", [self guid], ext];
    } else {
        return [NSString stringWithFormat:@"http://localhost/files/%@", [self guid]];
    }
}

-(void)revokeMessage:(IMessage*)message {
    int now = (int)time(NULL);
    if (message.uuid.length == 0) {
        return;
    }
    if (now - message.timestamp > REVOKE_EXPIRE) {
        [self.view makeToast:NSLocalizedString(@"message.revokeTimeout", nil) duration:0.7 position:CSToastPositionBottom];
        return;
    }
    
    if ([IMService.instance connectState] != STATE_CONNECTED) {
        [self.view makeToast:NSLocalizedString(@"message.revokeFailure", nil) duration:0.7 position:CSToastPositionBottom];
        return;
    }
    
    MessageRevoke *revoke = [[MessageRevoke alloc] initWithMsgId:message.uuid];
    IMessage *imsg = [self newOutMessage:revoke];
    [self sendMessage:imsg];
}

-(void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    [self eraseMessageFailure:message];
    [self sendMessage:message];
}

-(id<IMessageIterator>)newMessageIterator {
    NSAssert(NO, @"not implement");
    return nil;
}

//下拉刷新
-(id<IMessageIterator>)newForwardMessageIterator:(int64_t)messageID {
    NSAssert(NO, @"not implement");
    return nil;
}
//上拉刷新
-(id<IMessageIterator>)newBackwardMessageIterator:(int64_t)messageID {
    NSAssert(NO, @"not implement");
    return nil;
}

-(BOOL)getMessageOutgoing:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}

-(IMessage*)newOutMessage:(MessageContent*)content {
    NSAssert(NO, @"not implement");
    return nil;
}

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    NSAssert(NO, @"not implement");
}

- (void)sendMessage:(IMessage*)message {
    NSAssert(NO, @"not implement");
}

- (IUser*)getUser:(int64_t)uid {
    return nil;
}

- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb {
     NSLog(@"not implement");
}

@end
