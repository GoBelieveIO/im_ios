//
//  BaseMessageViewController.m
//  imkit
//
//  Created by houxh on 15/3/17.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import "BaseMessageViewController.h"
#import <imsdk/IMService.h>
#import <AudioToolbox/AudioServices.h>
#import "UIImageView+WebCache.h"
#import "IMessage.h"
//#import "PeerMessageDB.h"
#import "Constants.h"

#import "FileCache.h"
#import "Outbox.h"
#import "AudioDownloader.h"
#import "UIImage+Resize.h"



@interface BaseMessageViewController ()<AudioDownloaderObserver, OutboxObserver>

@end

@implementation BaseMessageViewController

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray array];
        self.names = [NSMutableDictionary dictionary];
    }
    return self;
}

- (int64_t)sender {
    NSAssert(NO, @"not implement");
    return 0;
}

- (int64_t)receiver {
    NSAssert(NO, @"not implement");
    return 0;
}

- (void)loadConversationData {
    NSAssert(NO, @"not implement");
}

- (void)loadEarlierData {
    NSAssert(NO, @"not implement");
}

- (BOOL)isInConversation:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}

-(BOOL)saveMessage:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}
-(BOOL)removeMessage:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}
-(BOOL)markMessageFailure:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}
-(BOOL)markMesageListened:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}

-(BOOL)eraseMessageFailure:(IMessage*)msg {
    NSAssert(NO, @"not implement");
    return NO;
}

- (void)sendMessage:(IMessage*)msg {
    NSAssert(NO, @"not implement");
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)addObserver {
    [[IMService instance] addMessageObserver:self];
    [[Outbox instance] addBoxObserver:self];
    [[AudioDownloader instance] addDownloaderObserver:self];
}

-(void)removeObserver {
    [[IMService instance] removeMessageObserver:self];
    [[Outbox instance] removeBoxObserver:self];
    [[AudioDownloader instance] removeDownloaderObserver:self];
}

-(void)initTableViewData {
    self.messageArray = [NSMutableArray array];
    self.timestamps = [NSMutableArray array];
    
    NSInteger count = [self.messages count];
    if (count == 0) {
        return;
    }
    
    NSDate *lastDate = nil;
    NSDate *curtDate = nil;
    NSMutableArray *msgBlockArray = nil;
    
    for (NSInteger i = count-1; i >= 0; i--) {
        IMessage *msg = [self.messages objectAtIndex:i];
        
        FileCache *cache = [FileCache instance];
        AudioDownloader *downloader = [AudioDownloader instance];
        if (msg.content.type == MESSAGE_AUDIO) {
            NSString *path = [cache queryCacheForKey:msg.content.audio.url];
            if (!path && ![downloader isDownloading:msg]) {
                [downloader downloadAudio:msg];
            }
        }
        
        curtDate = [NSDate dateWithTimeIntervalSince1970: msg.timestamp];
        if ([self isSameDay:lastDate other:curtDate]) {
            [msgBlockArray insertObject:msg atIndex:0];
        } else {
            msgBlockArray  = [NSMutableArray arrayWithObject:msg];
            
            [self.messageArray insertObject:msgBlockArray atIndex:0];
            [self.timestamps insertObject:curtDate atIndex:0];
            lastDate = curtDate;
        }
    }
}



- (void)insertMessage:(IMessage*)msg {
    NSAssert(msg.msgLocalID, @"");
    [self.messages addObject:msg];
    NSDate *curtDate = [NSDate dateWithTimeIntervalSince1970: msg.timestamp];
    NSMutableArray *msgBlockArray = nil;
    NSIndexPath *indexPath = nil;
    //收到第一个消息
    if ([self.messageArray count] == 0 ) {
        
        msgBlockArray = [[NSMutableArray alloc] init];
        [self.messageArray addObject: msgBlockArray];
        [msgBlockArray addObject:msg];
        
        [self.timestamps addObject: curtDate];
        
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        
    }else{
        NSDate *lastDate = [self.timestamps lastObject];
        if ([self isSameDay:lastDate other:curtDate]) {
            //same day
            msgBlockArray = [self.messageArray lastObject];
            [msgBlockArray addObject:msg];
            
            indexPath = [NSIndexPath indexPathForRow:[msgBlockArray count] - 1 inSection: [self.messageArray count] - 1];
        }else{
            //next day
            msgBlockArray = [[NSMutableArray alloc] init];
            [msgBlockArray addObject: msg];
            [self.messageArray addObject: msgBlockArray];
            [self.timestamps addObject:curtDate];
            indexPath = [NSIndexPath indexPathForRow:[msgBlockArray count] - 1 inSection: [self.messageArray count] - 1];
        }
    }
    
    [UIView beginAnimations:nil context:NULL];
    if (indexPath.row == 0 ) {
        
        NSUInteger sectionCount = indexPath.section;
        NSIndexSet *indices = [NSIndexSet indexSetWithIndex: sectionCount];
        [self.tableView beginUpdates];
        [self.tableView insertSections:indices withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
        
    }else{
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        [indexPaths addObject:indexPath];
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView endUpdates];
    }
    
    [self scrollToBottomAnimated:NO];
    
    [UIView commitAnimations];
}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if([self.messageArray count] == 0){
        return;
    }
    
    long lastSection = [self.messageArray count] - 1;
    NSMutableArray *array = [self.messageArray objectAtIndex: lastSection];
    long lastRow = [array count]-1;
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:lastSection]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:animated];
}








- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSMutableArray *array = [self.messageArray objectAtIndex: indexPath.section];
    IMessage *msg =  ((IMessage*)[array objectAtIndex:indexPath.row]);
    if(msg){
        return msg;
    }
    return nil;
}


- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.timestamps objectAtIndex:indexPath.row];
}


- (IMessage*)getMessageWithID:(int)msgLocalID {
    
    for ( long sectionIndex = [self.messageArray count] - 1; sectionIndex >= 0; sectionIndex--) {
        
        NSMutableArray *rowArrays = [self.messageArray objectAtIndex:sectionIndex];
        for (long rowindex = [rowArrays count ] - 1;rowindex >= 0 ; rowindex--) {
            
            IMessage *tmpMsg = (IMessage*) [rowArrays objectAtIndex:rowindex];
            if (tmpMsg.msgLocalID == msgLocalID) {
                return tmpMsg;
            }
        }
    }
    return nil;
}

- (void)reloadMessage:(int)msgLocalID {
    
    for (long sectionIndex = [self.messageArray count] - 1; sectionIndex >= 0; sectionIndex--) {
        
        NSMutableArray *rowArrays = [self.messageArray objectAtIndex:sectionIndex];
        for (long rowindex = [rowArrays count ] - 1;rowindex >= 0 ; rowindex--) {
            
            IMMessage *tmpMsg = [rowArrays objectAtIndex:rowindex];
            if (tmpMsg.msgLocalID == msgLocalID) {
                
                NSIndexPath *findpath = [NSIndexPath indexPathForRow:rowindex inSection: sectionIndex];
                NSArray *array = [NSArray arrayWithObject:findpath];
                [self.tableView reloadRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationNone];
            }
        }
    }
}


- (NSIndexPath*)getIndexPathById:(int)msgLocalID {
    for ( long sectionIndex = [self.messageArray count] - 1; sectionIndex >= 0; sectionIndex--) {
        
        NSMutableArray *rowArrays = [self.messageArray objectAtIndex:sectionIndex];
        for (long rowindex = [rowArrays count ] - 1;rowindex >= 0 ; rowindex--) {
            
            IMMessage *tmpMsg = [rowArrays objectAtIndex:rowindex];
            if (tmpMsg.msgLocalID == msgLocalID) {
                
                NSIndexPath *findpath = [NSIndexPath indexPathForRow:rowindex inSection: sectionIndex];
                return findpath;
            }
        }
    }
    return nil;
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

- (void)sendAudioMessage:(NSString*)path second:(int)second {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    
    Audio *audio = [[Audio alloc] init];
    audio.url = [self localAudioURL];
    audio.duration = second;
    MessageContent *content = [[MessageContent alloc] initWithAudio:audio];
    msg.content = content;
    msg.timestamp = (int)time(NULL);
    
    //todo 优化读文件次数
    NSData *data = [NSData dataWithContentsOfFile:path];
    FileCache *fileCache = [FileCache instance];
    [fileCache storeFile:data forKey:audio.url];
    
    [self saveMessage:msg];
    
    [[Outbox instance] uploadAudio:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


- (void)sendImageMessage:(UIImage*)image {
    if (image.size.height == 0) {
        return;
    }
    
    
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageContent *content = [[MessageContent alloc] initWithImageURL:[self localImageURL]];
    msg.content = content;
    msg.timestamp = (int)time(NULL);

    float newHeigth = 640;
    float newWidth = newHeigth*image.size.width/image.size.height;
    
    UIImage *sizeImage = [image resizedImage:CGSizeMake(128, 128) interpolationQuality:kCGInterpolationDefault];
    image = [image resizedImage:CGSizeMake(newWidth, newHeigth) interpolationQuality:kCGInterpolationDefault];
    
    [[SDImageCache sharedImageCache] storeImage:image forKey:msg.content.imageURL];
    NSString *littleUrl =  [msg.content littleImageURL];
    [[SDImageCache sharedImageCache] storeImage:sizeImage forKey: littleUrl];
    
    [self saveMessage:msg];
    
    [[Outbox instance] uploadImage:msg image:image];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}

-(void) sendTextMessage:(NSString*)text {
    IMessage *msg = [[IMessage alloc] init];
    
    msg.sender = self.sender;
    msg.receiver = self.receiver;
    
    MessageContent *content = [[MessageContent alloc] initWithText:text];
    msg.content = content;
    msg.timestamp = (int)time(NULL);
    
    [self saveMessage:msg];
    
    [self sendMessage:msg];
    
    [[self class] playMessageSentSound];
    
    [self insertMessage:msg];
}


-(void)resendMessage:(IMessage*)message {
    message.flags = message.flags & (~MESSAGE_FLAG_FAILURE);
    
    [self eraseMessageFailure:message];
    
    if (message.content.type == MESSAGE_AUDIO) {
        [[Outbox instance] uploadAudio:message];
    } else if (message.content.type == MESSAGE_IMAGE) {
        UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:message.content.imageURL];
        if (!image) {
            return;
        }
        [[Outbox instance] uploadImage:message image:image];
    } else {
        [self sendMessage:message];
    }
    
    [self reloadMessage:message.msgLocalID];
}



#pragma mark - Outbox Observer
- (void)onAudioUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        [self reloadMessage:msg.msgLocalID];
    }
}

