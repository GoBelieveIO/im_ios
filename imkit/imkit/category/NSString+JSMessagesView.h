/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

@interface NSString (JSMessagesView)

- (NSString *)trimWhitespace;
- (NSUInteger)numberOfLines;
//在所有中文字符后面添加一个空格
- (NSString*)tokenizer;
@end
