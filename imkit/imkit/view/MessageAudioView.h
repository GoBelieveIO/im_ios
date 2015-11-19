/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "BubbleView.h"
#import <AVFoundation/AVFoundation.h>


#define kAudioViewCellHeight 58 
#define kAudioCellWidth 210

@interface MessageAudioView : BubbleView <AVAudioPlayerDelegate>

@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIImageView *unreadImageView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *timeLengthLabel;
@property (nonatomic, strong) UILabel *createTimeLabel;

@property (nonatomic) UIActivityIndicatorView *downloadIndicatorView;
@property (nonatomic) UIActivityIndicatorView *uploadIndicatorView;


@end
