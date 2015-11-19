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
        
        self.unreadImageView = [[UIImageView alloc] init];
        self.unreadImageView.hidden = YES;
        [self.unreadImageView setImage:[UIImage imageNamed:@"VoiceNodeUnread"]];
        [self addSubview:self.unreadImageView];
        
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
    
    MessageAudioContent *audio = self.msg.audioContent;
    int minute = audio.duration/60;
    int second = audio.duration%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d",minute,second];
    [self.timeLengthLabel setText:str];
    
    if ([self.msg isListened]) {
        self.unreadImageView.hidden = YES;
    } else if (self.type == BubbleMessageTypeIncoming){
        self.unreadImageView.hidden = NO;
    } else {
        self.unreadImageView.hidden = YES;
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
        if ([self.msg isListened]) {
            self.unreadImageView.hidden = YES;
        } else if (self.type == BubbleMessageTypeIncoming){
            self.unreadImageView.hidden = NO;
        } else {
            self.unreadImageView.hidden = YES;
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
    
    CGRect bubbleFrame = [self bubbleFrame];
    
    CGRect rect = self.playBtn.frame;
    rect.size.width = kPlayBtnWidth;
    rect.size.height = kPlayBtnHeight;
    rect.origin.x = (self.type == BubbleMessageTypeOutgoing) ? (bubbleFrame.origin.x + kBubblePaddingTail + 8) : (kBubblePaddingHead + 8);
    self.playBtn.frame = rect;
    
    rect = self.progressView.frame;
    rect.origin.x = self.playBtn.frame.origin.x + self.playBtn.frame.size.width;
    rect.size.width = kAudioCellWidth - kBubblePaddingHead - kBubblePaddingTail - 8 - kPlayBtnWidth - 8  - (self.type == BubbleMessageTypeOutgoing ?  0  : 8);
    self.progressView.frame = rect;
    
    rect = self.timeLengthLabel.frame;
    rect.origin.x = self.progressView.frame.origin.x ;
    self.timeLengthLabel.frame = rect;

    //右上角
    rect.origin.x = CGRectGetMaxX(bubbleFrame) - kBubblePaddingTail - 13;
    rect.origin.y = bubbleFrame.origin.y + kPaddingTop + 2;
    rect.size.width = 11;
    rect.size.height = 11;
    self.unreadImageView.frame = rect;
    
    self.uploadIndicatorView.frame = bubbleFrame;
    self.downloadIndicatorView.frame = bubbleFrame;
    

}
@end
