/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "BubbleView.h"
#import "IMessage.h"

#define kImageWidth  140
#define kImageHeight 220

@interface MessageImageView : BubbleView
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIActivityIndicatorView *downloadIndicatorView;
@property (nonatomic) UIActivityIndicatorView *uploadIndicatorView;
@end
