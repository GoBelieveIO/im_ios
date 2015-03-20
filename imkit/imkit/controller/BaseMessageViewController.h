//
//  BaseMessageViewController.h
//  imkit
//
//  Created by houxh on 15/3/17.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <imsdk/IMService.h>
#import "IMessage.h"

//基类处理tableview相关的数据
@interface BaseMessageViewController : UIViewController<MessageObserver>

//派生类必须重写
@property(nonatomic, readonly) int64_t sender;

//receiver可能代表uid或者群组id
@property(nonatomic, readonly) int64_t receiver;

- (BOOL)saveMessage:(IMessage*)msg;
- (BOOL)removeMessage:(IMessage*)msg;
- (BOOL)markMessageFailure:(IMessage*)msg;
- (BOOL)markMesageListened:(IMessage*)msg;
- (BOOL)eraseMessageFailure:(IMessage*)msg;

- (void)sendMessage:(IMessage*)msg;

//protected
@property(nonatomic) NSMutableArray *messageArray;
@property(nonatomic) NSMutableArray *timestamps;
@property(nonatomic) NSMutableArray *messages;
@property(nonatomic) NSMutableDictionary *names;

@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) UITableView *tableView;


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
- (BOOL)isYestoday:(NSDate*)date1 today:(NSDate*)date2 ;
- (BOOL)isBeforeYestoday:(NSDate*)date1 today:(NSDate*)date2;
- (BOOL)isInWeek:(NSDate*)date1 today:(NSDate*)date2;
- (BOOL)isInMonth:(NSDate*)date1 today:(NSDate*)date2;
- (NSDateComponents*)getComponentOfDate:(NSDate *)date ;
- (NSString *)getConversationTimeString:(NSDate *)date;

+ (void)playMessageReceivedSound;
+ (void)playMessageSentSound;

@end
