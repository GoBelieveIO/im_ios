//
//  EMChatToolbarItem.m
//  ChatDemo-UI3.0
//
//  Created by dhc on 15/7/2.
//  Copyright (c) 2015年 easemob.com. All rights reserved.
//

#import "EaseChatToolbarItem.h"

@implementation EaseChatToolbarItem

- (instancetype)initWithButton:(UIButton *)button
                      withView:(UIView *)button2View
{
    self = [super init];
    if (self) {
        _button = button;
        _button2View = button2View;
    }
    
    return self;
}

@end
