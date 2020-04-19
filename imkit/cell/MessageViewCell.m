/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/



#import "MessageViewCell.h"
#import "MessageTextView.h"
#import "MessageImageView.h"
#import "MessageAudioView.h"
#import "MessageNotificationView.h"
#import "MessageLocationView.h"
#import "MessageLinkView.h"
#import "MessageVOIPView.h"
#import "MessageFileView.h"
#import "MessageVideoView.h"
#import "MessageClassroomView.h"
#import "MessageUnknownView.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface MessageViewCell()


@end

@implementation MessageViewCell

+ (CGFloat)cellHeightMessage:(IMessage*)msg {
    if (msg.imageContent) {
        int w = msg.imageContent.width;
        int h = msg.imageContent.height;
        
        if (w > 0 && h > 0) {
            CGFloat h1 = kImageWidth*(h*1.0/w) + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom;
            return h1;
        } else {
            return kImageHeight + kPaddingTop + kPaddingBottom + kMarginTop + kMarginBottom;
        }
    } else if (msg.textContent) {
        UIFont *font = [MessageTextView font];
        CGSize textSize = [MessageTextView textSizeForText:msg.textContent.text withFont:font];
        CGFloat h = textSize.height + 16;
        return MAX(h, 40) + kMarginTop + kMarginBottom;
    } else {
        return 0;
    }
}


-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier {
    self =  [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGRect frame = CGRectZero;
        
        switch (type) {
            case MESSAGE_AUDIO:
            {
                MessageAudioView *audioView = [[MessageAudioView alloc] initWithFrame:frame];
                self.bubbleView = audioView;
            }
                break;
            case MESSAGE_TEXT:
            {
                MessageTextView *textView = [[MessageTextView alloc] initWithFrame:frame];
                self.bubbleView = textView;
            }
                break;
            case MESSAGE_IMAGE:
            {
                MessageImageView *imageView = [[MessageImageView alloc] initWithFrame:frame];
                self.bubbleView = imageView;
            }
                break;
    
            case MESSAGE_LOCATION:
            {
                MessageLocationView *locationView = [[MessageLocationView alloc] initWithFrame:frame];
                self.bubbleView = locationView;
            }
                break;
            case MESSAGE_LINK:
            {
                MessageLinkView *linkView = [[MessageLinkView alloc] initWithFrame:frame];
                self.bubbleView = linkView;
            }
                break;
            case MESSAGE_HEADLINE:
            case MESSAGE_GROUP_NOTIFICATION:
            case MESSAGE_TIME_BASE:
            case MESSAGE_GROUP_VOIP:
            case MESSAGE_REVOKE:
            case MESSAGE_ACK:
            {
                MessageNotificationView *notificationView = [[MessageNotificationView alloc] initWithFrame:frame];
                self.bubbleView = notificationView;
            }
                break;
            case MESSAGE_VOIP:
            {
                MessageVOIPView *voipView = [[MessageVOIPView alloc] initWithFrame:frame];
                self.bubbleView = voipView;
            }
                break;
            case MESSAGE_FILE:
            {
                MessageFileView *fileView = [[MessageFileView alloc] initWithFrame:frame];
                self.bubbleView = fileView;
            }
                break;
            case MESSAGE_VIDEO:
            {
                MessageVideoView *videoView = [[MessageVideoView alloc] initWithFrame:frame];
                self.bubbleView = videoView;
            }
                break;
            case MESSAGE_CLASSROOM:
            {
                MessageClassroomView *classroomView = [[MessageClassroomView alloc] initWithFrame:frame];
                self.bubbleView = classroomView;
            }
                break;
            default:
            {
                MessageUnknownView *unknownView = [[MessageUnknownView alloc] initWithFrame:frame];
                self.bubbleView = unknownView;
            }
                break;
        }
        [self.contentView addSubview:self.bubbleView];
    }
    return self;
}


- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    [self.msg removeObserver:self forKeyPath:@"senderInfo"];
    [self.msg removeObserver:self forKeyPath:@"flags"];
}


-(void)setMsg:(IMessage *)msg {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    [self.msg removeObserver:self forKeyPath:@"flags"];
    [self.msg removeObserver:self forKeyPath:@"senderInfo"];
    _msg = msg;
    [self.msg addObserver:self forKeyPath:@"senderInfo" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"flags" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"uploading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
}

@end
