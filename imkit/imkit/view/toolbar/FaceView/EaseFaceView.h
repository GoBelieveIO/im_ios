/************************************************************
  *  * EaseMob CONFIDENTIAL 
  * __________________ 
  * Copyright (C) 2013-2014 EaseMob Technologies. All rights reserved. 
  *  
  * NOTICE: All information contained herein is, and remains 
  * the property of EaseMob Technologies.
  * Dissemination of this information or reproduction of this material 
  * is strictly forbidden unless prior written permission is obtained
  * from EaseMob Technologies.
  */

#import <UIKit/UIKit.h>

#import "EaseFacialView.h"

@protocol EMFaceDelegate

@required
- (void)selectedFacialView:(NSString *)str isDelete:(BOOL)isDelete;
- (void)sendFace;
- (void)sendFaceWithEmotion:(NSString *)emotion;

@end

@interface EaseFaceView : UIView <EaseFacialViewDelegate>

@property (nonatomic, assign) id<EMFaceDelegate> delegate;

- (BOOL)stringIsFace:(NSString *)string;

/*!
 @method
 @brief 通过数据源获取表情分组数,
 @discussion
 @param number 分组数
 @param emotionManagers 表情分组列表
 @result
 */
- (void)setEmotionManagers:(NSArray*)emotionManagers;

@end
