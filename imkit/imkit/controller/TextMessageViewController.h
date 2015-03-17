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

@interface TextMessageViewController : BaseMessageViewController < UIImagePickerControllerDelegate, UINavigationControllerDelegate,UIScrollViewDelegate,UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate, UIActionSheetDelegate>



@end