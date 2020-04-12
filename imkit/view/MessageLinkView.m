/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageLinkView.h"
#import <SDWebImage/SDWebImage.h>

@interface MessageLinkView()
@property(nonatomic) UILabel *titleLabel;
@property(nonatomic) UILabel *contentLabel;
@end
@implementation MessageLinkView
- (id)initWithFrame:(CGRect)frame {
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
        if(![[SDImageCache sharedImageCache] diskImageDataExistsWithKey:url]){
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

-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}



-(CGSize)bubbleSize {
    CGSize bubbleSize = CGSizeMake(kLinkWidth , kLinkHeight );
    return bubbleSize;
}

-(void)layoutSubviews {
    [super layoutSubviews];

    CGRect bubbleFrame = self.bounds;
    CGFloat X = bubbleFrame.origin.x;
    CGFloat Y = bubbleFrame.origin.y + 34;
    CGRect imageFrame = CGRectMake(X,
                                   Y,
                                   70,
                                   70);
    [self.imageView setFrame:imageFrame];
    
    [self.downloadIndicatorView setFrame:imageFrame];
    
    CGRect rect = CGRectMake(X, 4, 180, 30);
    self.titleLabel.frame = rect;
    
    rect = CGRectMake(X + 70 + 4, 40,
                      bubbleFrame.size.width - 74, 70);
    self.contentLabel.frame = rect;
    
}
@end
