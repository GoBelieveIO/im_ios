

#import "UIImage+JSMessagesView.h"


@implementation UIImage (JSMessagesView)

#pragma mark - Avatar styles
- (UIImage *)circleImageWithSize:(CGFloat)size
{
    return [self imageAsCircle:YES
                   withDiamter:size
                   borderColor:[UIColor colorWithHue:0.0f saturation:0.0f brightness:0.8f alpha:1.0f]
                   borderWidth:1.0f
                  shadowOffSet:CGSizeMake(0.0f, 1.0f)];
}

- (UIImage *)squareImageWithSize:(CGFloat)size
{
    return [self imageAsCircle:NO
                   withDiamter:size
                   borderColor:[UIColor colorWithHue:0.0f saturation:0.0f brightness:0.8f alpha:1.0f]
                   borderWidth:1.0f
                  shadowOffSet:CGSizeMake(0.0f, 1.0f)];
}

- (UIImage *)imageAsCircle:(BOOL)clipToCircle
               withDiamter:(CGFloat)diameter
               borderColor:(UIColor *)borderColor
               borderWidth:(CGFloat)borderWidth
              shadowOffSet:(CGSize)shadowOffset{
    // increase given size for border and shadow
    CGFloat increase = diameter * 0.15f;
    CGFloat newSize = diameter + increase;
    
    CGRect newRect = CGRectMake(0.0f,
                                0.0f,
                                newSize,
                                newSize);
    
    // fit image inside border and shadow
    CGRect imgRect = CGRectMake(increase,
                                increase,
                                newRect.size.width - (increase * 2.0f),
                                newRect.size.height - (increase * 2.0f));
    
    UIGraphicsBeginImageContextWithOptions(newRect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    // draw shadow
    if(!CGSizeEqualToSize(shadowOffset, CGSizeZero))
        CGContextSetShadowWithColor(context,
                                    CGSizeMake(shadowOffset.width, shadowOffset.height),
                                    3.0f,
                                    [UIColor colorWithWhite:0.0f alpha:0.45f].CGColor);
    
    // draw border
    // as circle or square
    CGPathRef borderPath = (clipToCircle) ? CGPathCreateWithEllipseInRect(imgRect, NULL) : CGPathCreateWithRect(imgRect, NULL);
    
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, borderWidth);
    CGContextAddPath(context, borderPath);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGPathRelease(borderPath);
    CGContextRestoreGState(context);
    
    // clip to circle
    if(clipToCircle) {
        UIBezierPath *imgPath = [UIBezierPath bezierPathWithOvalInRect:imgRect];
        [imgPath addClip];
    }
    
    [self drawInRect:imgRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
} 


#pragma mark - Input bar
+ (UIImage *)inputBar{
    return [UIImage imageNamed:@"input-bar-flat"];
}

+ (UIImage *)inputField{
    return nil; // no graphic around input field.
}

#pragma mark - Bubble cap insets
- (UIImage *)makeStretchableDefaultIncoming{
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(10.0f, 20.0f, 20.0f, 20.0f)
                                resizingMode:UIImageResizingModeStretch];
}

- (UIImage *)makeStretchableDefaultOutgoing{
    return [self resizableImageWithCapInsets:UIEdgeInsetsMake(10.0f, 10.0f, 19.0f, 20.0f)
                                resizingMode:UIImageResizingModeStretch];
}

#pragma mark - Incoming message bubbles
+ (UIImage *)bubbleDefaultIncoming{
    return [[UIImage imageNamed:@"BubbleIncoming"] makeStretchableDefaultIncoming];
}

+ (UIImage *)bubbleDefaultIncomingSelected{
    return [[UIImage imageNamed:@"BubbleIncomingSelected"] makeStretchableDefaultIncoming];
}

#pragma mark - Outgoing message bubbles
+ (UIImage *)bubbleDefaultOutgoing{
    return [[UIImage imageNamed:@"BubbleOutgoing"] makeStretchableDefaultOutgoing];
}

+ (UIImage *)bubbleDefaultOutgoingSelected{
    return [[UIImage imageNamed:@"BubbleOutgoingSelected"] makeStretchableDefaultOutgoing];
}

@end
