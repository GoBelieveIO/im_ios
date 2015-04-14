/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageTextView.h"
#import "Constants.h"


@implementation MessageTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
      
    }
    return self;
}

- (void)setText:(NSString *)newText
{
    _text = newText;
    [self setNeedsDisplay];
}

#pragma mark - Drawing
- (CGRect)bubbleFrame{

    CGSize bubbleSize = [BubbleView bubbleSizeForText:self.text withFont:[BubbleView font]];
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}

- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
    UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    
    CGRect bubbleFrame = [self bubbleFrame];
	[image drawInRect:bubbleFrame];
    
    [self drawMsgStateSign: frame];
    
    CGSize textSize = [BubbleView textSizeForText:self.text withFont:[BubbleView font]];
    
    CGFloat textX = image.leftCapWidth  + (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x : 0.0f);
    
    CGRect textFrame = CGRectMake(textX,
                                  kPaddingTop + kMarginTop - 2,
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
