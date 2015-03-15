//
//  NSString+JSMessagesView.m
//
//  Created by Jesse Squires on 2/14/13.
//  Copyright (c) 2013 Hexed Bits. All rights reserved.
//
//  http://www.hexedbits.com
//

#import "NSString+JSMessagesView.h"

@implementation NSString (JSMessagesView)

- (NSString *)trimWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSUInteger)numberOfLines
{
    return [self componentsSeparatedByString:@"\n"].count + 1;
}

@end