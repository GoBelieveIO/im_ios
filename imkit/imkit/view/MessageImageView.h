//
//  MessageImageView.h
//  Message
//
//  Created by houxh on 14-9-9.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BubbleView.h"

#define  kMessageImagViewHeight 120

@interface MessageImageView : BubbleView

@property (weak, nonatomic) UIViewController *dgtController;
@property (nonatomic) UIImageView *imageView;

@property (nonatomic) id data;

-(void) setUploading:(BOOL)uploading;

@end
