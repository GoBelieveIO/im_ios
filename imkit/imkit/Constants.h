//
//  Constants.h
//  Message
//
//  Created by daozhu on 14-6-20.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#ifndef Message_Constants_h
#define Message_Constants_h

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define SETCOLOR(RED,GREEN,BLUE) [UIColor colorWithRed:RED/255 green:GREEN/255 blue:BLUE/255 alpha:1.0]

//RGB颜色
#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
//RGB颜色和不透明度
#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f \
alpha:(a)]

#define iPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)

//Address Book contact
#define KPHONELABELDICDEFINE		@"KPhoneLabelDicDefine"
#define KPHONENUMBERDICDEFINE	@"KPhoneNumberDicDefine"
#define KPHONENAMEDICDEFINE	@"KPhoneNameDicDefine"

#define KTabBarHeight  49
#define KNavigationBarHeight 44
#define kStatusBarHeight 20
#define kSearchBarHeight 44
#define kTabBarHeight 49
//NSNotificaiton

#define CREATE_NEW_CONVERSATION @"creat_new_conversation"
#define SEND_FIRST_MESSAGE_OK   @"send_first_message_ok"
#define CLEAR_ALL_CONVESATION   @"clear_all_conversation"

#define ON_NEW_MESSAGE_NOTIFY  @"on_new_message_notify"
#define CLEAR_SINGLE_CONV_NEW_MESSAGE_NOTIFY @"clear_single_conv_new_message_notify"
#define CLEAR_TAB_BAR_NEW_MESSAGE_NOTIFY  @"clear_tab_bar_new_message_notify"

#endif
