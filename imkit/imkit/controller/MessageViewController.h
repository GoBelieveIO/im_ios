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

@interface MessageViewController : UIViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate,
    MessageObserver,  UIActionSheetDelegate>

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, copy) NSString *peerName;
@property(nonatomic, assign) int64_t peerLastUpTimestamp;

@end
