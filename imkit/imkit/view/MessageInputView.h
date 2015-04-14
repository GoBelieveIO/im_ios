/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"
#import "FBShimmeringView.h"

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
@property (nonatomic) FBShimmeringView *shimmeringView;
@property (nonatomic) CGPoint lastPoint;


@property (nonatomic ,weak) id <MessageInputRecordDelegate>  delegate;

- (id)initWithFrame:(CGRect)frame andDelegate:(id < MessageInputRecordDelegate>) dleg;

- (void)slipLabelFrame:(double)x;
- (void)resetLabelFrame;

- (void) setRecordShowing;
- (void) setNomarlShowing;

@end
