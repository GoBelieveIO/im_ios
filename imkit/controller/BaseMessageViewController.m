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
#import <SDWebImage/SDWebImage.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AudioToolbox/AudioServices.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "UIImage+Resize.h"
#import "NSDate+Format.h"
#import "UIView+Toast.h"
#import "AVURLAsset+Video.h"
#import "IMessage.h"
#import "FileCache.h"
#import "AudioDownloader.h"

//应用启动时间
static int uptime = 0;

@interface BaseMessageViewController ()

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


- (id)init {
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray array];
        self.attachments = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    [self.messageDB saveMessageAttachment:msg address:address];
}


-(BOOL)saveMessage:(IMessage*)msg {
    return [self.messageDB saveMessage:msg];
}

-(BOOL)removeMessage:(IMessage*)msg {
    return [self.messageDB removeMessage:msg.msgLocalID];
}

-(BOOL)markMessageFailure:(IMessage*)msg {
    return [self.messageDB markMessageFailure:msg.msgLocalID];
    
}

-(BOOL)markMesageListened:(IMessage*)msg {
    return [self.messageDB markMesageListened:msg.msgLocalID];
    
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    return [self.messageDB eraseMessageFailure:msg.msgLocalID];
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
    [self downloadMessageContent:self.messages count:count];
    [self updateNotificationDesc:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    [self loadSenderInfo:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    [self checkAtName:self.messages count:count];
    
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
    
    NSArray *newMessages = [self loadEarlierData:last.msgLocalID];
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
    
    
    [self loadSenderInfo:self.messages count:count];
    [self downloadMessageContent:self.messages count:count];
    [self updateNotificationDesc:self.messages count:count];
    [self checkMessageFailureFlag:self.messages count:count];
    [self checkAtName:self.messages count:count];
    
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
-(int)loadLateData {
    int newCount = 0;
    if (!self.hasLateMore || self.messages.count == 0) {
        return newCount;
    }
    int messageID = 0;
    for (NSInteger i = self.messages.count - 1; i > 0; i--) {
        IMessage *msg = [self.messages objectAtIndex:i];
        if (msg.msgLocalID) {
            messageID = msg.msgLocalID;
            break;
        }
    }
    
    if (messageID == 0) {
        return newCount;
    }
    
    NSArray *newMessages = [self loadLateData:messageID];
    
    if (newMessages.count == 0) {
        self.hasLateMore = NO;
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
    [self loadSenderInfo:newMessages count:count];
    [self downloadMessageContent:newMessages count:count];
    [self updateNotificationDesc:newMessages count:count];
    [self checkMessageFailureFlag:newMessages count:count];
    [self checkAtName:newMessages count:count];
    
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
    
    iterator = [self.messageDB newMessageIterator: self.conversationID];
    pageSize = PAGE_COUNT;
    
    
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
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= pageSize) {
                break;
            }
        }
        
        msg = [iterator next];
    }
    
    
    return messages;
}

//navigator from search
- (NSArray*)loadConversationData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    int count = 0;
    id<IMessageIterator> iterator;
    
    IMessage *msg = [self.messageDB getMessage:messageID];
    if (!msg) {
        return nil;
    }
    [messages addObject:msg];
    
    iterator = [self.messageDB newBackwardMessageIterator:self.conversationID messageID:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        
        msg = [iterator next];
    }
    
    count = 0;
    iterator = [self.messageDB newForwardMessageIterator:self.conversationID last:messageID];
    msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    return messages;
}


- (NSArray*)loadEarlierData:(int)messageID {
    NSMutableArray *messages = [NSMutableArray array];
    
    id<IMessageIterator> iterator =  [self.messageDB newForwardMessageIterator:self.conversationID last:messageID];
    
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [messages insertObject:msg atIndex:0];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    NSLog(@"load earlier messages:%d", count);
    return messages;
}

//加载后面的聊天记录
-(NSArray*)loadLateData:(int)messageID {
    id<IMessageIterator> iterator = [self.messageDB newBackwardMessageIterator:self.conversationID messageID:messageID];
    NSMutableArray *newMessages = [NSMutableArray array];
    int count = 0;
    IMessage *msg = [iterator next];
    while (msg) {
        if (msg.type == MESSAGE_ATTACHMENT) {
            MessageAttachmentContent *att = msg.attachmentContent;
            [self.attachments setObject:att
                                 forKey:[NSNumber numberWithInt:att.msgLocalID]];
            
        } else {
            msg.isOutgoing = (msg.sender == self.currentUID);
            [newMessages addObject:msg];
            if (++count >= PAGE_COUNT) {
                break;
            }
        }
        msg = [iterator next];
    }
    
    NSLog(@"load late messages:%d", count);
    return newMessages;
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
        if (m.msgLocalID == msg.msgLocalID) {
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
        if (m.msgLocalID == msg.msgLocalID) {
            index = i;
        }
    }
    if (index != -1) {
        [self.messages replaceObjectAtIndex:index withObject:other];
    }
    return (int)index;
}

- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    IMessage *msg = [self.messages objectAtIndex: indexPath.row];
    return msg;
}

