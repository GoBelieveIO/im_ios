/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageImageView.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface MessageImageView()
@property(nonatomic) UIView *maskView;
@end

@implementation MessageImageView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.imageView = [[UIImageView alloc] init];
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

- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
}

- (void)setMsg:(IMessage*)msg {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    [super setMsg:msg];
    [self.msg addObserver:self forKeyPath:@"uploading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    
    MessageImageContent *content = msg.imageContent;
    NSString *littleURL = content.littleImageURL;
    if (littleURL.length > 0) {
        NSString *url = littleURL;
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


-(CGSize)bubbleSize {
    int w = self.msg.imageContent.width;
    int h = self.msg.imageContent.height;
    if (w > 0 && h > 0) {
        CGSize size = CGSizeMake(kImageWidth, kImageWidth*(h*1.0/w));
        return size;
    } else {
        CGSize size = CGSizeMake(kImageWidth, kImageHeight);
        return size;
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    NSLog(@"w:%f h:%f", self.bounds.size.width, self.bounds.size.height);

    CGRect imageFrame = self.bounds;
    [self.imageView setFrame:imageFrame];
    self.maskView.frame = imageFrame;
    
    [self.downloadIndicatorView setFrame:imageFrame];
    [self.uploadIndicatorView setFrame:imageFrame];
    
}
@end
