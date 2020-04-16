//
//  EMChatToolbar.m
//  ChatDemo-UI3.0
//
//  Created by dhc on 15/7/1.
//  Copyright (c) 2015年 easemob.com. All rights reserved.
//

#import "EaseChatToolbar.h"

#import "IUser.h"
#import "HCDChatBoxFaceView.h"
#import "HCDChatInputBarDefine.h"
#import "HCDChatFaceHeleper.h"

@interface EaseChatToolbar()<UITextViewDelegate, HCDChatBoxFaceViewDelegate>

@property (nonatomic, assign) BOOL at;//是否输入了at
@property (nonatomic) NSMutableArray *atUsers;


@property (strong, nonatomic) NSMutableArray *leftItems;
@property (strong, nonatomic) NSMutableArray *rightItems;

/**
 *  背景
 */
@property (strong, nonatomic) UIImageView *toolbarBackgroundImageView;
@property (strong, nonatomic) UIImageView *backgroundImageView;

/**
 *  底部扩展页面
 */
@property (nonatomic) BOOL isShowButtomView;

/**
 *  按钮、toolbarView
 */
@property (strong, nonatomic) UIView *toolbarView;
@property (strong, nonatomic) UIButton *recordButton;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIButton *faceButton;

/**
 *  输入框
 */
@property (nonatomic) CGFloat previousTextViewContentHeight;//上一次inputTextView的contentSize.height
@property (nonatomic) NSLayoutConstraint *inputViewWidthItemsLeftConstraint;
@property (nonatomic) NSLayoutConstraint *inputViewWidthoutItemsLeftConstraint;

@end

@implementation EaseChatToolbar

