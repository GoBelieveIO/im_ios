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

#define BUTTON_PHOTO_TAG 1
#define BUTTON_CAMERA_TAG 2
#define BUTTON_LOCATION_TAG 3
#define BUTTON_CALL_TAG 4

@protocol EaseChatBarMoreViewDelegate;

@interface EaseChatBarMoreView : UIView

@property (nonatomic,assign) id<EaseChatBarMoreViewDelegate> delegate;

@property (nonatomic) UIColor *moreViewBackgroundColor UI_APPEARANCE_SELECTOR;  //moreview背景颜色,default whiteColor

- (instancetype)initWithFrame:(CGRect)frame;

//disable config
- (instancetype)initWithFrame:(CGRect)frame config:(NSDictionary*)config;

/*!
 @method
 @brief 新增一个新的功能按钮
 @param image 按钮图片
 @param highLightedImage 高亮图片
 @param title 按钮标题
 @param tag 按钮索引
 */
- (void)insertItemWithImage:(UIImage*)image
           highlightedImage:(UIImage*)highLightedImage
                      title:(NSString*)title
                        tag:(NSInteger)tag;

/*!
 @method
 @brief 修改功能按钮图片
 @param image 按钮图片
 @param highLightedImage 高亮图片
 @param title 按钮标题
 @param tag 按钮索引
 */
- (void)updateItemWithImage:(UIImage*)image
           highlightedImage:(UIImage*)highLightedImage
                      title:(NSString*)title
                        tag:(NSInteger)tag;


@end


@protocol EaseChatBarMoreViewDelegate <NSObject>

@optional

/*!
 @method
 @brief 默认功能
 @param moreView 功能view
 */
- (void)moreViewTakePicAction:(EaseChatBarMoreView *)moreView;
- (void)moreViewPhotoAction:(EaseChatBarMoreView *)moreView;
- (void)moreViewLocationAction:(EaseChatBarMoreView *)moreView;
- (void)moreViewVideoCallAction:(EaseChatBarMoreView *)moreView;


/*!
 @method
 @brief 发送消息后的回调
 @param moreView 功能view
 @param index    按钮索引
 */
- (void)moreView:(EaseChatBarMoreView *)moreView didItemInMoreViewAtIndex:(NSInteger)index;

@end