- (IMessage*)getMessageWithID:(int)msgLocalID {
    for (IMessage *msg in self.messages) {
        if (msg.msgLocalID == msgLocalID) {
            return msg;
        }
    }
    return nil;
}

- (IMessage*)getMessageWithUUID:(NSString*)uuid {
    if (uuid.length == 0) {
        return nil;
    }
    for (IMessage *msg in self.messages) {
        if ([msg.uuid isEqualToString:uuid]) {
            return msg;
        }
    }
    return nil;
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

-(void)checkMessageFailureFlag:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkMessageFailureFlag:msg];
    }
}

-(void)checkAtName:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self checkAtName:msg];
    }
}

-(void)checkAtName:(IMessage*)msg {

}


- (void)updateNotificationDesc:(IMessage*)message {
    if (message.type == MESSAGE_GROUP_NOTIFICATION) {
        MessageGroupNotificationContent *notification = message.groupNotificationContent;
        int type = notification.notificationType;
        if (type == NOTIFICATION_GROUP_CREATED) {
            if (self.currentUID == notification.master) {
                NSString *desc = [NSString stringWithFormat:@"您创建了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            } else {
                NSString *desc = [NSString stringWithFormat:@"您加入了\"%@\"群组", notification.groupName];
                notification.notificationDesc = desc;
            }
        } else if (type == NOTIFICATION_GROUP_DISBANDED) {
            notification.notificationDesc = @"群组已解散";
        } else if (type == NOTIFICATION_GROUP_MEMBER_ADDED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@加入群", name];
                notification.notificationDesc = desc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@加入群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_MEMBER_LEAVED) {
            IUser *u = [self getUser:notification.member];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@离开群", name];
                notification.notificationDesc = desc;
                [self asyncGetUser:notification.member cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@离开群", u.name];
                    notification.notificationDesc = desc;
                }];
            }
        } else if (type == NOTIFICATION_GROUP_NAME_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群组更名为%@", notification.groupName];
            notification.notificationDesc = desc;
        } else if (type == NOTIFICATION_GROUP_NOTICE_UPDATED) {
            NSString *desc = [NSString stringWithFormat:@"群公告:%@", notification.notice];
            notification.notificationDesc = desc;
        }
    } else if (message.type == MESSAGE_GROUP_VOIP) {
        MessageGroupVOIPContent *content = (MessageGroupVOIPContent*)message.groupVOIPContent;
        if (content.finished) {
            content.notificationDesc = @"语音通话已经结束";
        } else {
            IUser *u = [self getUser:content.initiator];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", name];
                content.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", name];
                content.notificationDesc = desc;
                [self asyncGetUser:content.initiator cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"%@发起了语音聊天", u.name];
                    content.notificationDesc = desc;
                }];
            }
        }
    } else if (message.type == MESSAGE_REVOKE) {
        MessageRevoke *content = message.revokeContent;
        if (message.isOutgoing) {
            content.notificationDesc = @"你撤回了一条消息";
        } else {
            IUser *u = [self getUser:message.sender];
            if (u.name.length > 0) {
                NSString *name = u.name;
                NSString *desc = [NSString stringWithFormat:@"\"%@\"撤回了一条消息", name];
                content.notificationDesc = desc;
            } else {
                NSString *name = u.identifier;
                NSString *desc = [NSString stringWithFormat:@"\"%@\"撤回了一条消息", name];
                content.notificationDesc = desc;
                [self asyncGetUser:message.sender cb:^(IUser *u) {
                    NSString *desc = [NSString stringWithFormat:@"\"%@\"撤回了一条消息", u.name];
                    content.notificationDesc = desc;
                }];
            }
        }
    } else if (message.type == MESSAGE_ACK) {
        MessageACK *ack = message.ackContent;
        if (ack.error == MSG_ACK_NOT_YOUR_FRIEND) {
            ack.notificationDesc = @"你还不是他（她）朋友";
        } else if (ack.error == MSG_ACK_IN_YOUR_BLACKLIST) {
            ack.notificationDesc = @"消息已发出，但被对方拒收了。";
        } else if (ack.error == MSG_ACK_NOT_MY_FRIEND) {
            ack.notificationDesc = @"对方已不是你的朋友";
        }
    }
}

- (void)updateNotificationDesc:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self updateNotificationDesc:msg];
    }
}


- (void)downloadMessageContent:(IMessage*)msg {
    FileCache *cache = [FileCache instance];
    AudioDownloader *downloader = [AudioDownloader instance];
    if (msg.type == MESSAGE_AUDIO) {
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:msg.msgLocalID]];
        
        if (attachment.url.length > 0) {
            MessageAudioContent *content = [msg.audioContent cloneWithURL:attachment.url];
            msg.rawContent = content.raw;
        }
        
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
        //加载附件中的地址
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:msg.msgLocalID]];
        if (attachment && attachment.address) {
            content.address = attachment.address;
        }
        
        if (content.address.length == 0) {
            [self reverseGeocodeLocation:msg];
        }
    } else if (msg.type == MESSAGE_IMAGE) {
        NSLog(@"image url:%@", msg.imageContent.imageURL);
        MessageAttachmentContent *attachment = [self.attachments objectForKey:[NSNumber numberWithInt:msg.msgLocalID]];
        
        if (attachment.url.length > 0) {
            MessageImageContent *content = [msg.imageContent cloneWithURL:attachment.url];
            msg.rawContent = content.raw;
        }
        
        
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

- (void)downloadMessageContent:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self downloadMessageContent:msg];
    }
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
            content.address = placemark.name;
            
            [self saveMessageAttachment:msg address:placemark.name];
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


