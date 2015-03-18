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

@interface MessageViewController : BaseMessageViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,  UITextViewDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIActionSheetDelegate, UITableViewDataSource, UITableViewDelegate>

- (void)setDraft:(NSString*)text;
- (NSString*)getDraft;
- (void)disableSend;
- (void)enableSend;
@end
