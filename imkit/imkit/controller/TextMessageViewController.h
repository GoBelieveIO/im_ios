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

@interface TextMessageViewController : UIViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, MessageObserver,  UIActionSheetDelegate>

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) int64_t peerUID;
@property(nonatomic, copy) NSString *peerName;

@end