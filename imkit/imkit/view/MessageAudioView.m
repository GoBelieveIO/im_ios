/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageAudioView.h"
#import "FileCache.h"
#import "MessageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"

#define kblank 5
#define kMargin 20

#define kPlayBtnWidth    26
#define kPlayBtnHeight   27
#define kmicroBtnWidth   14
#define kmicroBtnHeight  21
#define ktimeLabelWidth  60
#define ktimeLabelHeight 20

#define kProgressViewHeight 3

@implementation MessageAudioView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        CGRect rect = CGRectMake(kMargin, 0, kPlayBtnWidth, kPlayBtnHeight);
        rect.origin.y = (kAudioViewCellHeight - kPlayBtnHeight  )/2;
        self.playBtn = [[UIButton alloc] initWithFrame: rect];
        [self.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [self.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];

        [self addSubview:self.playBtn];
        rect.origin.x = self.playBtn.frame.origin.x + self.playBtn.frame.size.width;
        rect.origin.y = (kAudioViewCellHeight - kProgressViewHeight )/2;
        rect.size.width = kAudioCellWidth - kMargin - kPlayBtnWidth - 2*kblank;
        rect.size.height = kProgressViewHeight;
        self.progressView = [[UIProgressView alloc] initWithFrame:rect];
        [self.progressView setProgressViewStyle:UIProgressViewStyleDefault];
        [self.progressView setBackgroundColor:[UIColor greenColor]];
        self.progressView.progress = 0.0f;
        [self.progressView setTrackTintColor:RGBACOLOR(179, 179, 179, 1.0)];
        [self.progressView setTintColor:RGBACOLOR(43, 11, 207, 1.0)];
        [self addSubview:self.progressView];
        
        rect.size.height = ktimeLabelHeight;
        rect.size.width = ktimeLabelWidth;
        rect.origin.x = self.progressView.frame.origin.x;
        rect.origin.y = kAudioViewCellHeight - ktimeLabelHeight - kPaddingBottom;
        self.timeLengthLabel = [[UILabel alloc] initWithFrame:rect];
        [self.timeLengthLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [self addSubview:self.timeLengthLabel];
        
        rect.origin.x = kAudioCellWidth - kmicroBtnWidth  - kblank;
        rect.origin.y = kAudioViewCellHeight - kmicroBtnHeight - kPaddingBottom;
        rect.size.width = kmicroBtnWidth;
        rect.size.height = kmicroBtnHeight;
        self.microPhoneBtn = [[UIButton alloc] initWithFrame:rect ];

        [self addSubview:self.microPhoneBtn];
        
        self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.downloadIndicatorView];
        self.uploadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.uploadIndicatorView];
    }
    return self;
}

-(void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    [self.msg removeObserver:self forKeyPath:@"downloading"];
    [self.msg removeObserver:self forKeyPath:@"playing"];
    [self.msg removeObserver:self forKeyPath:@"progress"];
}

-(void)setMsg:(IMessage *)msg {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    [self.msg removeObserver:self forKeyPath:@"downloading"];
    [self.msg removeObserver:self forKeyPath:@"playing"];
    [self.msg removeObserver:self forKeyPath:@"progress"];

    [super setMsg:msg];
    
    MessageAudioContent *audio = (MessageAudioContent*)self.msg.content;
    int minute = audio.duration/60;
    int second = audio.duration%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d",minute,second];
    [self.timeLengthLabel setText:str];
    
    if ([self.msg isListened]) {
        [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicBlueIncoming"] forState:UIControlStateNormal];
    }else{
        [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicNewIncoming"] forState:UIControlStateNormal];
    }
    
    if (self.type == BubbleMessageTypeOutgoing) {
        [self.microPhoneBtn setHidden:YES];
    } else {
        [self.microPhoneBtn setHidden:NO];
    }
    
    [self.msg addObserver:self forKeyPath:@"uploading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"downloading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"playing" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    if (self.msg.uploading) {
        [self.uploadIndicatorView startAnimating];
    } else {
        [self.uploadIndicatorView stopAnimating];
    }
    
    if (self.msg.downloading) {
        [self.downloadIndicatorView startAnimating];
    } else {
        [self.downloadIndicatorView stopAnimating];
    }
    
    if (self.msg.playing) {
        [self.playBtn setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
        [self.playBtn setImage:[UIImage imageNamed:@"PausePressed"] forState:UIControlStateSelected];
        self.progressView.progress = self.msg.progress/100.0;
    } else {
        [self.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [self.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
        self.progressView.progress = 0.0f;
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if([keyPath isEqualToString:@"uploading"]) {
        if (self.msg.uploading) {
            [self.uploadIndicatorView startAnimating];
        } else {
            [self.uploadIndicatorView stopAnimating];
        }
    } else if ([keyPath isEqualToString:@"downloading"]) {
        if (self.msg.downloading) {
            [self.downloadIndicatorView startAnimating];
        } else {
            [self.downloadIndicatorView stopAnimating];
        }
    } else if ([keyPath isEqualToString:@"playing"]) {
        if (self.msg.playing) {
            [self.playBtn setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
            [self.playBtn setImage:[UIImage imageNamed:@"PausePressed"] forState:UIControlStateSelected];
        } else {
            [self.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
            [self.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
        }
    } else if ([keyPath isEqualToString:@"progress"]) {
        self.progressView.progress = self.msg.progress/100.0;
    } else if([keyPath isEqualToString:@"flags"]) {
        if (self.msg.isListened) {
            [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicBlueIncoming"] forState:UIControlStateNormal];
        } else {
            [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicNewIncoming"] forState:UIControlStateNormal];
        }
    }
}


#pragma mark - Drawing
- (CGRect)bubbleFrame{
    
    CGSize bubbleSize = CGSizeMake(kAudioCellWidth, kAudioViewCellHeight);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height - 4));
    
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    CGSize bubbleSize = CGSizeMake(kAudioCellWidth, kAudioViewCellHeight);
    
    CGRect rect = self.playBtn.frame;
    rect.origin.x = image.leftCapWidth + floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width  : 0.0f);
    self.playBtn.frame = rect;
    
    rect = self.progressView.frame;
    rect.origin.x = self.playBtn.frame.origin.x + self.playBtn.frame.size.width;
    rect.size.width = kAudioCellWidth - image.leftCapWidth - kPlayBtnWidth - 2*kblank   - (self.type == BubbleMessageTypeOutgoing ?  2*image.leftCapWidth  : 10);
    self.progressView.frame = rect;
    
    rect = self.timeLengthLabel.frame;
    rect.origin.x = self.progressView.frame.origin.x ;
    self.timeLengthLabel.frame = rect;
    
    rect = self.microPhoneBtn.frame;
    rect.origin.x = kAudioCellWidth - image.leftCapWidth - kmicroBtnWidth + floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width - 20 : 0.0f);
    self.microPhoneBtn.frame = rect;
    
    CGRect bubbleFrame = [self bubbleFrame];
    
    self.uploadIndicatorView.frame = bubbleFrame;
    self.downloadIndicatorView.frame = bubbleFrame;
    

}
@end
