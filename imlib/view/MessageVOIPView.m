//
//  MessageVOIPView.m
//  gobelieve
//
//  Created by houxh on 2017/11/8.
//

#import "MessageVOIPView.h"
#import "IMessage.h"

@interface MessageVOIPView()
@property(nonatomic, copy) NSString *text;

@property(nonatomic) UILabel *label;
@property(nonatomic) UIImageView *imageView;
@end

@implementation MessageVOIPView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
      
        self.label = [[UILabel alloc] init];
        self.label.font = [UIFont systemFontOfSize:14.0f];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.label];
        
        self.imageView = [[UIImageView alloc] init];
        self.imageView.image = [UIImage imageNamed:@"phone"];
        [self addSubview:self.imageView];
    }
    return self;
}


- (void)setMsg:(IMessage *)msg {
    [super setMsg:msg];
    
    MessageVOIPContent *voip = (MessageVOIPContent*)msg.voipContent;
    int duration = voip.duration;
    
    int m = duration/60;
    int s = duration%60;
    NSString *t = [NSString stringWithFormat:@"%02d:%02d", m, s];
    if (msg.isOutgoing) {
        switch (voip.flag) {
            case VOIP_FLAG_REFUSED:
                self.text = @"对方已拒绝";
                break;
            case VOIP_FLAG_UNRECEIVED:
                self.text = @"对方未接听";
                break;
            case VOIP_FLAG_CANCELED:
                self.text = @"已取消";
                break;
            case VOIP_FLAG_ACCEPTED:
                self.text = t;
                break;
            default:
                break;
        }
    } else {
        switch (voip.flag) {
            case VOIP_FLAG_REFUSED:
                self.text = @"已拒绝";
                break;
            case VOIP_FLAG_UNRECEIVED:
                self.text = @"未接听";
                break;
            case VOIP_FLAG_CANCELED:
                self.text = @"对方已取消";
                break;
            case VOIP_FLAG_ACCEPTED:
                self.text = t;
                break;
            default:
                break;
        }
    }
    
    self.label.text = self.text;

    [self setNeedsDisplay];
}



- (CGSize)bubbleSize {
    CGRect bounds = CGRectMake(0, 0, 1000, 44);
    
    CGRect r = [self.label textRectForBounds:bounds limitedToNumberOfLines:1];
    r.size.width += 32;
    r.size.width = ceil(r.size.width);
    return r.size;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect bubbleFrame = self.bounds;
    
    if (self.msg.isOutgoing) {
        CGRect f = bubbleFrame;
        f.size.width -= 32;
        self.label.frame = f;
        
        f.origin.x = CGRectGetMaxX(bubbleFrame) - 24;
        f.size.width = 24;
        self.imageView.frame = f;
    } else {
        CGRect f = bubbleFrame;
        f.size.width = 24;
        self.imageView.frame = f;
        
        f.origin.x = bubbleFrame.origin.x + 32;
        f.size.width = bubbleFrame.size.width - 32;
        self.label.frame = f;
        
        [self.label sizeToFit];
        f = self.label.frame;
    }
}

@end
