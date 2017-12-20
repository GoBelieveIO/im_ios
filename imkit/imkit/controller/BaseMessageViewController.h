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
#import "IMessageDB.h"
#import "Outbox.h"

//基类处理tableview相关的数据
@interface BaseMessageViewController : UIViewController

@property(nonatomic) id<IMessageDB> messageDB;

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) NSString *cid;

@property(nonatomic, assign) int messageID;//加载此消息id前后的消息
//protected
@property(nonatomic, assign) BOOL hasLateMore;
@property(nonatomic, assign) BOOL hasEarlierMore;
@property(nonatomic) NSMutableArray *messages;
@property(nonatomic) NSMutableDictionary *attachments;

@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) int lastReceivedTimestamp;

//protected overwrite by derived class
-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
-(BOOL)saveMessage:(IMessage*)msg;
-(BOOL)removeMessage:(IMessage*)msg;
-(BOOL)markMessageFailure:(IMessage*)msg;
-(BOOL)markMesageListened:(IMessage*)msg;
-(BOOL)eraseMessageFailure:(IMessage*)msg;

- (void)loadConversationData;
- (void)loadEarlierData;
- (void)loadLateData;


- (void)initTableViewData;

- (void)insertMessage:(IMessage*)msg;
- (void)insertMessages:(NSArray*)messages;
- (void)scrollToBottomAnimated:(BOOL)animated;

- (IMessage*)getMessageWithID:(int)msgLocalID;
- (IMessage*)getMessageWithUUID:(NSString*)uuid;

- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath;

+ (void)playMessageReceivedSound;
+ (void)playMessageSentSound;

@end
