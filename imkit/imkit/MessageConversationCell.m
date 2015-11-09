//
//  MessageConversationCell.m
//  Message
//
//  Created by daozhu on 14-7-6.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageConversationCell.h"


#define kCatchWidth 74.0f


@interface MessageConversationCell () 

@end


@implementation MessageConversationCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    CALayer *imageLayer = [self.headView layer];   //获取ImageView的层
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:self.headView.frame.size.width/2];
    
}

#pragma mark - Private Methods

#pragma mark - Overridden Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

-(void) showNewMessage:(int)count{
//    JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.messageContent alignment:JSBadgeViewAlignmentCenterRight];
//    [badgeView setBadgeTextFont:[UIFont systemFontOfSize:14.0f]];
//    [self.messageContent bringSubviewToFront:badgeView];
//    if (count > 99) {
//       badgeView.badgeText = @"99+";
//    }else{
//        badgeView.badgeText = [NSString stringWithFormat:@"%d",count];
//    }
}

-(void) clearNewMessage{
//    for (UIView *vi in [self.messageContent subviews]) {
//        if ([vi isKindOfClass:[JSBadgeView class]]) {
//            [vi removeFromSuperview];
//        }
//    }
}


@end
