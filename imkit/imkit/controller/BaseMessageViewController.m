/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "BaseMessageViewController.h"
#import <AudioToolbox/AudioServices.h>
#import "IMessage.h"


@interface BaseMessageViewController ()

@end

@implementation BaseMessageViewController

- (id)init {
    self = [super init];
    if (self) {
        self.messages = [NSMutableArray array];
        self.attachments = [NSMutableDictionary dictionary];
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

- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image {
    NSAssert(NO, @"not implement");
}

- (void)sendMessage:(IMessage*)msg {
    NSAssert(NO, @"not implement");
}


- (void)viewDidLoad {
    [super viewDidLoad];
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
            IMessage *m = [[IMessage alloc] init];
            m.rawContent = tb.raw;
            [newMessages addObject:m];
            lastDate = [NSDate dateWithTimeIntervalSince1970:msg.timestamp];
        }
        
        [newMessages addObject:msg];
    }
    
    self.messages = newMessages;
}


- (void)insertMessage:(IMessage*)msg {
    NSDate *lastDate = nil;
    NSInteger count = [self.messages count];
    
    for (NSInteger i = count; i > 0; i--) {
        IMessage *m = [self.messages objectAtIndex:i-1];
        if (m.type == MESSAGE_TIME_BASE) {
            lastDate = [NSDate dateWithTimeIntervalSince1970:m.timeBaseContent.timestamp];
            break;
        }
    }
    
    NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
    if (lastDate == nil || msg.timestamp - lastDate.timeIntervalSince1970 > 1*60) {
        MessageTimeBaseContent *tb = [[MessageTimeBaseContent alloc] initWithTimestamp:msg.timestamp];
        IMessage *m = [[IMessage alloc] init];
        m.rawContent = tb.raw;
        [self.messages addObject:m];
        NSIndexPath *indexPath = nil;
        indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
        [indexPaths addObject:indexPath];
    }
    [self.messages addObject:msg];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [indexPaths addObject:indexPath];

    [UIView beginAnimations:nil context:NULL];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    [self scrollToBottomAnimated:NO];
    [UIView commitAnimations];

}

- (void)scrollToBottomAnimated:(BOOL)animated
{
    if (self.messages.count == 0) {
        return;
    }
    long lastRow = [self.messages count] - 1;
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRow inSection:0]
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:animated];
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

- (NSString *)getConversationTimeString:(NSDate *)date{
    NSString *format = @"MM-dd HH:mm";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:format];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [formatter stringFromDate:date];
}

- (NSString*)formatSectionTime:(NSDate*)date {
    NSDate *curtDate = date;
    NSDateComponents *components = [self getComponentOfDate:curtDate];
    NSDate *todayDate = [NSDate date];
    NSString *timeStr = nil;
    if ([self isSameDay:curtDate other:todayDate]) {
        timeStr = [NSString stringWithFormat:@"%02zd:%02zd",components.hour,components.minute];
    } else if ([self isYestoday:curtDate]) {
        timeStr = [NSString stringWithFormat:@"昨天 %02zd:%02zd",components.hour,components.minute];
    } else if ([self isInWeek:curtDate]) {
        NSString *s = [self getWeekDayString: components.weekday];
        timeStr = [NSString stringWithFormat:@"%@ %02zd:%02zd", s, components.hour,components.minute];
    } else if ([self isInYear:curtDate]) {
        NSString *format = @"MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        timeStr = [formatter stringFromDate:curtDate];
    } else {
        NSString *format = @"yyy-MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        timeStr = [formatter stringFromDate:curtDate];
    }
    
    return timeStr;
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
            return @"";
    }
    return nil;
}

- (BOOL)isSameDay:(NSDate*)date1 other:(NSDate*)date2 {
    NSDateComponents *c1 = [self getComponentOfDate:date1];
    NSDateComponents *c2 = [self getComponentOfDate:date2];
    return c1.year == c2.year && c1.month == c2.month && c1.day == c2.day;
}

- (BOOL)isYestoday:(NSDate*)date {
    NSDate *now = [NSDate date];
    NSDate *y = [now dateByAddingTimeInterval:-24*3600];
    return [self isSameDay:date other:y];
}
- (BOOL)isBeforeYestoday:(NSDate*)date {
    NSDate *now = [NSDate date];
    NSDate *y = [now dateByAddingTimeInterval:-2*24*3600];
    return [self isSameDay:y other:date];
}

-(BOOL)isInWeek:(NSDate*)date {
    NSDate *now = [NSDate date];
    NSDate *t = [now dateByAddingTimeInterval:-7*24*3600];
    return [t compare:date] == NSOrderedAscending && ![self isSameDay:t other:date];
}

- (BOOL)isInMonth:(NSDate*)date {
    NSDate *now = [NSDate date];
    NSDate *t = [now dateByAddingTimeInterval:-30*24*3600];
    return [t compare:date] == NSOrderedAscending;
}

-(BOOL)isInYear:(NSDate*)date {
    NSDate *now = [NSDate date];
    
    NSDateComponents *c1 = [self getComponentOfDate:now];
    NSDateComponents *c2 = [self getComponentOfDate:date];
    
    return c1.year == c2.year;
}

@end
