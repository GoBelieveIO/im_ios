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

@protocol EaseFacialViewDelegate

@optional
-(void)selectedFacialView:(NSString*)str;
-(void)deleteSelected:(NSString *)str;
-(void)sendFace;
-(void)sendFace:(NSString *)str;

@end

@class EaseEmotionManager;
@interface EaseFacialView : UIView
{
	NSMutableArray *_faces;
}

@property(nonatomic) id<EaseFacialViewDelegate> delegate;

@property(strong, nonatomic, readonly) NSArray *faces;

-(void)loadFacialView:(EaseEmotionManager*)emotionManager size:(CGSize)size;

//-(void)loadFacialView:(int)page size:(CGSize)size;

@end
