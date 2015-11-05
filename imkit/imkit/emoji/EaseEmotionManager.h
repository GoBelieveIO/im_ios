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

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, EMEmotionType) {
    EMEmotionDefault = 0,
    EMEmotionPng,
    EMEmotionGif
};

@interface EaseEmotionManager : NSObject

@property (nonatomic, copy) NSString *emotionName;
/**
 *  某一类表情的数据源
 */
@property (nonatomic, strong) NSArray *emotions;

@property (nonatomic, assign) NSInteger emotionRow;

@property (nonatomic, assign) NSInteger emotionCol;

@property (nonatomic, assign) EMEmotionType emotionType;

- (id)initWithType:(EMEmotionType)Type
        emotionRow:(NSInteger)emotionRow
        emotionCol:(NSInteger)emotionCol
          emotions:(NSArray*)emotions;

@end
