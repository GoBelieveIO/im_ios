/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */


#import <UIKit/UIKit.h>

@protocol MessageViewControllerUserDelegate;

@class IGroup;
@protocol MessageListViewControllerGroupDelegate <NSObject>
//从本地获取群组信息
- (IGroup*)getGroup:(int64_t)gid;
//从服务器获取用户信息
- (void)asyncGetGroup:(int64_t)gid cb:(void(^)(IGroup*))cb;
@end

@interface MessageListViewController : UIViewController
@property(nonatomic, assign) int64_t currentUID;

@property(nonatomic, weak) id<MessageViewControllerUserDelegate> userDelegate;
@property(nonatomic, weak) id<MessageListViewControllerGroupDelegate> groupDelegate;
@end
