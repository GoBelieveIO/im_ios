

#import <UIKit/UIKit.h>

@interface UIImage (JSMessagesView)

#pragma mark - Avatar styles
- (UIImage *)circleImageWithSize:(CGFloat)size;
- (UIImage *)squareImageWithSize:(CGFloat)size;

- (UIImage *)imageAsCircle:(BOOL)clipToCircle
               withDiamter:(CGFloat)diameter
               borderColor:(UIColor *)borderColor
               borderWidth:(CGFloat)borderWidth
              shadowOffSet:(CGSize)shadowOffset;

#pragma mark - Input bar
+ (UIImage *)inputBar;
+ (UIImage *)inputField;

#pragma mark - Bubble cap insets
- (UIImage *)makeStretchableDefaultIncoming;
- (UIImage *)makeStretchableDefaultOutgoing;


#pragma mark - Incoming message bubbles
+ (UIImage *)bubbleDefaultIncoming;
+ (UIImage *)bubbleDefaultIncomingSelected;

#pragma mark - Outgoing message bubbles
+ (UIImage *)bubbleDefaultOutgoing;
+ (UIImage *)bubbleDefaultOutgoingSelected;

@end
