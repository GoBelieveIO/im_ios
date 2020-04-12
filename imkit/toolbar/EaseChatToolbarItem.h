//
//  EMChatToolbarItem.h
//  ChatDemo-UI3.0
//
//  Created by dhc on 15/7/2.
//  Copyright (c) 2015年 easemob.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface EaseChatToolbarItem : NSObject

/**
 *  按钮
 */
@property (strong, nonatomic, readonly) UIButton *button;

/**
 *  点击按钮之后在toolbar下方延伸出的页面
 */
@property (strong, nonatomic) UIView *button2View;

- (instancetype)initWithButton:(UIButton *)button
                      withView:(UIView *)button2View;

@end
