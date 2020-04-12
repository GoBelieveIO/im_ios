//
//  HCDChatInputBarDefine.h
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#ifndef HCDChatInputBarDefine_h
#define HCDChatInputBarDefine_h

//是不是全屏手机：iPhoneX、iPhoneXS、iPhoneXSMax、iPhoneXR
static inline BOOL isFullScreen() {
    if (@available(iOS 11.0, *)) {
        UIWindow *w = [UIApplication sharedApplication].windows[0];
        return (UIEdgeInsetsEqualToEdgeInsets(w.safeAreaInsets, UIEdgeInsetsMake(44, 0, 34, 0)));
    }
    return NO;
}

#ifndef COLOR
#define COLORA(R,G,B,A) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:A]
#define COLOR(R,G,B) [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1]
#endif

// 屏幕高度
#ifndef SCREEN_HEIGHT
#define SCREEN_HEIGHT         [[UIScreen mainScreen] bounds].size.height
#endif

// 屏幕宽度
#ifndef SCREEN_WIDTH
#define SCREEN_WIDTH          [[UIScreen mainScreen] bounds].size.width
#endif

#define CHATBOX_HEIGHT              49
#define CHATBOX_BUTTON_WIDTH        37  // 按钮的宽度（语音 +号 表情按钮）
#define HEIGHT_TEXTVIEW             CHATBOX_HEIGHT * 0.74 //文本框高度
#define MAX_TEXTVIEW_HEIGHT         104  //文本框最大高度

#define HEIGHT_BOTTOM_VIEW          36.0f  //表情下面的一条
#define HEIGHT_TABBAR (isFullScreen() ? 88 : 49)
#define HEIGHT_CHATBOXVIEW (isFullScreen() ? (215 + 39) : 215) //表情显示或者more显示的d高度
#define DEFAULT_LINE_GRAY_COLOR  COLORA(188.0, 188.0, 188.0, 0.6f)
#define DEFAULT_SCROLLVIEW_COLOR    COLORA(244.0, 244.0, 246.0, 1.0)
#define DEFAULT_CHATBOX_COLOR   COLORA(255.0, 255.0, 255.0, 1.0)

#endif /* HCDChatInputBarDefine_h */
