/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageTextView.h"
#import "Constants.h"

@interface MessageTextView()
@property(nonatomic, copy) NSString *text;
@property(nonatomic, copy) NSString *translation;
@end

@implementation MessageTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      
    }
    return self;
}


- (void)setMsg:(IMessage *)msg {
    [super setMsg:msg];
    MessageTextContent *text = msg.textContent;
    self.text = text.text;
    self.translation = msg.translation;
    [self setNeedsDisplay];
}


#pragma mark - Drawing

+ (CGFloat)cellHeightForText:(NSString *)txt {
    [self cellHeightForText:txt translation:nil];
}

+ (CGFloat)cellHeightForText:(NSString *)txt translation:(NSString*)translation {
    float height = [BubbleView textSizeForText:txt withFont:[BubbleView font]].height + kMarginTop + kMarginBottom + kPaddingTop + kPaddingBottom + 16;
    
    if (translation.length > 0) {
        height += [MessageTextView textSizeForText:translation withFont:[BubbleView font]].height + 16;
    }
    return height;
}

- (CGRect)bubbleFrame{

    CGSize bubbleSize = [BubbleView textSizeForText:self.text withFont:[BubbleView font]];
    
    bubbleSize.width = bubbleSize.width + kBubblePaddingHead + kBubblePaddingTail + 16;
    bubbleSize.height = bubbleSize.height + kPaddingTop + kPaddingBottom + 16;
    
    bubbleSize.height = MAX(bubbleSize.height, 40);
    
    if (self.translation.length > 0) {
        CGSize translationSize = [BubbleView textSizeForText:self.translation withFont:[BubbleView font]];
        translationSize.width = translationSize.width + kBubblePaddingHead + kBubblePaddingTail + 16;
        translationSize.height = translationSize.height + 16;
        bubbleSize.width = MAX(bubbleSize.width, translationSize.width);
        bubbleSize.height += translationSize.height;
        
        float x = floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f);
        return CGRectMake(x,
                          floorf(kMarginTop),
                          floorf(bubbleSize.width),
                          floorf(bubbleSize.height));
        
    } else {
        float x = floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f);
        return CGRectMake(x,
                          floorf(kMarginTop),
                          floorf(bubbleSize.width),
                          floorf(bubbleSize.height));
    }
    
}

- (void)drawText:(NSString*)text frame:(CGRect)textFrame {
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending){
        UIColor* textColor = RGBACOLOR(31.0f, 31.0f, 31.0f, 1.0f);
        if (self.selectedToShowCopyMenu){
            textColor = RGBACOLOR(91.0f, 91.0f, 91.0f, 1.0f);
        }
        
        NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [paragraphStyle setAlignment:NSTextAlignmentLeft];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        
        NSDictionary* attributes = @{NSFontAttributeName: [BubbleView font],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        
        NSMutableDictionary* dict = [attributes mutableCopy];
        [dict setObject:textColor forKey:NSForegroundColorAttributeName];
        attributes = [NSDictionary dictionaryWithDictionary:dict];
        
        [text drawInRect:textFrame
               withAttributes:attributes];
    }else{
        [text drawInRect:textFrame
                     withFont:[BubbleView font]
                lineBreakMode:NSLineBreakByWordWrapping
                    alignment:NSTextAlignmentLeft];
    }

}

- (void)drawLine:(CGPoint)start end:(CGPoint)end {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 1.0f);
    CGContextMoveToPoint(context, start.x, start.y);
    CGContextAddLineToPoint(context, end.x, end.y);
    CGContextStrokePath(context);
}

- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
    CGSize textSize = [BubbleView textSizeForText:self.text withFont:[BubbleView font]];
    
    CGFloat textX;
    if (self.type == BubbleMessageTypeOutgoing) {
        float x = floorf( self.frame.size.width - textSize.width - kBubblePaddingHead - kBubblePaddingTail - 16);
        textX = (x + 7 + 8);
    } else {
        textX = (8 + 8);
    }
    
    CGRect textFrame = CGRectMake(textX,
                                  kPaddingTop + kMarginTop + 8,
                                  textSize.width,
                                  textSize.height);
    
    [self drawText:self.text frame:textFrame];
    
    if (self.translation.length > 0) {
        float y = textFrame.origin.y + textFrame.size.height + 8;
        float w = textFrame.size.width;
        
        textSize = [BubbleView textSizeForText:self.translation withFont:[BubbleView font]];

        w = MAX(w, textSize.width);
        CGPoint start = CGPointMake(textX, y);
        CGPoint end = CGPointMake(textX + w, y);
        [self drawLine:start end:end];
        
        textFrame = CGRectMake(textX,
                               y + 8,
                               textSize.width,
                               textSize.height);
        
        [self drawText:self.translation frame:textFrame];
    }
}


@end
