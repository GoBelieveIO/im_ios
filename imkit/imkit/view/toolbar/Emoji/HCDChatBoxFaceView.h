//
//  HCDChatBoxFaceView.h
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HCDChatFace.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HCDChatBoxFaceViewDelegate <NSObject>
- (void)chatBoxFaceViewDidSelectedFace:(HCDChatFace *)face type:(HCDFaceType)type;
- (void)chatBoxFaceViewDeleteButtonDown;
- (void)chatBoxFaceViewSendButtonDown;
@end

@interface HCDChatBoxFaceView : UIView
@property (nonatomic, assign) id<HCDChatBoxFaceViewDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
