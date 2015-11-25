/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/
#import "BubbleView.h"
#import "NSString+JSMessagesView.h"

CGFloat const kJSAvatarSize = 50.0f;

@interface BubbleView()

@property (nonatomic) UIActivityIndicatorView *sendingIndicatorView;

+ (UIImage *)bubbleImageTypeIncoming;
+ (UIImage *)bubbleImageTypeOutgoing;

@end

@implementation BubbleView

#pragma mark - Initialization
- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.msgSendErrorBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [self.msgSendErrorBtn setImage:[UIImage imageNamed:@"MessageSendError"] forState:UIControlStateNormal];
        [self.msgSendErrorBtn setImage:[UIImage imageNamed:@"MessageSendError"]  forState: UIControlStateHighlighted];
        self.msgSendErrorBtn.hidden = YES;
        [self addSubview:self.msgSendErrorBtn];
        
        self.sendingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.sendingIndicatorView];
    }
    return self;
}

- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"flags"];
}

#pragma mark - Setters
-(void)setMsg:(IMessage *)msg {
    [self.msg removeObserver:self forKeyPath:@"flags"];
    _msg = msg;
    [self.msg addObserver:self forKeyPath:@"flags" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    if (self.type == BubbleMessageTypeOutgoing) {
        if (self.msg.isFailure) {
            self.msgSendErrorBtn.hidden = NO;
            [self.sendingIndicatorView stopAnimating];
        } else if (self.msg.isACK) {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView stopAnimating];
        } else if (self.msg.uploading) {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView stopAnimating];
        } else {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView startAnimating];
        }
    } else {
        self.msgSendErrorBtn.hidden = YES;
        [self.sendingIndicatorView stopAnimating];
    }
    [self setNeedsLayout];
}

- (void)setType:(BubbleMessageType)newType
{
    _type = newType;
    [self setNeedsDisplay];
}

- (void)setSelectedToShowCopyMenu:(BOOL)isSelected{
    _selectedToShowCopyMenu = isSelected;
    [self setNeedsDisplay];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"flags"] || [keyPath isEqualToString:@"uploading"]) {
        if (self.type == BubbleMessageTypeOutgoing) {
            if (self.msg.isFailure) {
                self.msgSendErrorBtn.hidden = NO;
                [self.sendingIndicatorView stopAnimating];
            } else if (self.msg.isACK) {
                self.msgSendErrorBtn.hidden = YES;
                [self.sendingIndicatorView stopAnimating];
            } else if (self.msg.uploading) {
                self.msgSendErrorBtn.hidden = YES;
                [self.sendingIndicatorView stopAnimating];
            } else {
                self.msgSendErrorBtn.hidden = YES;
                [self.sendingIndicatorView startAnimating];
            }
        } else {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView stopAnimating];
        }
    }
}


+ (UIImage *)bubbleDefaultIncoming{
    UIImage *image = [UIImage imageNamed:@"ReceiverTextNodeBkg"];
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(28.0f, 14.0f, 17.0f, 12.0f)
                          resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)bubbleDefaultIncomingSelected{
    UIImage *image = [UIImage imageNamed:@"ReceiverTextNodeBkgHL"];
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(28.0f, 14.0f, 17.0f, 12.0f)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)bubbleDefaultOutgoing{
    UIImage *image = [UIImage imageNamed:@"SenderTextNodeBkg"];
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(28.0f, 11.0f, 15.0f, 12.0f)
                                 resizingMode:UIImageResizingModeStretch];
}

+ (UIImage *)bubbleDefaultOutgoingSelected{
    UIImage *image = [UIImage imageNamed:@"SenderTextNodeBkgHL"];
    return [image resizableImageWithCapInsets:UIEdgeInsetsMake(28.0f, 11.0f, 15.0f, 12.0f)
                         resizingMode:UIImageResizingModeStretch];
}



#pragma mark - Drawing
- (CGRect)bubbleFrame{
    return CGRectMake(0, 0, 0, 0);
}

- (UIImage *)bubbleImage{
    return [BubbleView bubbleImageForType:self.type];
}

- (UIImage *)bubbleImageHighlighted{
    return (self.type == BubbleMessageTypeIncoming) ? [[self class] bubbleDefaultIncomingSelected] : [[self class] bubbleDefaultOutgoingSelected];
}

-(void) showSendErrorBtn:(BOOL)show{
    if (self.type == BubbleMessageTypeOutgoing) {
        [self.msgSendErrorBtn setHidden:!show];
    }

}

- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
    UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    
    CGRect bubbleFrame = [self bubbleFrame];
    [image drawInRect:bubbleFrame];
}

-(void)layoutSubviews {
    CGRect bubbleFrame = [self bubbleFrame];
    CGFloat imgX = bubbleFrame.origin.x;
    CGRect rect = self.msgSendErrorBtn.frame;
    rect.origin.x = imgX - self.msgSendErrorBtn.frame.size.width + 2;
    rect.origin.y = bubbleFrame.origin.y + bubbleFrame.size.height  - self.msgSendErrorBtn.frame.size.height - kPaddingBottom;
    [self.msgSendErrorBtn setFrame:rect];
    [self.sendingIndicatorView setFrame:rect];
}

#pragma mark - Bubble view
+ (UIImage *)bubbleImageForType:(BubbleMessageType)aType
{
    switch (aType) {
        case BubbleMessageTypeIncoming:
            return [self bubbleImageTypeIncoming];
            
        case BubbleMessageTypeOutgoing:
            return [self bubbleImageTypeOutgoing];
            
        default:
            return nil;
    }
}

+ (UIImage *)bubbleImageTypeIncoming{
    return [self bubbleDefaultIncoming];
}

+ (UIImage *)bubbleImageTypeOutgoing{
    return [self bubbleDefaultOutgoing];
}

+ (UIFont *)font{
    return [UIFont systemFontOfSize:14.0f];
}

+ (CGSize)textSizeForText:(NSString *)txt withFont:(UIFont*)font{
    CGFloat width = [UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGFloat height = MAX([BubbleView numberOfLinesForMessage:txt],
                         [txt numberOfLines]) *  30.0f;
   
    UILabel *gettingSizeLabel = [[UILabel alloc] init];
    gettingSizeLabel.font = font;
    gettingSizeLabel.text = txt;
    gettingSizeLabel.numberOfLines = 0;
    gettingSizeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize maximumLabelSize = CGSizeMake(width, height);
    
    return  [gettingSizeLabel sizeThatFits:maximumLabelSize];
}


+ (int)maxCharactersPerLine
{
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 34 : 109;
}

+ (int)numberOfLinesForMessage:(NSString *)txt
{
    return (int)(txt.length / [BubbleView maxCharactersPerLine]) + 1;
}

@end
