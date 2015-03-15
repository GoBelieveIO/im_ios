//
//  MessageAudioView.m
//  Message
//
//  Created by 杨朋亮 on 14-9-10.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageAudioView.h"
#import "FileCache.h"
#import "MessageViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Constants.h"

#define kblank 5
#define kMargin 20

#define kAudioCellWidth 210

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

        
    }
    return self;
}

-(void)initializeWithMsg:(IMessage *)msg withType:(BubbleMessageType)type withMsgStateType:(BubbleMessageReceiveStateType)stateType{
    [super setType:type];
    [super setMsgStateType:stateType];
    _msg = msg;
    [self updatePosition];
    
    int minute = self.msg.content.audio.duration/60;
    int second = self.msg.content.audio.duration%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d",minute,second];
    [self.timeLengthLabel setText:str];
   
    if ([self.msg isListened]) {
        [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicBlueIncoming"] forState:UIControlStateNormal];
    }else{
        [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicNewIncoming"] forState:UIControlStateNormal];
    }
    
    if(self.type == BubbleMessageTypeOutgoing){
        [self.microPhoneBtn setHidden:YES];
    }else{
        [self.microPhoneBtn setHidden:NO];
    }
    
}


-(void)updatePosition{
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
    
}

-(void)setPlaying:(BOOL)playing {
    if (playing) {
        [self.playBtn setImage:[UIImage imageNamed:@"PauseOS7"] forState:UIControlStateNormal];
        [self.playBtn setImage:[UIImage imageNamed:@"PausePressed"] forState:UIControlStateSelected];
        self.progressView.progress = 0;
    } else {
        [self.playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [self.playBtn setImage:[UIImage imageNamed:@"PlayPressed"] forState:UIControlStateSelected];
        self.progressView.progress = 0.0f;
    }
}

-(void)setListened{
    
    [self.microPhoneBtn setImage:[UIImage imageNamed:@"MicBlueIncoming"] forState:UIControlStateNormal];
    
}

#pragma mark - Drawing
- (CGRect)bubbleFrame{
    
    CGSize bubbleSize = CGSizeMake(kAudioCellWidth, kAudioViewCellHeight);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height - 4));
    
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    CGRect bubbleFrame = [self bubbleFrame];
	[image drawInRect:bubbleFrame];
    [self drawMsgStateSign: rect];
}

-(void)setDownloading:(BOOL)downloading {
    //todo download的动画
    if (downloading) {
        self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect bubbleFrame = [self bubbleFrame];
        [self.downloadIndicatorView setFrame: bubbleFrame];
        [self.downloadIndicatorView startAnimating];
        [self addSubview: self.downloadIndicatorView];
    }else{
        if (self.downloadIndicatorView&&[self.downloadIndicatorView isAnimating]) {
            [self.downloadIndicatorView stopAnimating];
        }
    }
}

-(void)setUploading:(BOOL)uploading {
    //todo uploading的动画
    if (uploading) {
        self.uploadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect bubbleFrame = [self bubbleFrame];
        [self.uploadIndicatorView setFrame: bubbleFrame];
        [self.uploadIndicatorView startAnimating];
        [self addSubview: self.uploadIndicatorView];
    }else{
        if (self.uploadIndicatorView&&[self.uploadIndicatorView isAnimating]) {
            [self.uploadIndicatorView stopAnimating];
        }
    }
}

@end
