#import "BubbleView.h"
#import "NSString+JSMessagesView.h"
#import "UIImage+JSMessagesView.h"

CGFloat const kJSAvatarSize = 50.0f;

@interface BubbleView()

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
    }
    return self;
}

#pragma mark - Setters
- (void)setType:(BubbleMessageType)newType
{
    _type = newType;
    [self setNeedsDisplay];
}

- (void) setMsgStateType:(BubbleMessageReceiveStateType)type{
    _msgStateType = type;
    [self setNeedsDisplay];
}

- (void)setSelectedToShowCopyMenu:(BOOL)isSelected{
    _selectedToShowCopyMenu = isSelected;
    [self setNeedsDisplay];
}

#pragma mark - Drawing
- (CGRect)bubbleFrame{
    NSLog(@"act对象消息");
    return CGRectMake(0, 0, 0, 0);
}

- (UIImage *)bubbleImage{
    return [BubbleView bubbleImageForType:self.type];
}

- (UIImage *)bubbleImageHighlighted{
    return (self.type == BubbleMessageTypeIncoming) ? [UIImage bubbleDefaultIncomingSelected] : [UIImage bubbleDefaultOutgoingSelected];
}

-(void) showSendErrorBtn:(BOOL)show{
    if (self.type == BubbleMessageTypeOutgoing) {
        [self.msgSendErrorBtn setHidden:!show];
    }

}

-(void) drawMsgStateSign:(CGRect) frame{
    if (self.type == BubbleMessageTypeOutgoing) {
        UIImage *msgSignImg = nil;
        switch (_msgStateType) {
            case BubbleMessageReceiveStateNone:
            {
                msgSignImg = [UIImage imageNamed:@"CheckDoubleLight"];
            }
                break;
            case BubbleMessageReceiveStateClient:
            {
                msgSignImg = [UIImage imageNamed:@"CheckDoubleGreen"];
            }
                break;
            case BubbleMessageReceiveStateServer:
            {
                msgSignImg = [UIImage imageNamed:@"CheckSingleGreen"];
            }
                break;
            default:
                break;
        }
        
        CGRect bubbleFrame = [self bubbleFrame];
        
        CGFloat imgX = bubbleFrame.origin.x + bubbleFrame.size.width - msgSignImg.size.width;
        imgX = self.type == BubbleMessageTypeOutgoing ?(imgX - 15):(imgX - 5);
        
        CGRect msgStateSignRect = CGRectMake(imgX, frame.size.height -  kPaddingBottom - msgSignImg.size.height, msgSignImg.size.width , msgSignImg.size.height);
        
        [msgSignImg drawInRect:msgStateSignRect];
        
        
        imgX = bubbleFrame.origin.x;
        CGRect rect = self.msgSendErrorBtn.frame;
        rect.origin.x = imgX - self.msgSendErrorBtn.frame.size.width + 2;
        rect.origin.y = bubbleFrame.origin.y + bubbleFrame.size.height  - self.msgSendErrorBtn.frame.size.height - kMarginBottom;
        [self.msgSendErrorBtn setFrame:rect];
        [self bringSubviewToFront:self.msgSendErrorBtn];
    }
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
    return [UIImage bubbleDefaultIncoming];
}

+ (UIImage *)bubbleImageTypeOutgoing{
    return [UIImage bubbleDefaultOutgoing];
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

+ (CGSize)bubbleSizeForText:(NSString *)txt withFont:(UIFont*)font
{
    CGSize textSize = [BubbleView textSizeForText:txt withFont:font];
    return CGSizeMake(textSize.width + kBubblePaddingRight,
                      textSize.height + kPaddingTop + kPaddingBottom);
}

+ (CGFloat)cellHeightForText:(NSString *)txt
{
    return [BubbleView bubbleSizeForText:txt withFont:[BubbleView font]].height + kMarginTop + kMarginBottom;
}

+ (int)maxCharactersPerLine
{
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 34 : 109;
}

+ (int)numberOfLinesForMessage:(NSString *)txt
{
    return (txt.length / [BubbleView maxCharactersPerLine]) + 1;
}

@end
