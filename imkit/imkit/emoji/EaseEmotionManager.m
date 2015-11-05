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

#import "EaseEmotionManager.h"

@implementation EaseEmotionManager

- (id)initWithType:(EMEmotionType)Type
        emotionRow:(NSInteger)emotionRow
        emotionCol:(NSInteger)emotionCol
          emotions:(NSArray*)emotions
{
    self = [super init];
    if (self) {
        _emotionType = Type;
        _emotionRow = emotionRow;
        _emotionCol = emotionCol;
        _emotions = emotions;
    }
    return self;
}

@end
