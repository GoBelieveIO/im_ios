/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageTableSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"

@interface PaddingLabel : UILabel

@end

@implementation PaddingLabel

-(CGSize)intrinsicContentSize{
    CGSize contentSize = [super intrinsicContentSize];
    return CGSizeMake(contentSize.width + 12, contentSize.height);
}

@end

@implementation MessageTableSectionHeaderView

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.sectionHeader = [[PaddingLabel alloc] init];
        self.sectionHeader.layer.cornerRadius = 10;
        self.sectionHeader.layer.masksToBounds = YES;
        self.sectionHeader.backgroundColor = RGBCOLOR(0xF6, 0xF4, 0xE5);
        self.sectionHeader.textAlignment = NSTextAlignmentCenter;
        self.sectionHeader.translatesAutoresizingMaskIntoConstraints = NO;

        [self addSubview:self.sectionHeader];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sectionHeader attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.sectionHeader attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];

        self.alpha = 0.9;
    }
    return self;
}


@end
