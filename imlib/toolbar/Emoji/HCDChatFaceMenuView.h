//
//  HCDChatFaceMenuView.h
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HCDChatFaceMenuView;
@protocol HCDChatBoxFaceMenuViewDelegate <NSObject>
- (void)chatBoxFaceMenuViewSendButtonDown;
@end

@interface HCDChatFaceMenuView : UIView

@property (nonatomic, assign) id<HCDChatBoxFaceMenuViewDelegate>delegate;

@end

NS_ASSUME_NONNULL_END
