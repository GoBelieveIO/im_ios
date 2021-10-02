/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "BaseMessageViewController.h"


@class MessageViewCell;
@class EaseChatToolbar;
@interface MessageViewController : BaseMessageViewController
//UIMenuController显示时，选中的消息
@property(nonatomic) IMessage *selectedMessage;
@property(nonatomic, weak) MessageViewCell *selectedCell;

@property(nonatomic) BOOL isShowUserName;//显示用户昵称 default:NO
@property(nonatomic) BOOL isShowReaded;//显示未读/已读 default:YES
@property(nonatomic) BOOL isShowReply;//显示回复信息 default:YES
@property(nonatomic) BOOL callEnabled;//是否显示视频呼叫按钮; default:YES
@property(nonatomic)UIView *inputBar;
@property(strong, nonatomic) EaseChatToolbar *chatToolbar;

@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIView *tableHeaderView;

- (void)setDraft:(NSString*)text;
- (NSString*)getDraft;
- (void)disableSend;
- (void)enableSend;

//overwrite
- (void)onBack;
- (void)addObserver;
- (void)removeObserver;

//protected
- (void)forward:(id)sender;
- (void)call;
- (void)openUnread:(IMessage*)msg;
- (void)openReply:(IMessage*)msg;
- (NSMutableArray*)getMessageMenuItems:(IMessage*)msg;
@end
