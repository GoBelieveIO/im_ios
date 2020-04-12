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
#import <Masonry/Masonry.h>

#define kblank 5
#define kMargin 0

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

        self.playBtn = [[UIButton alloc] init];
        [self.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [self.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
        [self addSubview:self.playBtn];

        self.progressView = [[UIProgressView alloc] init];
        [self.progressView setProgressViewStyle:UIProgressViewStyleDefault];
        [self.progressView setBackgroundColor:[UIColor greenColor]];
        self.progressView.progress = 0.0f;
        [self.progressView setTrackTintColor:RGBACOLOR(179, 179, 179, 1.0)];
        [self.progressView setTintColor:RGBACOLOR(43, 11, 207, 1.0)];
        [self addSubview:self.progressView];

        self.timeLengthLabel = [[UILabel alloc] init];
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
        
        [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(kPlayBtnWidth, kPlayBtnHeight));
            make.left.equalTo(self);
            make.centerY.equalTo(self);
        }];
        
        [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.playBtn.mas_right);
            make.centerY.equalTo(self);
            make.right.equalTo(self.mas_right).with.offset(-8);
            make.height.mas_equalTo(kProgressViewHeight);
        }];
        
        [self.timeLengthLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(ktimeLabelWidth, ktimeLabelHeight));
            make.left.equalTo(self);
            make.bottom.equalTo(self);
        }];
        
        [self.unreadImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(8, 8));
            make.left.equalTo(self.mas_right).with.offset(-8);
            make.right.equalTo(self.mas_right);
        }];
        
        [self.uploadIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        [self.downloadIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
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
    
    [self.msg addObserver:self forKeyPath:@"uploading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"downloading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"playing" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    MessageAudioContent *audio = self.msg.audioContent;
    int minute = audio.duration/60;
    int second = audio.duration%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d",minute,second];
    [self.timeLengthLabel setText:str];
    
    if ([self.msg isListened]) {
        self.unreadImageView.hidden = YES;
    } else if (self.msg.isIncomming){
        self.unreadImageView.hidden = NO;
    } else {
        self.unreadImageView.hidden = YES;
    }
    
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
        } else if (self.msg.isIncomming) {
            self.unreadImageView.hidden = NO;
        } else {
            self.unreadImageView.hidden = YES;
        }
    }
}


- (CGSize)bubbleSize {
    CGSize bubbleSize = CGSizeMake(kAudioWidth, kAudioHeight);
    return bubbleSize;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect bubbleFrame = self.bounds;
    
    CGRect rect = self.playBtn.frame;
    rect.size.width = kPlayBtnWidth;
    rect.size.height = kPlayBtnHeight;
    rect.origin.x = (bubbleFrame.origin.x);
    rect.origin.y = bubbleFrame.origin.y + (kAudioHeight - kPlayBtnHeight)/2;
    self.playBtn.frame = rect;
    
    rect = self.progressView.frame;
    rect.origin.x = self.playBtn.frame.origin.x + self.playBtn.frame.size.width;
    rect.origin.y = bubbleFrame.origin.y + (kAudioHeight - kProgressViewHeight )/2;
    rect.size.width = bubbleFrame.size.width - 8 - kPlayBtnWidth;
    self.progressView.frame = rect;
    
    rect = self.timeLengthLabel.frame;
    rect.origin.x = self.progressView.frame.origin.x ;
    rect.origin.y = bubbleFrame.origin.y + kAudioHeight - ktimeLabelHeight;
    self.timeLengthLabel.frame = rect;

    //右上角
    rect.origin.x = CGRectGetMaxX(bubbleFrame) - 8;
    rect.origin.y = bubbleFrame.origin.y;
    rect.size.width = 8;
    rect.size.height = 8;
    self.unreadImageView.frame = rect;
    
    self.uploadIndicatorView.frame = bubbleFrame;
    self.downloadIndicatorView.frame = bubbleFrame;
    

}
@end
