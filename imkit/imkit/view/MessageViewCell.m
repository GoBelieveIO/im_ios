


#import "MessageViewCell.h"
#import "UIImage+JSMessagesView.h"
#import "MessageTextView.h"
#import "MessageImageView.h"
#import "MessageAudioView.h"
#import "MessageNotificationView.h"



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

#pragma mark - Message Cell

- (void) setMessage:(IMessage *)message msgType:(BubbleMessageType)msgType {
    [self setMessage:message userName:nil msgType:msgType];
}

- (void) setMessage:(IMessage *)message userName:(NSString*)name msgType:(BubbleMessageType)msgType {
    if (name.length > 0) {
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
    
    BubbleMessageReceiveStateType state;
    if(message.isACK){
        if (message.isPeerACK) {
            state =  BubbleMessageReceiveStateClient;
        }else{
            state =  BubbleMessageReceiveStateServer;
        }
    }else{
        state =  BubbleMessageReceiveStateNone;
    }
    
    switch (message.content.type) {
        case MESSAGE_TEXT:
        {
            MessageTextView *textView = (MessageTextView*)self.bubbleView;
            textView.text = message.content.text;
            textView.type = msgType;
            textView.msgStateType = state;
        }
            break;
        case MESSAGE_IMAGE:
        {
            MessageImageView *msgImageView = (MessageImageView*)self.bubbleView;
            msgImageView.data = message.content.imageURL;
            msgImageView.type = msgType;
            msgImageView.msgStateType = state;
        }
            break;
        case MESSAGE_AUDIO:
        {
            MessageAudioView *audioView = (MessageAudioView*)self.bubbleView;
            [audioView initializeWithMsg:message withType:msgType withMsgStateType:state];
        }
            break;
        case MESSAGE_GROUP_NOTIFICATION:
        {
            MessageNotificationView *notificationView = (MessageNotificationView*)self.bubbleView;
            notificationView.label.text = message.content.notificationDesc;
        }
            break;
        default:
            break;
    }
    if (message.flags&MESSAGE_FLAG_FAILURE) {
        [self.bubbleView showSendErrorBtn:YES];
    }else{
        [self.bubbleView showSendErrorBtn:NO];
    }

}
@end