-(void)onAudioUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        [self reloadMessage:msg.msgLocalID];
    }
}

- (void)onImageUploadSuccess:(IMessage*)msg URL:(NSString*)url {
    if ([self isInConversation:msg]) {
        [self reloadMessage:msg.msgLocalID];
    }
}

- (void)onImageUploadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        msg.flags = msg.flags|MESSAGE_FLAG_FAILURE;
        [self reloadMessage:msg.msgLocalID];
    }
}

#pragma mark - Audio Downloader Observer
- (void)onAudioDownloadSuccess:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        [self reloadMessage:msg.msgLocalID];
    }
}

- (void)onAudioDownloadFail:(IMessage*)msg {
    if ([self isInConversation:msg]) {
        [self reloadMessage:msg.msgLocalID];
    }
}

#pragma mark - function
- (NSDateComponents*) getComponentOfDate:(NSDate *)date {
    if (date == nil) {
        return nil;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|\
    NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
    comps = [calendar components:unitFlags fromDate:date];
    return comps;
}

- (NSString *) getConversationTimeString:(NSDate *)date{
    NSString *format = @"MM-dd HH:mm";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:format];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [formatter stringFromDate:date];
}

// 从数字获取对应的周时间字符串
- (NSString *) getWeekDayString:(NSInteger)iDay {
    switch (iDay) {
        case 1:
            return @"周日";
            break;
        case 2:
            return @"周一";
            break;
        case 3:
            return @"周二";
            break;
        case 4:
            return @"周三";
            break;
        case 5:
            return @"周四";
            break;
        case 6:
            return @"周五";
            break;
        case 7:
            return @"周六";
            break;
        default:
            return nil;
    }
    return nil;
}

- (BOOL)isSameDay:(NSDate*)date1 other:(NSDate*)date2 {
    NSDateComponents *c1 = [self getComponentOfDate:date1];
    NSDateComponents *c2 = [self getComponentOfDate:date2];
    return c1.year == c2.year && c1.month == c2.month && c1.day == c2.day;
}

- (BOOL)isYestoday:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *y = [date1 dateByAddingTimeInterval:-24*3600];
    return [self isSameDay:y other:date2];
}
- (BOOL)isBeforeYestoday:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *y = [date1 dateByAddingTimeInterval:-2*24*3600];
    return [self isSameDay:y other:date2];
}

-(BOOL)isInWeek:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *t = [date1 dateByAddingTimeInterval:-7*24*3600];
    return [t compare:date2] == NSOrderedAscending && ![self isSameDay:t other:date2];
}

- (BOOL)isInMonth:(NSDate*)date1 today:(NSDate*)date2 {
    NSDate *t = [date1 dateByAddingTimeInterval:-30*24*3600];
    return [t compare:date2] == NSOrderedAscending;
}


@end
