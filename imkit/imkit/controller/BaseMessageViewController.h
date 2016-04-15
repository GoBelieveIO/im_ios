/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "IMService.h"
#import "IMessage.h"

//基类处理tableview相关的数据
@interface BaseMessageViewController : UIViewController


//protected
@property(nonatomic) NSMutableArray *messages;
@property(nonatomic) NSMutableDictionary *attachments;

@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) UITableView *tableView;

@property(nonatomic) int lastReceivedTimestamp;

//是否只展示文本消息
@property(nonatomic) BOOL textMode;


//protected overwrite by derived class
- (BOOL)markMesageListened:(IMessage*)msg;
- (void)loadConversationData;
- (void)loadEarlierData;


- (void)initTableViewData;

- (void)insertMessage:(IMessage*)msg;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (IMessage*)getMessageWithID:(int)msgLocalID;
- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSString *)getWeekDayString:(NSInteger)iDay;
- (BOOL)isSameDay:(NSDate*)date1 other:(NSDate*)date2 ;
- (BOOL)isYestoday:(NSDate*)date;
- (BOOL)isBeforeYestoday:(NSDate*)date;
- (BOOL)isInWeek:(NSDate*)date;
- (BOOL)isInMonth:(NSDate*)date;
- (BOOL)isInYear:(NSDate*)date;
- (NSDateComponents*)getComponentOfDate:(NSDate *)date ;
- (NSString *)getConversationTimeString:(NSDate *)date;
- (NSString*)formatSectionTime:(NSDate*)date;

+ (void)playMessageReceivedSound;
+ (void)playMessageSentSound;

@end
