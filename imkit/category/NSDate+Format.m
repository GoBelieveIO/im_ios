//
//  NSDate+Format.m
//  gobelieve
//
//  Created by houxh on 2017/11/11.
//

#import "NSDate+Format.h"

@implementation NSDate(Format)

- (NSDateComponents*) getComponentOfDate {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    NSInteger unitFlags = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|\
    NSCalendarUnitWeekday|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
    comps = [calendar components:unitFlags fromDate:self];
    return comps;
}


- (NSString *)getConversationTimeString{
    NSString *format = @"MM-dd HH:mm";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateFormat:format];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    return [formatter stringFromDate:self];
}

- (NSString*)formatSectionTime {
    NSDateComponents *components = [self getComponentOfDate];
    NSDate *todayDate = [NSDate date];
    NSString *timeStr = nil;
    if ([self isSameDay:todayDate]) {
        timeStr = [NSString stringWithFormat:@"%02zd:%02zd",components.hour,components.minute];
    } else if ([self isYestoday]) {
        timeStr = [NSString stringWithFormat:@"昨天 %02zd:%02zd",components.hour,components.minute];
    } else if ([self isInWeek]) {
        NSString *s = [self getWeekDayString: components.weekday];
        timeStr = [NSString stringWithFormat:@"%@ %02zd:%02zd", s, components.hour,components.minute];
    } else if ([self isInYear]) {
        NSString *format = @"MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        timeStr = [formatter stringFromDate:self];
    } else {
        NSString *format = @"yyy-MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        timeStr = [formatter stringFromDate:self];
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

- (BOOL)isSameDay:(NSDate*)date  {
    NSDateComponents *c1 = [self getComponentOfDate];
    NSDateComponents *c2 = [date getComponentOfDate];
    return c1.year == c2.year && c1.month == c2.month && c1.day == c2.day;
}

- (BOOL)isYestoday {
    NSDate *now = [NSDate date];
    NSDate *y = [now dateByAddingTimeInterval:-24*3600];
    return [self isSameDay:y];
}
- (BOOL)isBeforeYestoday {
    NSDate *now = [NSDate date];
    NSDate *y = [now dateByAddingTimeInterval:-2*24*3600];
    return [self isSameDay:y];
}

-(BOOL)isInWeek {
    NSDate *now = [NSDate date];
    NSDate *t = [now dateByAddingTimeInterval:-7*24*3600];
    return [t compare:self] == NSOrderedAscending && ![self isSameDay:t];
}

- (BOOL)isInMonth {
    NSDate *now = [NSDate date];
    NSDate *t = [now dateByAddingTimeInterval:-30*24*3600];
    return [t compare:self] == NSOrderedAscending;
}

-(BOOL)isInYear {
    NSDate *now = [NSDate date];
    
    NSDateComponents *c1 = [now getComponentOfDate];
    NSDateComponents *c2 = [self getComponentOfDate];
    
    return c1.year == c2.year;
}
@end
