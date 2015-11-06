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

#define kImageWidth  200
#define kImageHeight 200
#define  kMessageImagViewHeight (kImageHeight + kMarginTop + kMarginBottom + kPaddingTop + kPaddingBottom)

@interface MessageImageView : BubbleView

@property (nonatomic) UIImageView *imageView;

@property (nonatomic) UIActivityIndicatorView *downloadIndicatorView;
@property (nonatomic) UIActivityIndicatorView *uploadIndicatorView;


@end
