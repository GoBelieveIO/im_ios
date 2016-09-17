/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "IMService.h"
#import "BaseMessageViewController.h"


@protocol MessageViewControllerUserDelegate <NSObject>
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid;
//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb;
@end


@interface MessageViewController : BaseMessageViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,  UITextViewDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak) id<MessageViewControllerUserDelegate> userDelegate;
@property(nonatomic) BOOL isShowUserName;

@property(nonatomic)UIView *inputBar;

- (void)setDraft:(NSString*)text;
- (NSString*)getDraft;
- (void)disableSend;
- (void)enableSend;

- (void)downloadMessageContent:(IMessage*)message;
- (void)downloadMessageContent:(NSArray*)messages count:(int)count;

- (void)loadSenderInfo:(IMessage*)msg;
- (void)loadSenderInfo:(NSArray*)messages count:(int)count;

- (void)stopPlayer;

//protected
- (void)createMapSnapshot:(IMessage*)msg;
- (void)reverseGeocodeLocation:(IMessage*)msg;
- (void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
- (NSString*)localImageURL;
- (NSString*)localAudioURL;
@end
