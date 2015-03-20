//
//  TextMessageViewController.h
//  imkit
//
//  Created by houxh on 15/3/16.
//  Copyright (c) 2015年 beetle. All rights reserved.
//


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