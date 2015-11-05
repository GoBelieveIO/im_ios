//
//  Emoji.m
//  Emoji
//
//  Created by Aliksandr Andrashuk on 26.10.12.
//  Copyright (c) 2012 Aliksandr Andrashuk. All rights reserved.
//

#import "EaseEmoji.h"
#import "EaseEmojiEmoticons.h"


@implementation EaseEmoji

+ (NSString *)emojiWithCode:(int)code
{
    int sym = EMOJI_CODE_TO_SYMBOL(code);
    return [[NSString alloc] initWithBytes:&sym length:sizeof(sym) encoding:NSUTF8StringEncoding];
}

+ (NSArray *)allEmoji
{
    NSMutableArray *array = [NSMutableArray new];
    [array addObjectsFromArray:[EaseEmojiEmoticons allEmoticons]];
    return array;
}

@end