- (instancetype)initWithFrame:(CGRect)frame {
    self = [self initWithFrame:frame
             horizontalPadding:8
               verticalPadding:5
            inputViewMinHeight:36
            inputViewMaxHeight:120];
    if (self) {

    }
    
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame
            horizontalPadding:(CGFloat)horizontalPadding
              verticalPadding:(CGFloat)verticalPadding
           inputViewMinHeight:(CGFloat)inputViewMinHeight
           inputViewMaxHeight:(CGFloat)inputViewMaxHeight {
    if (frame.size.height < (verticalPadding * 2 + inputViewMinHeight)) {
        frame.size.height = verticalPadding * 2 + inputViewMinHeight;
    }
    self = [super initWithFrame:frame];
    if (self) {
        self.atUsers = [NSMutableArray array];
        _horizontalPadding = horizontalPadding;
        _verticalPadding = verticalPadding;
        _inputViewMinHeight = inputViewMinHeight;
        _inputViewMaxHeight = inputViewMaxHeight;
        
        _leftItems = [NSMutableArray array];
        _rightItems = [NSMutableArray array];
        _isShowButtomView = NO;
    }
    return self;
}

#pragma mark - setup subviews

- (void)setupSubviews:(NSDictionary*)config {
    
    CGRect moreFrame = CGRectMake(0, CGRectGetMaxY(self.bounds), self.frame.size.width, 180);
    self.moreView = [[EaseChatBarMoreView alloc] initWithFrame:moreFrame config:config];
    self.moreView.backgroundColor = [UIColor colorWithRed:240 / 255.0 green:242 / 255.0 blue:247 / 255.0 alpha:1.0];
    
    CGRect faceFrame = CGRectMake(0, CGRectGetMaxY(self.bounds) + HEIGHT_CHATBOXVIEW, SCREEN_WIDTH, HEIGHT_CHATBOXVIEW);
    HCDChatBoxFaceView *faceView = [[HCDChatBoxFaceView alloc] initWithFrame:faceFrame];
    faceView.delegate = self;
    self.faceView = faceView;

    //backgroundImageView
    _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    _backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _backgroundImageView.backgroundColor = [UIColor clearColor];
    _backgroundImageView.image = [[UIImage imageNamed:@"messageToolbarBg"] stretchableImageWithLeftCapWidth:0.5 topCapHeight:10];
    [self addSubview:_backgroundImageView];
    
    //toolbar
    _toolbarView = [[UIView alloc] initWithFrame:self.bounds];
    _toolbarView.backgroundColor = [UIColor clearColor];
    [self addSubview:_toolbarView];
    
    _toolbarBackgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _toolbarView.frame.size.width, _toolbarView.frame.size.height)];
    _toolbarBackgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _toolbarBackgroundImageView.backgroundColor = [UIColor clearColor];
    [_toolbarView addSubview:_toolbarBackgroundImageView];
    
    //输入框
    _inputTextView = [[EaseTextView alloc] initWithFrame:CGRectMake(self.horizontalPadding, self.verticalPadding, self.frame.size.width - self.verticalPadding * 2, self.frame.size.height - self.verticalPadding * 2)];
    _inputTextView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _inputTextView.scrollEnabled = YES;
    _inputTextView.returnKeyType = UIReturnKeySend;
    _inputTextView.enablesReturnKeyAutomatically = YES; // UITextView内部判断send按钮是否可以用
    _inputTextView.placeHolder = NSLocalizedString(@"message.toolBar.inputPlaceHolder", @"input a new message");
    _inputTextView.delegate = self;
    _inputTextView.backgroundColor = [UIColor clearColor];
    _inputTextView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    _inputTextView.layer.borderWidth = 0.65f;
    _inputTextView.layer.cornerRadius = 6.0f;
    _previousTextViewContentHeight = [self _getTextViewContentH:_inputTextView];
    [_toolbarView addSubview:_inputTextView];
    
    //转变输入样式
    UIButton *styleChangeButton = [[UIButton alloc] init];
    styleChangeButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [styleChangeButton setImage:[UIImage imageNamed:@"chatBar_record"] forState:UIControlStateNormal];
    [styleChangeButton setImage:[UIImage imageNamed:@"chatBar_keyboard"] forState:UIControlStateSelected];
    [styleChangeButton addTarget:self action:@selector(styleButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    EaseChatToolbarItem *styleItem = [[EaseChatToolbarItem alloc] initWithButton:styleChangeButton withView:nil];
    [self setInputViewLeftItems:@[styleItem]];
    
    //录制
    self.recordButton = [[UIButton alloc] initWithFrame:self.inputTextView.frame];
    self.recordButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [self.recordButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.recordButton setBackgroundImage:[[UIImage imageNamed:@"chatBar_recordBg"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateNormal];
    [self.recordButton setBackgroundImage:[[UIImage imageNamed:@"chatBar_recordSelectedBg"] stretchableImageWithLeftCapWidth:10 topCapHeight:10] forState:UIControlStateHighlighted];
    [self.recordButton setTitle:kTouchToRecord forState:UIControlStateNormal];
    [self.recordButton setTitle:kTouchToFinish forState:UIControlStateHighlighted];
    self.recordButton.hidden = YES;
    [self.recordButton addTarget:self action:@selector(recordButtonTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.recordButton addTarget:self action:@selector(recordButtonTouchUpOutside) forControlEvents:UIControlEventTouchUpOutside];
    [self.recordButton addTarget:self action:@selector(recordButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
    [self.recordButton addTarget:self action:@selector(recordDragOutside) forControlEvents:UIControlEventTouchDragExit];
    [self.recordButton addTarget:self action:@selector(recordDragInside) forControlEvents:UIControlEventTouchDragEnter];
    self.recordButton.hidden = YES;
    [self.toolbarView addSubview:self.recordButton];
    
    //表情
    self.faceButton = [[UIButton alloc] init];
    self.faceButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.faceButton setImage:[UIImage imageNamed:@"chatBar_face"] forState:UIControlStateNormal];
    [self.faceButton setImage:[UIImage imageNamed:@"chatBar_faceSelected"] forState:UIControlStateHighlighted];
    [self.faceButton setImage:[UIImage imageNamed:@"chatBar_keyboard"] forState:UIControlStateSelected];
    [self.faceButton addTarget:self action:@selector(faceButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    EaseChatToolbarItem *faceItem = [[EaseChatToolbarItem alloc] initWithButton:self.faceButton withView:self.faceView];
    
    //更多
    self.moreButton = [[UIButton alloc] init];
    self.moreButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.moreButton setImage:[UIImage imageNamed:@"chatBar_more"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage imageNamed:@"chatBar_moreSelected"] forState:UIControlStateHighlighted];
    [self.moreButton setImage:[UIImage imageNamed:@"chatBar_keyboard"] forState:UIControlStateSelected];
    [self.moreButton addTarget:self action:@selector(moreButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    EaseChatToolbarItem *moreItem = [[EaseChatToolbarItem alloc] initWithButton:self.moreButton withView:self.moreView];
    
    [self setInputViewRightItems:@[faceItem, moreItem]];
}

- (void)dealloc {
    _delegate = nil;
    _inputTextView.delegate = nil;
    _inputTextView = nil;
}



- (void)atUser:(IUser*)user {
    if (user.name.length > 0) {
        NSInteger index = [self.atUsers indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            IUser *u = (IUser*)obj;
            if (u.uid == user.uid) {
                *stop = YES;
                return YES;
            }
            return NO;
        }];
        
        if (index == NSNotFound) {
            [self.atUsers addObject:user];
        }
        NSString *name = [NSString stringWithFormat:@"%@ ", user.name];
        [self.inputTextView insertText:name];
        [self.inputTextView becomeFirstResponder];
    }
}

#pragma mark - setter

- (void)setText:(NSString*)text {
    self.inputTextView.text = text;
    [self _willShowInputTextViewToHeight:[self _getTextViewContentH:self.inputTextView]];
}

- (void)setInputViewLeftItems:(NSArray *)inputViewLeftItems
{
    for (EaseChatToolbarItem *item in self.leftItems) {
        [item.button removeFromSuperview];
        [item.button2View removeFromSuperview];
    }
    [self.leftItems removeAllObjects];
    
    CGFloat oX = self.horizontalPadding;
    CGFloat itemHeight = self.toolbarView.frame.size.height - self.verticalPadding * 2;
    for (id item in inputViewLeftItems) {
        if ([item isKindOfClass:[EaseChatToolbarItem class]]) {
            EaseChatToolbarItem *chatItem = (EaseChatToolbarItem *)item;
            if (chatItem.button) {
                CGRect itemFrame = chatItem.button.frame;
                if (itemFrame.size.height == 0) {
                    itemFrame.size.height = itemHeight;
                }
                
                if (itemFrame.size.width == 0) {
                    itemFrame.size.width = itemFrame.size.height;
                }
                
                itemFrame.origin.x = oX;
                itemFrame.origin.y = (self.toolbarView.frame.size.height - itemFrame.size.height) / 2;
                chatItem.button.frame = itemFrame;
                oX += (itemFrame.size.width + self.horizontalPadding);
                
                [self.toolbarView addSubview:chatItem.button];
                [self.leftItems addObject:chatItem];
            }
        }
    }
    
    CGRect inputFrame = self.inputTextView.frame;
    CGFloat value = inputFrame.origin.x - oX;
    inputFrame.origin.x = oX;
    inputFrame.size.width += value;
    self.inputTextView.frame = inputFrame;
    
    CGRect recordFrame = self.recordButton.frame;
    recordFrame.origin.x = inputFrame.origin.x;
    recordFrame.size.width = inputFrame.size.width;
    self.recordButton.frame = recordFrame;
}

- (void)setInputViewRightItems:(NSArray *)inputViewRightItems
{
    for (EaseChatToolbarItem *item in self.rightItems) {
        [item.button removeFromSuperview];
        [item.button2View removeFromSuperview];
    }
    [self.rightItems removeAllObjects];
    
    CGFloat oMaxX = self.toolbarView.frame.size.width - self.horizontalPadding;
    CGFloat itemHeight = self.toolbarView.frame.size.height - self.verticalPadding * 2;
    if ([inputViewRightItems count] > 0) {
        for (NSInteger i = (inputViewRightItems.count - 1); i >= 0; i--) {
            id item = [inputViewRightItems objectAtIndex:i];
            if ([item isKindOfClass:[EaseChatToolbarItem class]]) {
                EaseChatToolbarItem *chatItem = (EaseChatToolbarItem *)item;
                if (chatItem.button) {
                    CGRect itemFrame = chatItem.button.frame;
                    if (itemFrame.size.height == 0) {
                        itemFrame.size.height = itemHeight;
                    }
                    
                    if (itemFrame.size.width == 0) {
                        itemFrame.size.width = itemFrame.size.height;
                    }
                    
                    oMaxX -= itemFrame.size.width;
                    itemFrame.origin.x = oMaxX;
                    itemFrame.origin.y = (self.toolbarView.frame.size.height - itemFrame.size.height) / 2;
                    chatItem.button.frame = itemFrame;
                    oMaxX -= self.horizontalPadding;
                    
                    [self.toolbarView addSubview:chatItem.button];
                    [self addSubview:chatItem.button2View];
                    [self.rightItems addObject:item];
                }
            }
        }
    }
    
    CGRect inputFrame = self.inputTextView.frame;
    CGFloat value = oMaxX - CGRectGetMaxX(inputFrame);
    inputFrame.size.width += value;
    self.inputTextView.frame = inputFrame;
    
    CGRect recordFrame = self.recordButton.frame;
    recordFrame.origin.x = inputFrame.origin.x;
    recordFrame.size.width = inputFrame.size.width;
    self.recordButton.frame = recordFrame;
}

#pragma mark - private input view

- (CGFloat)_getTextViewContentH:(UITextView *)textView {
    return ceilf([textView sizeThatFits:textView.frame.size].height);
}

- (void)setInputTextViewHeight:(CGFloat)toHeight {
    if (toHeight < self.inputViewMinHeight) {
        toHeight = self.inputViewMinHeight;
    }
    if (toHeight > self.inputViewMaxHeight) {
        toHeight = self.inputViewMaxHeight;
    }
    
    if (toHeight == _previousTextViewContentHeight)
    {
        return;
    }
    else{
        CGFloat changeHeight = toHeight - _previousTextViewContentHeight;
        
        CGRect rect = self.frame;
        rect.size.height += changeHeight;
        rect.origin.y -= changeHeight;
        self.frame = rect;
        
        rect = self.toolbarView.frame;
        rect.size.height += changeHeight;
        self.toolbarView.frame = rect;
        
        rect = self.faceView.frame;
        rect.origin.y += changeHeight;
        self.faceView.frame = rect;
        
        rect = self.moreView.frame;
        rect.origin.y += changeHeight;
        self.moreView.frame = rect;
        
        //文本垂直居中
        [self.inputTextView setContentOffset:CGPointMake(0.0f, (self.inputTextView.contentSize.height - self.inputTextView.frame.size.height) / 2) animated:YES];

        _previousTextViewContentHeight = toHeight;
    }
}

- (void)_willShowInputTextViewToHeight:(CGFloat)toHeight
{
    if (toHeight < self.inputViewMinHeight) {
        toHeight = self.inputViewMinHeight;
    }
    if (toHeight > self.inputViewMaxHeight) {
        toHeight = self.inputViewMaxHeight;
    }
    
    if (toHeight == _previousTextViewContentHeight)
    {
        return;
    }
    else{
        CGFloat changeHeight = toHeight - _previousTextViewContentHeight;
        
        CGRect rect = self.frame;
        rect.size.height += changeHeight;
        rect.origin.y -= changeHeight;
        self.frame = rect;
        
        rect = self.toolbarView.frame;
        rect.size.height += changeHeight;
        self.toolbarView.frame = rect;
        
        rect = self.faceView.frame;
        rect.origin.y += changeHeight;
        self.faceView.frame = rect;
        
        rect = self.moreView.frame;
        rect.origin.y += changeHeight;
        self.moreView.frame = rect;
        
        //文本垂直居中
        [self.inputTextView setContentOffset:CGPointMake(0.0f, (self.inputTextView.contentSize.height - self.inputTextView.frame.size.height) / 2) animated:YES];

        _previousTextViewContentHeight = toHeight;
        
        if (_delegate && [_delegate respondsToSelector:@selector(chatToolbarDidChangeFrameToHeight:)]) {
            [_delegate chatToolbarDidChangeFrameToHeight:self.frame.size.height];
        }
    }
}

#pragma mark - private bottom view

- (void)_willShowBottomHeight:(CGFloat)bottomHeight
{
    CGRect fromFrame = self.frame;
    CGFloat toHeight = self.toolbarView.frame.size.height + bottomHeight;
    CGRect toFrame = CGRectMake(fromFrame.origin.x, fromFrame.origin.y + (fromFrame.size.height - toHeight), fromFrame.size.width, toHeight);
    
    //如果需要将所有扩展页面都隐藏，而此时已经隐藏了所有扩展页面，则不进行任何操作
    if(bottomHeight == 0 && self.frame.size.height == self.toolbarView.frame.size.height)
    {
        return;
    }
    
    if (bottomHeight == 0) {
        self.isShowButtomView = NO;
    }
    else{
        self.isShowButtomView = YES;
    }
    
    self.frame = toFrame;
    
    if (_delegate && [_delegate respondsToSelector:@selector(chatToolbarDidChangeFrameToHeight:)]) {
        [_delegate chatToolbarDidChangeFrameToHeight:toHeight];
    }
}

- (void)_willShowBottomView:(UIView *)bottomView
{
    CGFloat bottomHeight = bottomView ? bottomView.frame.size.height : 0;
    [self _willShowBottomHeight:bottomHeight];
    
    if (bottomView) {
        CGRect rect = bottomView.frame;
        rect.origin.y = CGRectGetMaxY(self.toolbarView.frame);
        bottomView.frame = rect;
    }
    

    if (bottomView) {
        [self bringSubviewToFront:bottomView];
    }
}

- (void)_willShowKeyboardFromFrame:(CGRect)beginFrame toFrame:(CGRect)toFrame
{
    if (beginFrame.origin.y == [[UIScreen mainScreen] bounds].size.height)
    {
        [self _willShowBottomHeight:toFrame.size.height];
    }
    else if (toFrame.origin.y == [[UIScreen mainScreen] bounds].size.height)
    {
        [self _willShowBottomHeight:0];
    }
    else{
        [self _willShowBottomHeight:toFrame.size.height];
    }
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(inputTextViewWillBeginEditing:)]) {
        [self.delegate inputTextViewWillBeginEditing:self.inputTextView];
    }
    
    for (EaseChatToolbarItem *item in self.leftItems) {
        item.button.selected = NO;
    }
    
    for (EaseChatToolbarItem *item in self.rightItems) {
        item.button.selected = NO;
    }
    
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
    
    if ([self.delegate respondsToSelector:@selector(inputTextViewDidBeginEditing:)]) {
        [self.delegate inputTextViewDidBeginEditing:self.inputTextView];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *viewText = textView.text;
    self.at = NO;
    if ([text isEqualToString:@"\n"]) {
        if ([self.delegate respondsToSelector:@selector(didSendText: withAt:)]) {
            NSString *t = textView.text;
            NSMutableArray *array = [NSMutableArray array];
            for (IUser *u in self.atUsers) {
                NSString *a = [NSString stringWithFormat:@"@%@ ", u.name];
                if ([t containsString:a]) {
                    [array addObject:u];
                }
            }
            [self.delegate didSendText:textView.text withAt:array];
            
            self.inputTextView.text = @"";
            [self _willShowInputTextViewToHeight:[self _getTextViewContentH:self.inputTextView]];
        } else if ([self.delegate respondsToSelector:@selector(didSendText:)]) {
            [self.delegate didSendText:textView.text];
            self.inputTextView.text = @"";
            [self _willShowInputTextViewToHeight:[self _getTextViewContentH:self.inputTextView]];
        }
        
        [self.atUsers removeAllObjects];
        return NO;
    }

    if ([text isEqualToString:@"@"]) {
        self.at = YES;
    } else if (text.length == 0 && viewText.length > 0) {
        //Delete Key
        NSString *t = textView.text;
        if ([t compare:@" " options:0 range:range] == NSOrderedSame) {
            NSRange r = [t rangeOfString:@"@" options:NSBackwardsSearch  range:NSMakeRange(0, range.location)];
            NSLog(@"@ range:%zd %zd", r.location, r.length);
            if (r.length == 1) {
                NSRange r1 = NSMakeRange(r.location + 1, range.location - r.location - 1);
                NSString *name = [t substringWithRange:r1];
                for (IUser *u in self.atUsers) {
                    if ([u.name isEqualToString:name]) {
                        NSRange r2 = NSMakeRange(r.location, range.location - r.location + 1);
                        textView.text = [t stringByReplacingCharactersInRange:r2 withString:@""];
                        NSLog(@"delete at name:%@", name);
                        return NO;
                    }
                }
            }
        }
        
        
        //[表情]删除
        if ([viewText characterAtIndex:range.location] == ']') {
            NSUInteger location = range.location;
            NSUInteger length = range.length;
            while (location != 0) {
                location --;
                length ++ ;
                char c = [viewText characterAtIndex:location];
                if (c == '[') {
                    textView.text = [viewText stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
                    return NO;
                } else if (c == ']') {
                    return YES;
                }
            }
        }
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [self _willShowInputTextViewToHeight:[self _getTextViewContentH:textView]];
    
    if (self.at) {
        self.at = NO;
        if ([self.delegate respondsToSelector:@selector(didAt)]) {
            [self.delegate didAt];
        }
    }
}

- (void)addEmojiFace:(HCDChatFace *)face {
    if (face.emoji.length > 0) {
        [self.inputTextView setText:[self.inputTextView.text stringByAppendingString:face.emoji]];
    } else {
        [self.inputTextView setText:[self.inputTextView.text stringByAppendingString:face.faceName]];
    }
    [self textViewDidChange:self.inputTextView];
}

- (void)sendCurrentMessage {
    NSString *viewText = self.inputTextView.text;
    if (viewText.length > 0) {// send Text
        if ([self.delegate respondsToSelector:@selector(didSendText:)]) {
            [self.delegate didSendText:viewText];
            self.inputTextView.text = @"";
            [self textViewDidChange:self.inputTextView];
        }
    }
}

-(NSMutableAttributedString*)backspaceText:(NSMutableAttributedString*) attr length:(NSInteger)length
{
    NSRange range = [self.inputTextView selectedRange];
    if (range.location == 0) {
        return attr;
    }
    [attr deleteCharactersInRange:NSMakeRange(range.location - length, length)];
    return attr;
}

- (void)deleteButtonDown {
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithAttributedString:self.inputTextView.attributedText];
    NSString *chatText = self.inputTextView.text;
    if (chatText.length > 0) {
        NSInteger length = 1;
        NSRange range = [self.inputTextView selectedRange];
        //[表情]删除
        if (range.location > 2 && [chatText characterAtIndex:range.location - 1] == ']') {
            NSInteger pos = -1;
            NSUInteger location = range.location - 2;
            while (location != 0) {
                location --;
                char c = [chatText characterAtIndex:location];
                if (c == '[') {
                    pos = location;
                    break;
                } else if (c == ']') {
                    break;
                }
            }
            if (pos != -1) {
                length = range.location - pos;
            }
        } else if (range.location >= 2) {
            NSString *trailer = [chatText substringWithRange:NSMakeRange(range.location - 2, 2)];
            if ([[HCDChatFaceHeleper sharedFaceHelper] isSurrogatePair:trailer]) {
                length = 2;
            }
        }
        self.inputTextView.attributedText = [self backspaceText:attr length:length];
        [self textViewDidChange:self.inputTextView];
    }
}


#pragma mark - HCDChatBoxFaceViewDelegate
- (void)chatBoxFaceViewDidSelectedFace:(HCDChatFace *)face type:(HCDFaceType)type {
    if (type == HCDFaceTypeEmoji) {
        [self addEmojiFace:face];
    }
}

- (void)chatBoxFaceViewDeleteButtonDown {
    [self deleteButtonDown];
}

- (void)chatBoxFaceViewSendButtonDown {
    [self sendCurrentMessage];
}


#pragma mark - UIKeyboardNotification

- (void)chatKeyboardWillChangeFrame:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect beginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    void(^animations)() = ^{
        [self _willShowKeyboardFromFrame:beginFrame toFrame:endFrame];
    };
    
    [UIView animateWithDuration:duration delay:0.0f options:(curve << 16 | UIViewAnimationOptionBeginFromCurrentState) animations:animations completion:nil];
}

#pragma mark - action

- (void)styleButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    if (button.selected) {
        for (EaseChatToolbarItem *item in self.rightItems) {
            item.button.selected = NO;
        }
        
        for (EaseChatToolbarItem *item in self.leftItems) {
            if (item.button != button) {
                item.button.selected = NO;
            }
        }
        
        //使toolbarView回到最小高度
        [self setInputTextViewHeight:36];
        //录音状态下，不显示底部扩展页面
        [self _willShowBottomView:nil];

        [self.inputTextView resignFirstResponder];
    }
    else{
        //键盘也算一种底部扩展页面
        [self _willShowInputTextViewToHeight:[self _getTextViewContentH:self.inputTextView]];
        [self.inputTextView becomeFirstResponder];
    }
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.recordButton.hidden = !button.selected;
        self.inputTextView.hidden = button.selected;
    } completion:nil];
}

- (void)faceButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    
    EaseChatToolbarItem *faceItem = nil;
    for (EaseChatToolbarItem *item in self.rightItems) {
        if (item.button == button){
            faceItem = item;
            continue;
        }
        
        item.button.selected = NO;
    }
    
    for (EaseChatToolbarItem *item in self.leftItems) {
        item.button.selected = NO;
    }
    
    if (button.selected) {
        //如果处于文字输入状态，使文字输入框失去焦点
        [self.inputTextView resignFirstResponder];
        
        CGFloat height = [self _getTextViewContentH:self.inputTextView];
        [self setInputTextViewHeight:height];
 
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self _willShowBottomView:faceItem.button2View];
            self.recordButton.hidden = button.selected;
            self.inputTextView.hidden = !button.selected;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        [self.inputTextView becomeFirstResponder];
    }
}

- (void)moreButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.selected = !button.selected;
    
    EaseChatToolbarItem *moreItem = nil;
    for (EaseChatToolbarItem *item in self.rightItems) {
        if (item.button == button){
            moreItem = item;
            continue;
        }
        
        item.button.selected = NO;
    }
    
    for (EaseChatToolbarItem *item in self.leftItems) {
        item.button.selected = NO;
    }
    
    if (button.selected) {
        //如果处于文字输入状态，使文字输入框失去焦点
        [self.inputTextView resignFirstResponder];
        
        CGFloat height = [self _getTextViewContentH:self.inputTextView];
        [self setInputTextViewHeight:height];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self _willShowBottomView:moreItem.button2View];
            self.recordButton.hidden = button.selected;
            self.inputTextView.hidden = !button.selected;
        } completion:nil];
    }
    else
    {
        [self.inputTextView becomeFirstResponder];
    }
}

