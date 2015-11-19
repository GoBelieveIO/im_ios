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
    [self setNeedsDisplay];
}

#pragma mark - Drawing


+ (CGFloat)cellHeightForText:(NSString *)txt
{
    return [MessageTextView bubbleSizeForText:txt withFont:[BubbleView font]].height + kMarginTop + kMarginBottom;
}

+ (CGSize)bubbleSizeForText:(NSString *)txt withFont:(UIFont*)font
{
    CGSize textSize = [BubbleView textSizeForText:txt withFont:font];
    return CGSizeMake(textSize.width + kBubblePaddingHead + kBubblePaddingTail + 16,
                      textSize.height + kPaddingTop + kPaddingBottom + 16);
}



- (CGRect)bubbleFrame{

    CGSize bubbleSize = [MessageTextView bubbleSizeForText:self.text withFont:[BubbleView font]];
    bubbleSize.height = MAX(bubbleSize.height, 40);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}

- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
    CGRect bubbleFrame = [self bubbleFrame];
    
    CGSize textSize = [BubbleView textSizeForText:self.text withFont:[BubbleView font]];
    
    CGFloat textX;
    if (self.type == BubbleMessageTypeOutgoing) {
        textX = (bubbleFrame.origin.x + 7 + 8);
    } else {
        textX = (8 + 8);
    }
    
    CGRect textFrame = CGRectMake(textX,
                                  kPaddingTop + kMarginTop + 8,
                                  textSize.width,
                                  textSize.height);
    
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
        
        [self.text drawInRect:textFrame
               withAttributes:attributes];
    }else{
        [self.text drawInRect:textFrame
                     withFont:[BubbleView font]
                lineBreakMode:NSLineBreakByWordWrapping
                    alignment:NSTextAlignmentLeft];
    }
}


@end
