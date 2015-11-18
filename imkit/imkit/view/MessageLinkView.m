/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageLinkView.h"

#define KInComingMoveRight  2.0
#define kOuttingMoveRight   3.0

@interface MessageLinkView()
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *contentLabel;
@end
@implementation MessageLinkView

- (void)dealloc {

}



- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imageView = [[UIImageView alloc] init];
        [self.imageView setUserInteractionEnabled:YES];
        [self addSubview:self.imageView];

        self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.downloadIndicatorView];
        
        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self addSubview:self.titleLabel];
        
        self.contentLabel = [[UILabel alloc] init];
        self.contentLabel.textAlignment = NSTextAlignmentCenter;
        self.contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        self.contentLabel.numberOfLines = 0;
        self.contentLabel.font = [UIFont systemFontOfSize:14];
        [self addSubview:self.contentLabel];
    }
    return self;
}

- (void)setMsg:(IMessage*)msg {
    
    [super setMsg:msg];
    
    MessageLinkContent *content = msg.linkContent;
    NSString *url = content.imageURL;
    if (url.length > 0) {
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
    
    self.titleLabel.text = content.title;
    self.contentLabel.text = content.content;
    [self setNeedsLayout];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Drawing
- (CGRect)bubbleFrame {
    CGSize bubbleSize = CGSizeMake(kLinkWidth + kBubblePaddingRight, kLinkHeight + kPaddingTop + kPaddingBottom);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}



-(void)layoutSubviews {
    [super layoutSubviews];
    
    UIImage *image = [self bubbleImage];
    CGRect bubbleFrame = [self bubbleFrame];

    CGFloat imgX = image.leftCapWidth + (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x + kOuttingMoveRight: KInComingMoveRight);

    CGRect imageFrame = CGRectMake(imgX,
                                   kMarginTop + kPaddingTop + 30,
                                   70,
                                   70);
    [self.imageView setFrame:imageFrame];

    
    [self.downloadIndicatorView setFrame:imageFrame];
    
    CGRect rect = CGRectMake(imgX, 8, 180, 30);
    self.titleLabel.frame = rect;
    
    rect = CGRectMake(imgX + 70 + 4, 42, 130, 70);
    self.contentLabel.frame = rect;
    
}
@end
