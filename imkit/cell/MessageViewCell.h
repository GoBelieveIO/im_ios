/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "BubbleView.h"
#import "IMessage.h"

#define kPaddingTop 8.0f
#define kPaddingBottom 8.0f
#define kMarginTop 4.0f
#define kMarginBottom 4.0f

#define kMiddlePaddingTop 4.0f
#define kMiddlePaddingBottom 4.0f

#define kMessageLinkViewHeight (kLinkHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageImagViewHeight (kImageHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageFileViewHeight (kFileHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageVideoViewHeight (kVideoHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageLocationViewHeight (kLocationHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageAudioViewHeight (kAudioHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageVOIPViewHeight (kVOIPHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageNotificationViewHeight (kNotificationHeight + kMiddlePaddingTop + kMiddlePaddingBottom + kMarginTop + kMarginBottom)
#define kMessageClassroomViewHeight (kClassroomHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)
#define kMessageUnknowViewHeight (kUnknowHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom)


#define TRIANGLE_WIDTH 4
#define TRIANGLE_HEIGHT 8


@interface MessageViewCell : UITableViewCell
//text, image
+ (CGFloat)cellHeightMessage:(IMessage*)msg;

@property(nonatomic) IMessage *msg;
@property(nonatomic) UIView *containerView;
@property(nonatomic) BubbleView *bubbleView;
@property(nonatomic, assign) BOOL selectedToShowCopyMenu;

- (id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier;
@end
