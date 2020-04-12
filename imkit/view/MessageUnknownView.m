//
//  MessageUnknownView.m
//  gobelieve
//
//  Created by houxh on 2017/11/9.
//

#import "MessageUnknownView.h"

@interface MessageUnknownView()
@property(nonatomic, copy) NSString *text;
@property(nonatomic, strong) UILabel *label;
@end
@implementation MessageUnknownView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[UILabel alloc] init];
        self.label.font = [UIFont systemFontOfSize:14.0f];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.label];
    }
    return self;
}


- (void)setMsg:(IMessage *)msg {
    [super setMsg:msg];
    if (msg.type == MESSAGE_SECRET) {
        self.text = @"消息未能解密";
    } else {
        self.text = @"未知的消息类型";
    }
    self.label.text = self.text;
}



- (CGSize)bubbleSize {
    CGFloat width = [UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGRect bounds = CGRectMake(0, 0, width, 44);
    
    CGRect r = [self.label textRectForBounds:bounds limitedToNumberOfLines:1];
    return r.size;
}



+ (UIFont *)font{
    return [UIFont systemFontOfSize:14.0f];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect bubbleFrame = self.bounds;
    self.label.frame = bubbleFrame;
}

@end
