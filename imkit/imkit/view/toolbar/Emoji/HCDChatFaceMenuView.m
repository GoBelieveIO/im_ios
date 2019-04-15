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
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIScrollView *scrollView;// 菜单滑动ScrollerView
@property (nonatomic, strong) NSMutableArray *faceMenuViewArray; // faceMenuViewArray 菜单栏上的按钮数组
@end

@implementation HCDChatFaceMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self addSubview:self.addButton];
        [self addSubview:self.scrollView];
    }
    return self;
}

#pragma mark - Public Methods
- (void)setFaceGroupArray:(NSMutableArray *)faceGroupArray {
    _faceGroupArray = faceGroupArray;
    float w = self.height * 1.25;
    [self.addButton setFrame:CGRectMake(0, 0, w, self.height)];
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(w, 6, 0.5, self.height - 12)];
    [line setBackgroundColor:DEFAULT_LINE_GRAY_COLOR];
    [self addSubview:line];
    
    [self.sendButton setFrame:CGRectMake(self.width - w * 1.2, 0, w * 1.2, self.height)];
    [self.scrollView setFrame:CGRectMake(w + 0.5, 0, self.width - self.addButton.width, self.height)];
    [self.scrollView setContentSize:CGSizeMake(w * (faceGroupArray.count + 3), self.scrollView.height)];
    float x = 0;
    int i = 0;
    
    
//    for (HCDChatFaceGroup *group in faceGroupArray) {
    {
        //目前仅需显示一个
        HCDChatFaceGroup *group = [faceGroupArray firstObject];
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, 0, w, self.height)];
        [button.imageView setContentMode:UIViewContentModeCenter];
        [button setImage:[UIImage imageNamed:group.groupImageName] forState:UIControlStateNormal];
        [button setTag:i ++];// 不同的组按钮有不同的Tag
        [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
        [self.faceMenuViewArray addObject:button];
        [self.scrollView addSubview:button];
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(button.x + button.width, 6, 0.5, self.height - 12)];
        [line setBackgroundColor:DEFAULT_LINE_GRAY_COLOR];
        [self.scrollView addSubview:line];
        x += button.width + 0.5;
    }
    [self buttonDown:[self.faceMenuViewArray firstObject]];
}

/**
 *  @return
 */
#pragma mark - Event Response
- (void)buttonDown:(UIButton *)sender {
    
    if (sender.tag == -1) {
        if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceMenuViewAddButtonDown)]) {
            [_delegate chatBoxFaceMenuViewAddButtonDown];
        }
    }
    // 发送点击事件
    else if (sender.tag == -2) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceMenuViewSendButtonDown)]) {
            [_delegate chatBoxFaceMenuViewSendButtonDown];
        }
    } else {
        
        for (UIButton *button in self.faceMenuViewArray)
        {
            [button setBackgroundColor:[UIColor whiteColor]];
        }
        
        [sender setBackgroundColor:DEFAULT_CHATBOX_COLOR];
        if ([[_faceGroupArray objectAtIndex:sender.tag] faceType] == HCDFaceTypeEmoji)
        {
            [self addSubview:self.sendButton];
            self.scrollView.width = self.width - self.addButton.width - self.sendButton.width - 1;
        } else {
            [self.sendButton removeFromSuperview];
            self.scrollView.width = self.width - self.addButton.width - 0.5;
        }
        if (_delegate && [_delegate respondsToSelector:@selector(chatBoxFaceMenuView:didSelectedFaceMenuIndex:)])
        {
            [_delegate chatBoxFaceMenuView:self didSelectedFaceMenuIndex:sender.tag];
        }
    }
}

#pragma mark - Getter
- (UIButton *)addButton {
    if (_addButton == nil) {
        _addButton = [[UIButton alloc] init];
        _addButton.tag = -1;
//        [_addButton setImage:[UIImage imageNamed:@"Card_AddIcon"] forState:UIControlStateNormal];
        [_addButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
    }
    return _addButton;
}

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

- (UIScrollView *)scrollView {
    if (_scrollView == nil) {
        _scrollView = [[UIScrollView alloc] init];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [_scrollView setScrollsToTop:NO];
    }
    return _scrollView;
}

- (NSMutableArray *)faceMenuViewArray {
    if (_faceMenuViewArray == nil) {
        _faceMenuViewArray = [[NSMutableArray alloc] init];
    }
    return _faceMenuViewArray;
}

@end
