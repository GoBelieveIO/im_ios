/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageTextView.h"
#import "NSString+JSMessagesView.h"
#import "KILabel.h"
#import "HCDChatHelper.h"



@interface MessageTextView()
@property(nonatomic, copy) NSString *text;

@end

@implementation MessageTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[KILabel alloc] init];
        self.label.linkDetectionTypes = KILinkTypeOptionURL;
        self.label.font = [UIFont systemFontOfSize:14.0f];
        self.label.numberOfLines = 0;
        self.label.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.label];
    }
    return self;
}

- (void)setMsg:(IMessage *)msg {
    [super setMsg:msg];
    MessageTextContent *text = msg.textContent;
    
    NSAttributedString *attrText = [HCDChatHelper formatMessageString: text.text withFont:[MessageTextView font]];
    self.text = text.text;
    [self.label setAttributedText:attrText];
}



- (CGSize)bubbleSize {
    UIFont *font = [[self class] font];
    CGSize textSize = [MessageTextView textSizeForText:self.text withFont:font];
    return textSize;
}

+ (int)numberOfLinesForMessage:(NSString *)txt {
    return (int)(txt.length / [self maxCharactersPerLine]) + 1;
}


+ (UIFont *)font {
    return [UIFont systemFontOfSize:14.0f];
}

+ (CGSize)textSizeForText:(NSString *)txt withFont:(UIFont*)font{
    CGFloat width = [UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGFloat height = MAX([MessageTextView numberOfLinesForMessage:txt],
                         [txt numberOfLines]) *  30.0f;
    
    UILabel *gettingSizeLabel = [[UILabel alloc] init];
    NSAttributedString *attrText = [HCDChatHelper formatMessageString:txt withFont:font];
    gettingSizeLabel.font = font;
    [gettingSizeLabel setAttributedText:attrText];
    gettingSizeLabel.numberOfLines = 0;
    gettingSizeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize maximumLabelSize = CGSizeMake(width, height);
    
    return  [gettingSizeLabel sizeThatFits:maximumLabelSize];
}


+ (int)maxCharactersPerLine {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 34 : 109;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect bubbleFrame = self.bounds;

    self.label.frame = bubbleFrame;
}



@end
