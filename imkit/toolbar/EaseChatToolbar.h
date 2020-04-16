//
//  EaseChatToolbar.h
//  ChatDemo-UI3.0
//
//  Created by dhc on 15/7/1.
//  Copyright (c) 2015年 easemob.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EaseTextView.h"
#import "EaseRecordView.h"
#import "EaseChatBarMoreView.h"
#import "EaseChatToolbarItem.h"

#define kTouchToRecord NSLocalizedString(@"message.toolBar.record.touch", @"hold down to talk")
#define kTouchToFinish NSLocalizedString(@"message.toolBar.record.send", @"loosen to send")


@class IUser;
@protocol EMChatToolbarDelegate;
@interface EaseChatToolbar : UIView

@property (weak, nonatomic) id<EMChatToolbarDelegate> delegate;

@property (nonatomic) UIImage *backgroundImage;

@property (nonatomic, readonly) CGFloat inputViewMaxHeight;

@property (nonatomic, readonly) CGFloat inputViewMinHeight;

@property (nonatomic, readonly) CGFloat horizontalPadding;

@property (nonatomic, readonly) CGFloat verticalPadding;

/**
 *  输入框左侧的按钮列表：EMChatToolbarItem类型
 */
@property (strong, nonatomic) NSArray *inputViewLeftItems;

/**
 *  输入框右侧的按钮列表：EMChatToolbarItem类型
 */
@property (strong, nonatomic) NSArray *inputViewRightItems;

/**
 *  用于输入文本消息的输入框
 */
@property (strong, nonatomic) EaseTextView *inputTextView;

/**
 *  更多的附加页面
 */
@property (strong, nonatomic) UIView *moreView;

/**
 *  表情的附加页面
 */
@property (strong, nonatomic) UIView *faceView;


/**
 *  默认高度
 *
 *  @return 默认高度
 */
+ (CGFloat)defaultHeight;


- (instancetype)initWithFrame:(CGRect)frame;

/**
 *  初始化chat bar
 * @param horizontalPadding  default 8
 * @param verticalPadding    default 5
 * @param inputViewMinHeight default 36
 * @param inputViewMaxHeight default 150
 */
- (instancetype)initWithFrame:(CGRect)frame
            horizontalPadding:(CGFloat)horizontalPadding
              verticalPadding:(CGFloat)verticalPadding
           inputViewMinHeight:(CGFloat)inputViewMinHeight
           inputViewMaxHeight:(CGFloat)inputViewMaxHeight;

//moreview config
- (void)setupSubviews:(NSDictionary*)config;

- (void)setText:(NSString*)text;

- (void)atUser:(IUser*)user;

- (void)chatKeyboardWillChangeFrame:(NSNotification *)notification;

@end

@protocol EMChatToolbarDelegate <NSObject>

@optional

/**
 *  文字输入框开始编辑
 *
 *  @param inputTextView 输入框对象
 */
- (void)inputTextViewDidBeginEditing:(EaseTextView *)inputTextView;

/**
 *  文字输入框将要开始编辑
 *
 *  @param inputTextView 输入框对象
 */
- (void)inputTextViewWillBeginEditing:(EaseTextView *)inputTextView;

/**
 *  发送文字消息，可能包含系统自带表情
 *
 *  @param text 文字消息
 */
- (void)didSendText:(NSString *)text;

/**
 *  发送文字消息，可能包含系统自带表情
 *
 *  @param text 文字消息
 *  @param ext 扩展消息
 */
- (void)didSendText:(NSString *)text withExt:(NSDictionary*)ext;

- (void)didSendText:(NSString *)text withAt:(NSArray*)atUsers;
/**
 *  发送第三方表情，不会添加到文字输入框中
 *
 *  @param faceLocalPath 选中的表情的本地路径
 */
- (void)didSendFace:(NSString *)faceLocalPath;

/**
 *  按下录音按钮开始录音
 */
- (void)didStartRecordingVoiceAction;

/**
 *  手指向上滑动取消录音
 */
- (void)didCancelRecordingVoiceAction;

/**
 *  松开手指完成录音
 */
- (void)didFinishRecoingVoiceAction;

/**
 *  当手指离开按钮的范围内时，主要为了通知外部的HUD
 */
- (void)didDragOutsideAction;

/**
 *  当手指再次进入按钮的范围内时，主要也是为了通知外部的HUD
 */
- (void)didDragInsideAction;

/**
 * 用户输入at
 */
- (void)didAt;


@required
/**
 *  高度变到toHeight
 */
- (void)chatToolbarDidChangeFrameToHeight:(CGFloat)toHeight;

@end