#pragma mark - send message
- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address {
    IMessage *msg = [self newOutMessage];
    
    MessageLocationContent *content = [[MessageLocationContent alloc] initWithLocation:location];
    msg.rawContent = content.raw;
    
    content = msg.locationContent;
    content.address = address;
    
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    [self saveMessage:msg];
    [self sendMessage:msg];
    
    [self createMapSnapshot:msg];
    if (content.address.length == 0) {
        [self reverseGeocodeLocation:msg];
    } else {
        [self saveMessageAttachment:msg address:content.address];
    }
    [self insertMessage:msg];
}

- (void)sendAudioMessage:(NSString*)path second:(int)second {
    IMessage *msg = [self newOutMessage];
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
        [self.view makeToast:@"拍摄时间太短了" duration:0.7 position:@"bottom"];
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
    [self convertVideoToLowQuailtyWithInputURL:url outputURL:mp4URL handler:^(AVAssetExportSession *es) {
        NSLog(@"convert video asset export session status:%d", (int)es.status);
        if (es.status == AVAssetExportSessionStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MessageVideoContent *content = [[MessageVideoContent alloc] initWithVideoURL:videoURL
                                                                                   thumbnail:thumbURL
                                                                                       width:width
                                                                                      height:height
                                                                                    duration:duration
                                                                                        size:size];
                IMessage *msg = [self newOutMessage];
                msg.rawContent = content.raw;
                msg.timestamp = (int)time(NULL);
                msg.isOutgoing = YES;
                [self loadSenderInfo:msg];
                [self saveMessage:msg];
                [self sendMessage:msg];
                [self insertMessage:msg];
            });
        }
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
    
    IMessage *msg = [self newOutMessage];
    MessageImageContent *content = [[MessageImageContent alloc] initWithImageURL:[self localImageURL] width:newWidth height:newHeight];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    
    [self loadSenderInfo:msg];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:content.imageURL completion:nil];
    NSString *littleUrl =  [content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl completion:nil];
    
    [self saveMessage:msg];
    
    [self sendMessage:msg withImage:image];
    [self insertMessage:msg];
}

-(void) sendTextMessage:(NSString*)text at:(NSArray*)atUsers atNames:(NSArray*)atNames {
    IMessage *msg = [self newOutMessage];
    
    MessageTextContent *content = [[MessageTextContent alloc] initWithText:text at:atUsers atNames:atNames];
    msg.rawContent = content.raw;
    msg.timestamp = (int)time(NULL);
    msg.isOutgoing = YES;
    [self loadSenderInfo:msg];
    [self saveMessage:msg];
    [self sendMessage:msg];
    [self insertMessage:msg];
}


- (void)loadSenderInfo:(IMessage*)msg {
    msg.senderInfo = [self getUser:msg.sender];
    if (msg.senderInfo.name.length == 0) {
        [self asyncGetUser:msg.sender cb:^(IUser *u) {
            msg.senderInfo = u;
        }];
    }
}
- (void)loadSenderInfo:(NSArray*)messages count:(int)count {
    for (int i = 0; i < count; i++) {
        IMessage *msg = [messages objectAtIndex:i];
        [self loadSenderInfo:msg];
    }
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL outputURL:(NSURL*)outputURL handler:(void (^)(AVAssetExportSession*))handler {
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        handler(exportSession);
    }];
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

-(void)revokeMessage:(IMessage*)message {
    int now = (int)time(NULL);
    if (message.uuid.length == 0) {
        return;
    }
    if (now - message.timestamp > REVOKE_EXPIRE) {
        [self.view makeToast:@"已经超过消息撤回的时间" duration:0.7 position:@"bottom"];
        return;
    }
    
    if ([IMService.instance connectState] != STATE_CONNECTED) {
        [self.view makeToast:@"网络连接断开，撤回失败" duration:0.7 position:@"bottom"];
        return;
    }
    
    MessageRevoke *revoke = [[MessageRevoke alloc] initWithMsgId:message.uuid];
    IMessage *imsg = [self newOutMessage];
    imsg.timestamp = now;
    imsg.content = revoke;
    imsg.isOutgoing = YES;
    [self sendMessage:imsg];
}

-(void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    [self eraseMessageFailure:message];
    [self sendMessage:message];
}

-(IMessage*)newOutMessage {
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
    return [self.userDelegate getUser:uid];
}

- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb {
    [self.userDelegate asyncGetUser:uid cb:cb];
}

@end
