/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/



#import "MessageViewCell.h"
#import "UIImage+JSMessagesView.h"
#import "MessageTextView.h"
#import "MessageImageView.h"
#import "MessageAudioView.h"
#import "MessageNotificationView.h"
#import "MessageLocationView.h"
#import "MessageLinkView.h"

@interface MessageViewCell()
@property(nonatomic) IMessage *msg;
@property(nonatomic) BOOL showName;
@end

@implementation MessageViewCell

#pragma mark - Setup
- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    
    self.imageView.image = nil;
    self.imageView.hidden = YES;
    self.textLabel.text = nil;
    self.textLabel.hidden = YES;
    self.detailTextLabel.text = nil;
    self.detailTextLabel.hidden = YES;
}


-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier {
    self =  [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
        CGRect frame = CGRectMake(12,
                                  0,
                                  self.contentView.frame.size.width - 24,
                                  NAME_LABEL_HEIGHT);
        
        self.nameLabel = [[UILabel alloc] initWithFrame:frame];
        self.nameLabel.font =  [UIFont systemFontOfSize:14.0f];
        self.nameLabel.textColor = [UIColor grayColor];

        [self.contentView addSubview:self.nameLabel];
        
        frame = CGRectMake(0,
                           NAME_LABEL_HEIGHT,
                           self.contentView.frame.size.width,
                           self.contentView.frame.size.height - NAME_LABEL_HEIGHT);
        
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
            case MESSAGE_GROUP_NOTIFICATION:
            {
                MessageNotificationView *notificationView = [[MessageNotificationView alloc] initWithFrame:frame];
                self.bubbleView = notificationView;
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
            default:
                self.bubbleView = nil;
                break;
        }
        
        if (self.bubbleView != nil) {
            [self.contentView addSubview:self.bubbleView];
            [self.contentView sendSubviewToBack:self.bubbleView];
            [self setBackgroundColor:[UIColor clearColor]];
        }
    }
    return self;
}


- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"senderInfo"];
}

#pragma mark - Message Cell
- (void) setMessage:(IMessage *)message msgType:(BubbleMessageType)msgType showName:(BOOL)showName {
    
    [self.msg removeObserver:self forKeyPath:@"senderInfo"];
    
    self.msg = message;
    
    [self.msg addObserver:self forKeyPath:@"senderInfo" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    

    NSString *name = self.msg.senderInfo.name;
    if (name.length == 0) {
        name = self.msg.senderInfo.identifier;
    }
    
    self.showName = showName;
    if (self.showName) {
        CGRect frame = CGRectMake(0,
                                  NAME_LABEL_HEIGHT,
                                  self.contentView.frame.size.width,
                                  self.contentView.frame.size.height - NAME_LABEL_HEIGHT);
        self.bubbleView.frame = frame;
        
        self.nameLabel.hidden = NO;
        self.nameLabel.text = name;
    } else {
        CGRect frame = CGRectMake(0,
                                  0,
                                  self.contentView.frame.size.width,
                                  self.contentView.frame.size.height);
        self.bubbleView.frame = frame;
        
        self.nameLabel.hidden = YES;
    }
    
    if (msgType == BubbleMessageTypeOutgoing) {
        self.nameLabel.textAlignment = NSTextAlignmentRight;
    } else {
        self.nameLabel.textAlignment = NSTextAlignmentLeft;
    }

    switch (message.type) {
        case MESSAGE_TEXT:
        {
            MessageTextView *textView = (MessageTextView*)self.bubbleView;
            textView.type = msgType;
            textView.msg = message;
        }
            break;
        case MESSAGE_IMAGE:
        {
            MessageImageView *msgImageView = (MessageImageView*)self.bubbleView;
            msgImageView.type = msgType;
            msgImageView.msg = message;
        }
            break;
        case MESSAGE_AUDIO:
        {
            MessageAudioView *audioView = (MessageAudioView*)self.bubbleView;
            audioView.type = msgType;
            audioView.msg = message;
        }
            break;
        case MESSAGE_GROUP_NOTIFICATION:
        {
            MessageNotificationView *notificationView = (MessageNotificationView*)self.bubbleView;
            notificationView.type = msgType;
            notificationView.msg = message;
        }
            break;
        case MESSAGE_LOCATION:
        {
            MessageLocationView *locationView = (MessageLocationView*)self.bubbleView;
            locationView.type = msgType;
            locationView.msg = message;
        }
            break;
        case MESSAGE_LINK:
        {
            MessageLinkView *linkView = (MessageLinkView*)self.bubbleView;
            linkView.type = msgType;
            linkView.msg = message;
        }
            break;
        default:
            break;
    }
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"senderInfo"]) {
        if (self.showName) {
            if (self.msg.senderInfo.name.length > 0) {
                self.nameLabel.text = self.msg.senderInfo.name;
            } else {
                self.nameLabel.text = self.msg.senderInfo.identifier;
            }
        }
    }
}
@end
