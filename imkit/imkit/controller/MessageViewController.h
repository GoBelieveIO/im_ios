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
#import "AudioDownloader.h"


@protocol MessageViewControllerUserDelegate <NSObject>
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid;
//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb;
@end


@interface MessageViewController : BaseMessageViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                                                                UIGestureRecognizerDelegate,
                                                                AVAudioRecorderDelegate, AVAudioPlayerDelegate,
                                                                UITableViewDataSource, UITableViewDelegate,
                                                                OutboxObserver, AudioDownloaderObserver>

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

- (void)updateNotificationDesc:(IMessage*)message;
- (void)updateNotificationDesc:(NSArray*)messages count:(int)count;

- (void)stopPlayer;

//overwrite
- (void)onBack;
- (void)addObserver;
- (void)removeObserver;

//protected
- (void)createMapSnapshot:(IMessage*)msg;
- (void)reverseGeocodeLocation:(IMessage*)msg;
- (NSString*)localImageURL;
- (NSString*)localAudioURL;
- (void)call;

//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid;
//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb;

@end
