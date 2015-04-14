/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <imsdk/IMService.h>
#import "BaseMessageViewController.h"

typedef NSString* (^GetUserNameBlock)(int64_t uid);

//提供最基本的文本聊天，便于开发者定制开发自己的UI
@interface TextMessageViewController : BaseMessageViewController < UITableViewDataSource, UITableViewDelegate,  UIGestureRecognizerDelegate>


@property(nonatomic, copy) GetUserNameBlock getUserName;
@property(nonatomic) BOOL isShowUserName;

- (void)setDraft:(NSString*)text;
- (NSString*)getDraft;

- (void)disableSend;

- (void)enableSend;

- (void)addObserver;
- (void)removeObserver;

@end
