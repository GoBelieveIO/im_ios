/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageTimeBaseView.h"
#import "Constants.h"

@interface PaddingLabel : UILabel

@end

@implementation PaddingLabel

-(CGSize)intrinsicContentSize{
    CGSize contentSize = [super intrinsicContentSize];
    return CGSizeMake(contentSize.width + 12, contentSize.height);
}

@end

@implementation MessageTimeBaseView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.label = [[PaddingLabel alloc] init];
        self.label.layer.cornerRadius = 10;
        self.label.layer.masksToBounds = YES;
        self.label.backgroundColor = RGBCOLOR(0xF6, 0xF4, 0xE5);
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:self.label];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        self.alpha = 0.9;

    }
    return self;
}

- (void)dealloc {

}

- (void)setMsg:(IMessage*)msg {
    [super setMsg:msg];
    self.label.text = msg.timeBaseContent.timeDesc;
}
@end