- (void)recordButtonTouchDown
{
    if (_delegate && [_delegate respondsToSelector:@selector(didStartRecordingVoiceAction)]) {
        [_delegate didStartRecordingVoiceAction];
    }
}

- (void)recordButtonTouchUpOutside
{
    if (_delegate && [_delegate respondsToSelector:@selector(didCancelRecordingVoiceAction)])
    {
        [_delegate didCancelRecordingVoiceAction];
    }
}

- (void)recordButtonTouchUpInside
{
    self.recordButton.enabled = NO;
    if ([self.delegate respondsToSelector:@selector(didFinishRecoingVoiceAction)])
    {
        [self.delegate didFinishRecoingVoiceAction];
    }
    self.recordButton.enabled = YES;
}

- (void)recordDragOutside
{
    if ([self.delegate respondsToSelector:@selector(didDragOutsideAction)])
    {
        [self.delegate didDragOutsideAction];
    }
}

- (void)recordDragInside
{
    if ([self.delegate respondsToSelector:@selector(didDragInsideAction)])
    {
        [self.delegate didDragInsideAction];
    }
}

#pragma mark - public

/**
 *  默认高度
 *
 *  @return 默认高度
 */
+ (CGFloat)defaultHeight
{
    return 5 * 2 + 36;
}

/**
 *  停止编辑
 */
- (BOOL)endEditing:(BOOL)force
{
    BOOL result = [super endEditing:force];
    
    for (EaseChatToolbarItem *item in self.rightItems) {
        item.button.selected = NO;
    }
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionBeginFromCurrentState animations:^{
        [self _willShowBottomView:nil];
    } completion:nil];
    
    return result;
}

@end
