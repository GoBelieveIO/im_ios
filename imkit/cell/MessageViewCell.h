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

#define TRIANGLE_WIDTH 4
#define TRIANGLE_HEIGHT 8

@interface MessageViewCell : UITableViewCell
@property(nonatomic) IMessage *msg;
@property(nonatomic) UIView *containerView;
@property(nonatomic) BubbleView *bubbleView;
@property(nonatomic, weak) UIButton *replyButton;
@property(nonatomic, weak) UIImageView *topicView;
@property(nonatomic, assign) BOOL selectedToShowCopyMenu;
@property(nonatomic, assign) BOOL showReply; //显示topicView&replyButton

- (id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier;
@end
