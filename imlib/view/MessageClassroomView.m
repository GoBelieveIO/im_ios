//
//  MessageClassroomView.m
//  gobelieve
//
//  Created by houxh on 2020/3/3.
//

#import "MessageClassroomView.h"
#import "MessageClassroom.h"
@interface MessageClassroomView()
@property(nonatomic, copy) NSString *text;

@property(nonatomic) UILabel *label;
@property(nonatomic) UIImageView *imageView;
@end

@implementation MessageClassroomView

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
        self.imageView.image = [UIImage imageNamed:@"classroom"];
        [self addSubview:self.imageView];
    }
    return self;
}


- (void)setMsg:(IMessage *)msg {
    [super setMsg:msg];
    self.label.text = NSLocalizedString(@"message.view.classroom", nil);
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
