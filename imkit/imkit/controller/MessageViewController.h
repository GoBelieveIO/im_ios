//
//  MessageViewController.h
//  Message
//
//  Created by daozhu on 14-6-16.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <imsdk/IMService.h>
#import "BaseMessageViewController.h"

typedef NSString* (^GetUserNameBlock)(int64_t uid);

@interface MessageViewController : BaseMessageViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,  UITextViewDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, copy) GetUserNameBlock getUserName;
@property(nonatomic) BOOL isShowUserName;

@property(nonatomic)UIView *inputBar;

- (void)setDraft:(NSString*)text;
- (NSString*)getDraft;
- (void)disableSend;
- (void)enableSend;

- (void)addObserver;
- (void)removeObserver;

@end
