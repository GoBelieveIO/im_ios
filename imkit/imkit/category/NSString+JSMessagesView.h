//
//  NSString+JSMessagesView.h
//
//  Created by Jesse Squires on 2/14/13.
//  Copyright (c) 2013 Hexed Bits. All rights reserved.
//
//  http://www.hexedbits.com
//
//

#import <Foundation/Foundation.h>

@interface NSString (JSMessagesView)

- (NSString *)trimWhitespace;
- (NSUInteger)numberOfLines;

@end