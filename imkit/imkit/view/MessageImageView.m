
//
//  MessageImageView.m
//  Message
//
//  Created by houxh on 14-9-9.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageImageView.h"
//#import "ESImageViewController.h"

#define kImageWidth  100
#define kImageHeight 100

#define KInComingMoveRight  8.0
#define kOuttingMoveRight   3.0

@implementation MessageImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imageView = [[UIImageView alloc] init];
        [self.imageView setUserInteractionEnabled:YES];
        [self addSubview:self.imageView];
    }
    return self;
}

- (void)setData:(id)newData{
    _data = newData;
    if (_data) {
        //在原图URL后面添加"@{width}w_{heigth}h_{1|0}c", 支持128x128, 256x256
        NSString *url = [NSString stringWithFormat:@"%@@128w_128h_0c", _data];
        if(![[SDImageCache sharedImageCache] diskImageExistsWithKey:url]){
            self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            CGRect bubbleFrame = [self bubbleFrame];
            [self.downloadIndicatorView setFrame: bubbleFrame];
            [self.downloadIndicatorView startAnimating];
            [self addSubview: self.downloadIndicatorView];
        }

        [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url] placeholderImage:[UIImage imageNamed:@"GroupChatRound"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (self.downloadIndicatorView&&[self.downloadIndicatorView isAnimating]) {
                [self.downloadIndicatorView stopAnimating];
                [self.downloadIndicatorView removeFromSuperview];
            }
        }];
    }
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
	UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    
    CGRect bubbleFrame = [self bubbleFrame];
	[image drawInRect:bubbleFrame];
    
    [self drawMsgStateSign: frame];
    
    if (self.imageView) {
        
        CGSize imageSize = CGSizeMake(kImageWidth, kImageHeight);
        CGFloat imgX = image.leftCapWidth + (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x + kOuttingMoveRight: KInComingMoveRight);
        
        CGRect imageFrame = CGRectMake(imgX,
                                       kPaddingTop + kMarginTop,
                                       imageSize.width - kPaddingTop - kMarginTop,
                                       imageSize.height - kPaddingBottom + 2.f);
        [self.imageView setFrame:imageFrame];
        
    }
}


#pragma mark - Drawing
- (CGRect)bubbleFrame {
    CGSize bubbleSize = CGSizeMake(kImageWidth + 35, kImageHeight + 15);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}

-(void) setUploading:(BOOL)uploading {
    //uploading的动画
    if (uploading) {
        self.uploadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect bubbleFrame = [self bubbleFrame];
        
        UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
        bubbleFrame.origin.x -= image.leftCapWidth;
        
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