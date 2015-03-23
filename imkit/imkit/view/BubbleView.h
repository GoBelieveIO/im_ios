#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"

extern CGFloat const kJSAvatarSize;

#define kMarginTop 4.0f
#define kMarginBottom 4.0f
#define kPaddingTop 8.0f
#define kPaddingBottom 8.0f
#define kBubblePaddingRight 45.0f

typedef enum {
    BubbleMessageReceiveStateNone = 0,
    BubbleMessageReceiveStateServer,
    BubbleMessageReceiveStateClient
}BubbleMessageReceiveStateType;

typedef enum {
    BubbleMessageTypeIncoming = 0,
    BubbleMessageTypeOutgoing
} BubbleMessageType;


@interface BubbleView : UIView


@property (assign, nonatomic) BubbleMessageType type;
@property (assign, nonatomic) BOOL selectedToShowCopyMenu;
@property (nonatomic) BubbleMessageReceiveStateType msgStateType;
@property (nonatomic) UIImageView *receiveStateImgSign;
@property (nonatomic) UIActivityIndicatorView *downloadIndicatorView;
@property (nonatomic) UIActivityIndicatorView *uploadIndicatorView;
@property (nonatomic) CGRect contentFrame;
@property (strong, nonatomic) UIButton *msgSendErrorBtn;

#pragma mark - Drawing
- (CGRect)bubbleFrame;
- (UIImage *)bubbleImage;
- (UIImage *)bubbleImageHighlighted;

-(void) showSendErrorBtn:(BOOL)show;

-(void) drawMsgStateSign:(CGRect) frame;

#pragma mark - Bubble view
+ (UIImage *)bubbleImageForType:(BubbleMessageType)aType;

+ (UIFont *)font;

+ (CGSize)textSizeForText:(NSString *)txt withFont:(UIFont*)font;
+ (CGSize)bubbleSizeForText:(NSString *)txt withFont:(UIFont*)font;

+ (CGFloat)cellHeightForText:(NSString *)txt;

+ (int)maxCharactersPerLine;
+ (int)numberOfLinesForMessage:(NSString *)txt;

@end