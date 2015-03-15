//
//  JSMessageInputView.h
//
//  Created by Jesse Squires on 2/12/13.
//  Copyright (c) 2013 Hexed Bits. All rights reserved.
//
//  http://www.hexedbits.com
//
//
//  Largely based on work by Sam Soffes
//  https://github.com/soffes
//
//  SSMessagesViewController
//  https://github.com/soffes/ssmessagesviewcontroller

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"

@protocol MessageInputRecordDelegate <NSObject>

-(void) recordStart;
-(void) recordCancel:(CGFloat)xMove;
-(void) recordEnd;

@end


@interface MessageInputView : UIView
@property (nonatomic) UIImageView *bkView;

@property (nonatomic) HPGrowingTextView *textView;
@property (nonatomic) UIButton *sendButton;
@property (nonatomic) UILabel *recordButton;
@property (nonatomic) UIButton* mediaButton;

@property (nonatomic) UIView *recordingView;
@property (nonatomic) UILabel *timerLabel;
@property (nonatomic) UIImageView *recordAnimationView;
@property (nonatomic) UILabel *slipLabel;
@property (nonatomic) CGPoint lastPoint;


@property (nonatomic ,weak) id <MessageInputRecordDelegate>  delegate;

- (id)initWithFrame:(CGRect)frame andDelegate:(id < MessageInputRecordDelegate>) dleg;

- (void)slipLabelFrame:(double)x;
- (void)resetLabelFrame;

- (void) setRecordShowing;
- (void) setNomarlShowing;

@end