/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageImageView.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>

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
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
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
        
        
        [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
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

- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
}

- (void)setMsg:(IMessage*)msg {
    [self.msg removeObserver:self forKeyPath:@"uploading"];
    [self.msg removeObserver:self forKeyPath:@"downloading"];
    [super setMsg:msg];
    [self.msg addObserver:self forKeyPath:@"uploading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self.msg addObserver:self forKeyPath:@"downloading" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    MessageImageContent *content = msg.imageContent;
    NSString *url = content.littleImageURL;
    if (msg.secret) {
        if (msg.downloading) {
            [self.downloadIndicatorView startAnimating];
        } else {
            [self.downloadIndicatorView stopAnimating];
        }
        
        if(![[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] &&
           ![[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
            UIImage *placehodler = [UIImage imageNamed:@"imageDownloadFail"];
            [self.imageView sd_setImageWithURL:nil placeholderImage:placehodler
                                     completed:nil];
        } else {
            UIImage *placehodler = [UIImage imageNamed:@"imageDownloadFail"];
            [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url] placeholderImage:placehodler
                                     completed:nil];
        }
    } else {
        if(![[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] &&
           ![[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
            [self.downloadIndicatorView startAnimating];
        } else {
            [self.downloadIndicatorView stopAnimating];
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
    
    [self setNeedsUpdateConstraints];
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
    } else if ([keyPath isEqualToString:@"downloading"]) {
        if (self.msg.downloading) {
            [self.downloadIndicatorView startAnimating];
        } else {
            [self.downloadIndicatorView stopAnimating];
            
            MessageImageContent *content = self.msg.imageContent;
            NSString *url = content.littleImageURL;
            if (self.msg.secret) {
                if([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] ||
                   [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
                    UIImage *placehodler = [UIImage imageNamed:@"imageDownloadFail"];
                    [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url] placeholderImage:placehodler
                                             completed:nil];
                }
            }
        }
    }

}


-(CGSize)bubbleSize {
    int w = self.msg.imageContent.width;
    int h = self.msg.imageContent.height;
    if (w > 0 && h > 0) {
        //必须是整数，否则会出现约束警告
        int height = kImageWidth*(h*1.0/w);
        CGSize size = CGSizeMake(kImageWidth, height);
        return size;
    } else {
        CGSize size = CGSizeMake(kImageWidth, kImageHeight);
        return size;
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
}

- (void)updateConstraints {
    CGSize size = [self bubbleSize];
    [self.imageView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(size);
    }];
    [super updateConstraints];
}

@end
