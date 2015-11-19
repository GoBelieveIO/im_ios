/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import <imsdk/IMService.h>
#import "IMessage.h"

//基类处理tableview相关的数据
@interface BaseMessageViewController : UIViewController

//派生类必须重写
@property(nonatomic, readonly) int64_t sender;

//receiver可能代表uid或者群组id
@property(nonatomic, readonly) int64_t receiver;

@property(nonatomic) IUser *senderInfo;

- (BOOL)saveMessage:(IMessage*)msg;
- (BOOL)removeMessage:(IMessage*)msg;
- (BOOL)markMessageFailure:(IMessage*)msg;
- (BOOL)markMesageListened:(IMessage*)msg;
- (BOOL)eraseMessageFailure:(IMessage*)msg;

- (void)sendMessage:(IMessage*)msg;
- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image;

//protected
@property(nonatomic) NSMutableArray *messageArray;
@property(nonatomic) NSMutableArray *timestamps;
@property(nonatomic) NSMutableArray *messages;
@property(nonatomic) NSMutableDictionary *attachments;

@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) UITableView *tableView;

@property(nonatomic) int lastReceivedTimestamp;

//是否只展示文本消息
@property(nonatomic) BOOL textMode;


//protected
//消息是否属于当前会话
- (BOOL)isInConversation:(IMessage*)msg;

- (void)loadConversationData;
- (void)loadEarlierData;


- (void)initTableViewData;

- (void)reloadMessage:(int)msgLocalID;
- (void)insertMessage:(IMessage*)msg;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (IMessage*) getMessageWithID:(int)msgLocalID;
- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSDate *)timestampForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath*)getIndexPathById:(int)msgLocalID;

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
