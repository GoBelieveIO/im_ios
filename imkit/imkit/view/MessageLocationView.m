/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageLocationView.h"

#define kImageWidth  100
#define kImageHeight 100

#define KInComingMoveRight  8.0
#define kOuttingMoveRight   3.0


@interface MessageLocationView()
@property (nonatomic) UIActivityIndicatorView *indicatorView;
@end

@implementation MessageLocationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        UIImageView *imageView = [[UIImageView alloc] init];
        [self addSubview:imageView];
        self.imageView = imageView;
        self.imageView.userInteractionEnabled = YES;
        
        
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        [self addSubview:self.indicatorView];
    }
    return self;
}


- (void)setSnapshotURL:(NSString*)url {
    if(![[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] &&
       ![[SDImageCache sharedImageCache] diskImageExistsWithKey:url]){
        [self.indicatorView startAnimating];
        return;
    }
    
    [self.indicatorView stopAnimating];
    [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url]
                      placeholderImage:nil
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                             }];
    
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)frame{
    [super drawRect:frame];
    
    UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    
    CGRect bubbleFrame = [self bubbleFrame];
    [image drawInRect:bubbleFrame];
    
    [self drawMsgStateSign: frame];
    
}


#pragma mark - Drawing
- (CGRect)bubbleFrame {
    CGSize bubbleSize = CGSizeMake(kImageWidth + 35, kImageHeight + 15);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}


-(void)layoutSubviews {
    UIImage *image = (self.selectedToShowCopyMenu) ? [self bubbleImageHighlighted] : [self bubbleImage];
    CGRect bubbleFrame = [self bubbleFrame];
    
    if (self.imageView) {
        
        CGSize imageSize = CGSizeMake(kImageWidth, kImageHeight);
        CGFloat imgX = image.leftCapWidth + (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x + kOuttingMoveRight: KInComingMoveRight);
        
        CGRect imageFrame = CGRectMake(imgX,
                                       kPaddingTop + kMarginTop,
                                       imageSize.width - kPaddingTop - kMarginTop,
                                       imageSize.height - kPaddingBottom + 2.f);
        [self.imageView setFrame:imageFrame];
        
        [self.indicatorView setFrame:imageFrame];
    }
}

@end
