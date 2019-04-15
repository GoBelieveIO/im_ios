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

- (void)chatBoxFaceMenuViewAddButtonDown;
- (void)chatBoxFaceMenuViewSendButtonDown;

- (void)chatBoxFaceMenuView:(HCDChatFaceMenuView *)chatBoxFaceMenuView didSelectedFaceMenuIndex:(NSInteger)index;
@end

@interface HCDChatFaceMenuView : UIView

@property (nonatomic, assign) id<HCDChatBoxFaceMenuViewDelegate>delegate;
@property (nonatomic, strong) NSMutableArray *faceGroupArray;
@end

NS_ASSUME_NONNULL_END
