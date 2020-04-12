//
//  OverlayLabel.m
//  gobelieve
//
//  Created by houxh on 2017/12/4.
//

#import "OverlayLabel.h"

#define KILabelRangeKey  @"range"
#define KILabelLinkKey  @"link"

@implementation OverlayLabel


- (NSArray *)getRangesForURLs:(NSAttributedString *)text
{
    NSMutableArray *rangesForURLs = [[NSMutableArray alloc] init];;
    
    // Use a data detector to find urls in the text
    NSError *error = nil;
    NSDataDetector *detector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:&error];
    
    NSString *plainText = text.string;
    
    NSArray *matches = [detector matchesInString:plainText
                                         options:0
                                           range:NSMakeRange(0, text.length)];
    
    // Add a range entry for every url we found
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        
        // If there's a link embedded in the attributes, use that instead of the raw text
        NSString *realURL = [text attribute:NSLinkAttributeName atIndex:matchRange.location effectiveRange:nil];
        if (realURL == nil)
            realURL = [plainText substringWithRange:matchRange];
        
       
            if ([match resultType] == NSTextCheckingTypeLink)
            {
                [rangesForURLs addObject:@{
                                           KILabelRangeKey : [NSValue valueWithRange:matchRange],
                                           KILabelLinkKey : realURL,
                                           }];
            }
   
    }
    
    return rangesForURLs;
}

// Returns attributed string attributes based on the text properties set on the label.
// These are styles that are only applied when NOT using the attributedText directly.
- (NSDictionary *)attributesFromProperties
{
    // Setup shadow attributes
    NSShadow *shadow = shadow = [[NSShadow alloc] init];
    if (self.shadowColor)
    {
        shadow.shadowColor = self.shadowColor;
        shadow.shadowOffset = self.shadowOffset;
    }
    else
    {
        shadow.shadowOffset = CGSizeMake(0, -1);
        shadow.shadowColor = nil;
    }
    
    // Setup color attributes
    UIColor *color = self.textColor;
    if (!self.isEnabled)
    {
        color = [UIColor lightGrayColor];
    }
    else if (self.isHighlighted)
    {
        color = self.highlightedTextColor;
    }
    
    // Setup paragraph attributes
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = self.textAlignment;
    
    // Create the dictionary
    NSDictionary *attributes = @{NSFontAttributeName : self.font,
                                 NSForegroundColorAttributeName : color,
                                 NSShadowAttributeName : shadow,
                                 NSParagraphStyleAttributeName : paragraph,
                                 };
    return attributes;
}



- (NSAttributedString *)addLinkAttributesToAttributedString:(NSAttributedString *)string linkRanges:(NSArray *)linkRanges
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    
    for (NSDictionary *dictionary in linkRanges)
    {
        NSRange range = [[dictionary objectForKey:KILabelRangeKey] rangeValue];
        NSDictionary *attributes = @{NSForegroundColorAttributeName : self.tintColor};

        // Add a link attribute using the stored link
        //[attributedString addAttribute:NSLinkAttributeName value:dictionary[KILabelLinkKey] range:range];
        
        // Use our tint color to hilight the link
        [attributedString addAttributes:attributes range:range];
    }
    return attributedString;
}


@end
