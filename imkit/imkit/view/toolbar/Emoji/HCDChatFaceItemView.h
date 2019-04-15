//
//  HCDChatFaceItemView.h
//  WeChatInputBar
//
//  Created by hcd on 2018/11/5.
//  Copyright © 2018 hcd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class HCDChatFace, HCDChatFaceGroup;
@interface HCDChatFaceItemView : UIView
@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign) UIControlEvents controlEvents;

- (void)showFaceGroup:(HCDChatFaceGroup *)group formIndex:(int)fromIndex count:(int)count;
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents;

@end

NS_ASSUME_NONNULL_END
