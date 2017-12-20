//
//  NSDate+Format.h
//  gobelieve
//
//  Created by houxh on 2017/11/11.
//

#import <Foundation/Foundation.h>

@interface NSDate(Format)
- (NSString *)getWeekDayString:(NSInteger)iDay;
- (BOOL)isSameDay:(NSDate*)date;
- (BOOL)isYestoday;
- (BOOL)isBeforeYestoday;
- (BOOL)isInWeek;
- (BOOL)isInMonth;
- (BOOL)isInYear;

- (NSDateComponents*)getComponentOfDate;
- (NSString *)getConversationTimeString;
- (NSString*)formatSectionTime;
@end
