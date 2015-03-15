//
//  MessageTableSectionHeaderView.m
//  Message
//
//  Created by daozhu on 14-7-6.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageTableSectionHeaderView.h"
#import <QuartzCore/QuartzCore.h>

@implementation MessageTableSectionHeaderView

-(void)awakeFromNib{
    self.sectionHeader.layer.cornerRadius = 10;
    self.sectionHeader.layer.masksToBounds = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
