/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "BubbleView.h"

@class KILabel;
@interface MessageTextView : BubbleView
@property(nonatomic, strong) KILabel *label;

+ (UIFont *)font;
+ (CGSize)textSizeForText:(NSString *)txt withFont:(UIFont*)font;

@end
