/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "BubbleView.h"

#define kImageWidth  240
#define kImageHeight 240
#define  kMessageImagViewHeight (kImageHeight + kMarginTop + kMarginBottom + kPaddingTop + kPaddingBottom)

@interface MessageImageView : BubbleView

@property (weak, nonatomic) UIViewController *dgtController;
@property (nonatomic) UIImageView *imageView;

@property (nonatomic) id data;

-(void) setUploading:(BOOL)uploading;

@end
