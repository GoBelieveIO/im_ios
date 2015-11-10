/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "BubbleView.h"

#define kLocationWidth  180
#define kLocationHeight 100

#define kMessageLocationViewHeight (kLocationHeight + kMarginTop + kMarginBottom + kPaddingTop + kPaddingBottom)

@interface MessageLocationView : BubbleView {
    
}
@property (nonatomic) UIImageView *imageView;


@end
