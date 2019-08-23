/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */


#import "MessageVideoView.h"
#import <SDWebImage/SDWebImage.h>
#import <Masonry/Masonry.h>

@interface MessageVideoView()
@property(nonatomic) UIView *maskView;
@property(nonatomic) UIImageView *playView;
@property(nonatomic) UILabel *durationLabel;
@end

@implementation MessageVideoView
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
        
        self.playView = [[UIImageView alloc] init];
        self.playView.image = [UIImage imageNamed:@"video_play"];
        [self addSubview:self.playView];
        
        self.durationLabel = [[UILabel alloc] init];
        [self.durationLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [self addSubview:self.durationLabel];
        
        
        self.uploadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.uploadIndicatorView];
        
        self.downloadIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self addSubview:self.downloadIndicatorView];
        
        [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-2);
            make.bottom.equalTo(self);
        }];
        
        [self.playView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(48, 48));
        }];
        
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
    
    MessageVideoContent *content = msg.videoContent;

    int minute = content.duration/60;
    int second = content.duration%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d",minute,second];
    self.durationLabel.text = str;
    
    NSString *url = content.thumbnailURL;
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
        [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url]
                          placeholderImage:placehodler
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
    } else if ([keyPath isEqualToString:@"downloading"]) {
        if (self.msg.downloading) {
            [self.downloadIndicatorView startAnimating];
        } else {
            [self.downloadIndicatorView stopAnimating];
            
            MessageVideoContent *content = self.msg.videoContent;
            NSString *url = content.thumbnailURL;
            if (self.msg.secret) {
                if([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:url] ||
                   [[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
                    UIImage *placehodler = [UIImage imageNamed:@"imageDownloadFail"];
                    [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url]
                                      placeholderImage:placehodler
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
        CGSize size = CGSizeMake(kVideoWidth, kVideoWidth*(h*1.0/w));
        return size;
    } else {
        CGSize size = CGSizeMake(kVideoWidth, kVideoHeight);
        return size;
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
}

@end
