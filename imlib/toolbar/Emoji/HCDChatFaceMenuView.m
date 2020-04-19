//
//  HCDChatFaceMenuView.m
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import "HCDChatFaceMenuView.h"
#import "HCDChatInputBarDefine.h"
#import "UIView+HCD_Extension.h"
#import "HCDChatFace.h"

@interface HCDChatFaceMenuView ()
@property (nonatomic, strong) UIButton *sendButton;

@end

@implementation HCDChatFaceMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor whiteColor]];

        float w = self.height * 1.25;
        [self.sendButton setFrame:CGRectMake(self.width - w * 1.2, 0, w * 1.2, self.height)];
        [self addSubview:self.sendButton];
    }
    return self;
}


/**
 *  @return
 */
#pragma mark - Event Response
- (void)buttonDown:(UIButton *)sender {
    // 发送点击事件
    if (sender.tag == -2) {
        if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceMenuViewSendButtonDown)]) {
            [_delegate chatBoxFaceMenuViewSendButtonDown];
        }
    }
}

#pragma mark - Getter
- (UIButton *)sendButton {
    if (_sendButton == nil) {
        _sendButton = [[UIButton alloc] init];
        [_sendButton setTitle:@"发送" forState:UIControlStateNormal];
        [_sendButton.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
        [_sendButton setBackgroundColor:[UIColor colorWithRed:0.1 green:0.4 blue:0.8 alpha:1.0]];
        _sendButton.tag = -2;
        [_sendButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    }
    return _sendButton;
}

@end
