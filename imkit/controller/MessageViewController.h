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



@class EaseChatToolbar;
@interface MessageViewController : BaseMessageViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                                                                UIGestureRecognizerDelegate,
                                                                AVAudioRecorderDelegate, AVAudioPlayerDelegate,
                                                                UITableViewDataSource, UITableViewDelegate,
                                                                OutboxObserver, AudioDownloaderObserver>
@property(nonatomic) BOOL isShowUserName;
@property(nonatomic) BOOL callEnabled;//是否显示视频呼叫按钮; default:YES
@property(nonatomic)UIView *inputBar;
@property(strong, nonatomic) EaseChatToolbar *chatToolbar;
@property(nonatomic) UIRefreshControl *refreshControl;
@property(nonatomic) UITableView *tableView;

- (void)setDraft:(NSString*)text;
- (NSString*)getDraft;
- (void)disableSend;
- (void)enableSend;

- (void)stopPlayer;

//overwrite
- (void)onBack;
- (void)addObserver;
- (void)removeObserver;

//protected

- (void)call;

- (void)openClassroomViewController:(IMessage*)msg;

@end
