/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "NSString+JSMessagesView.h"

@implementation NSString (JSMessagesView)

- (NSString *)trimWhitespace {
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSUInteger)numberOfLines {
    return [self componentsSeparatedByString:@"\n"].count + 1;
}

- (NSString*)tokenizer {
    NSInteger len = self.length;
    //2倍长度
    unichar *buf = malloc(2*len*sizeof(unichar));
    int index = 0;
    for (NSInteger i = 0; i < len; i++) {
        unichar codePoint = [self characterAtIndex:i];
        buf[index++] = codePoint;
        NSAssert(index <= 2*len, @"");
        if (codePoint >= 0x4e00 && codePoint <= 0x9fff) {
            buf[index++] = ' ';
             NSAssert(index <= 2*len, @"");
        }
    }
    
    NSString *s = nil;
    if (index > 0) {
        s = [NSString stringWithCharacters:buf length:index];
    } else {
        s = [[NSString alloc] init];
    }
    
    free(buf);
    return s;
}
@end
