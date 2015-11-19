/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageImageView.h"

#define KInComingMoveRight  2.0
#define kOuttingMoveRight   3.0

@interface MessageImageView()
@property(nonatomic) UIView *maskView;
@end
@implementation MessageImageView

- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imageView = [[UIImageView alloc] init];
        [self.imageView setUserInteractionEnabled:YES];
        [self addSubview:self.imageView];
        
        self.maskView = [[UIView alloc] init];
        self.maskView.backgroundColor = [UIColor blackColor];
        self.maskView.alpha = 0.3;
        self.maskView.hidden = YES;
        [self addSubview:self.maskView];
        
        self.uploadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.uploadIndicatorView];
        
        self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.downloadIndicatorView];
    }
    return self;
}

- (void)setMsg:(IMessage*)msg {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    
    [super setMsg:msg];
    
    MessageImageContent *content = msg.imageContent;
    NSString *originURL = content.imageURL;
    if (originURL) {
        //在原图URL后面添加"@{width}w_{heigth}h_{1|0}c", 支持128x128, 256x256
        NSString *url = [NSString stringWithFormat:@"%@@128w_128h_0c", originURL];
        if(![[SDImageCache sharedImageCache] diskImageExistsWithKey:url]){
            [self.downloadIndicatorView startAnimating];
        }

        UIImage *placehodler = [UIImage imageNamed:@"imageDownloadFail"];
        [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url] placeholderImage:placehodler
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (self.downloadIndicatorView&&[self.downloadIndicatorView isAnimating]) {
                [self.downloadIndicatorView stopAnimating];
            }
        }];
    }
    
    [self.msg addObserver:self forKeyPath:@"uploading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    if (self.msg.uploading) {
        self.maskView.hidden = NO;
        [self.uploadIndicatorView startAnimating];
    } else {
        self.maskView.hidden = YES;
        [self.uploadIndicatorView stopAnimating];
    }
    
    [self setNeedsDisplay];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if([keyPath isEqualToString:@"uploading"]) {
        if (self.msg.uploading) {
            self.maskView.hidden = NO;
            [self.uploadIndicatorView startAnimating];
        } else {
            self.maskView.hidden = YES;
            [self.uploadIndicatorView stopAnimating];
        }
    }
}

#pragma mark - Drawing
- (CGRect)bubbleFrame {
    CGSize bubbleSize = CGSizeMake(kImageWidth + kBubblePaddingHead + kBubblePaddingTail + 8, kImageHeight + kPaddingTop + kPaddingBottom + 8);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}



-(void)layoutSubviews {
    [super layoutSubviews];

    CGRect bubbleFrame = [self bubbleFrame];

    CGSize imageSize = CGSizeMake(kImageWidth, kImageHeight);
    CGFloat imgX = (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x + kBubblePaddingTail + 4: kBubblePaddingHead + 4);
    

    CGRect imageFrame = CGRectMake(imgX,
                                   kMarginTop + kPaddingTop + 4,
                                   imageSize.width,
                                   imageSize.height);
    [self.imageView setFrame:imageFrame];
    self.maskView.frame = imageFrame;
    
    [self.downloadIndicatorView setFrame:imageFrame];
    [self.uploadIndicatorView setFrame:imageFrame];
    
}
@end
