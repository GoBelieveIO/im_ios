/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/
#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"
#import "IMessage.h"

extern CGFloat const kJSAvatarSize;

#define kMarginTop 4.0f
#define kMarginBottom 4.0f
#define kPaddingTop 2.0f
#define kPaddingBottom 11.0f
#define kBubblePaddingHead 8.0f
#define kBubblePaddingTail 7.0f

//#define kBubblePaddingRight 31.0f

typedef enum {
    BubbleMessageTypeIncoming = 0,
    BubbleMessageTypeOutgoing
} BubbleMessageType;


@interface BubbleView : UIView

@property (nonatomic ,strong) IMessage *msg;

@property (assign, nonatomic) BubbleMessageType type;
@property (assign, nonatomic) BOOL selectedToShowCopyMenu;
@property (nonatomic) UIImageView *receiveStateImgSign;


@property (nonatomic) CGRect contentFrame;
@property (strong, nonatomic) UIButton *msgSendErrorBtn;



#pragma mark - Drawing
- (CGRect)bubbleFrame;
- (UIImage *)bubbleImage;
- (UIImage *)bubbleImageHighlighted;

-(void)showSendErrorBtn:(BOOL)show;

#pragma mark - Bubble view
+ (UIImage *)bubbleImageForType:(BubbleMessageType)aType;

+ (UIFont *)font;

+ (CGSize)textSizeForText:(NSString *)txt withFont:(UIFont*)font;


+ (int)maxCharactersPerLine;
+ (int)numberOfLinesForMessage:(NSString *)txt;

@end
