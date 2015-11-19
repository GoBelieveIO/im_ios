/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageLocationView.h"
#import "Constants.h"

#define kPinImageWidth 32
#define kPinImageHeight 39

#define KInComingMoveRight  2.0
#define kOuttingMoveRight   3.0

#define kAddressHeight  30

@interface MessageLocationView()
@property (nonatomic) UIActivityIndicatorView *indicatorView;
@property (nonatomic) UIImageView *pinImageView;
@property (nonatomic) UIView *addressBackgroundView;
@property (nonatomic) UILabel *addressLabel;
@property (nonatomic) UIActivityIndicatorView *geocodingIndicatorView;
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
        self.imageView.layer.cornerRadius = 6.0f;
        self.imageView.clipsToBounds = YES;
        self.imageView.userInteractionEnabled = YES;
        
        self.pinImageView = [[UIImageView alloc] init];
        UIImage *image = [UIImage imageNamed:@"PinGreen"];
        self.pinImageView.image = image;
        [self addSubview:self.pinImageView];

        self.addressBackgroundView = [[UIView alloc] init];
        self.addressBackgroundView.backgroundColor = RGBACOLOR(0, 0, 0, 0.3);
        [self.imageView addSubview:self.addressBackgroundView];
        
        self.addressLabel = [[UILabel alloc] init];
        self.addressLabel.textColor = [UIColor whiteColor];
        self.addressLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        [self.addressBackgroundView addSubview:self.addressLabel];
        
        self.geocodingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.addressBackgroundView addSubview:self.geocodingIndicatorView];
        
        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        [self addSubview:self.indicatorView];
    }
    return self;
}

-(void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"geocoding"];
    [self.msg removeObserver:self forKeyPath:@"downloading"];   
}

-(void)setMsg:(IMessage *)msg {
    [self.msg removeObserver:self forKeyPath:@"geocoding"];
    [self.msg removeObserver:self forKeyPath:@"downloading"];
    [super setMsg:msg];
    [self.msg addObserver:self forKeyPath:@"geocoding"
                          options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                          context:NULL];
    [self.msg addObserver:self forKeyPath:@"downloading"
                  options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                  context:NULL];

    MessageLocationContent *loc = msg.locationContent;
    
    UIImage *placehodler = [UIImage imageNamed:@"chat_location_preview"];
    if (self.msg.downloading) {
        [self.indicatorView startAnimating];
        self.imageView.image = placehodler;
        self.pinImageView.hidden = YES;
    } else {
        [self.indicatorView stopAnimating];
        self.pinImageView.hidden = NO;

        NSString *url = loc.snapshotURL;
        [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url]
                          placeholderImage:placehodler
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 }];
    }
    
    if (self.msg.geocoding) {
        [self.geocodingIndicatorView startAnimating];
    } else {
        [self.geocodingIndicatorView stopAnimating];
    }

    self.addressLabel.text = loc.address;
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if([keyPath isEqualToString:@"downloading"]) {
        UIImage *placehodler = [UIImage imageNamed:@"chat_location_preview"];
        if (self.msg.downloading) {
            [self.indicatorView startAnimating];
            self.imageView.image = placehodler;
            self.pinImageView.hidden = YES;
        } else {
            [self.indicatorView stopAnimating];
            self.pinImageView.hidden = NO;
            MessageLocationContent *loc = self.msg.locationContent;
            NSString *url = loc.snapshotURL;
            [self.imageView sd_setImageWithURL: [[NSURL alloc] initWithString:url]
                              placeholderImage:placehodler
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                     }];
        }
    } else if([keyPath isEqualToString:@"geocoding"]) {
        if (self.msg.geocoding) {
            [self.geocodingIndicatorView startAnimating];
        } else {
            [self.geocodingIndicatorView stopAnimating];
        }
        MessageLocationContent *loc = self.msg.locationContent;
        self.addressLabel.text = loc.address;
    }
}

#pragma mark - Drawing
- (CGRect)bubbleFrame {
    CGSize bubbleSize = CGSizeMake(kLocationWidth + kBubblePaddingHead + kBubblePaddingTail + 8, kLocationHeight + kPaddingTop + kPaddingBottom + 8);
    return CGRectMake(floorf(self.type == BubbleMessageTypeOutgoing ? self.frame.size.width - bubbleSize.width : 0.0f),
                      floorf(kMarginTop),
                      floorf(bubbleSize.width),
                      floorf(bubbleSize.height));
    
}


-(void)layoutSubviews {
    [super layoutSubviews];

    CGRect bubbleFrame = [self bubbleFrame];
    
    if (self.imageView) {
        
        CGSize imageSize = CGSizeMake(kLocationWidth, kLocationHeight);
        CGFloat imgX = (self.type == BubbleMessageTypeOutgoing ? bubbleFrame.origin.x + kBubblePaddingTail + 4: kBubblePaddingHead + 4);
        
        CGRect imageFrame = CGRectMake(imgX,
                                       kMarginTop + kPaddingTop + 4,
                                       imageSize.width,
                                       imageSize.height);
        [self.imageView setFrame:imageFrame];
        
        CGRect rect = imageFrame;
        rect.origin.x = 0;
        rect.origin.y = rect.size.height - kAddressHeight;
        rect.size.height = kAddressHeight;
        self.addressBackgroundView.frame = rect;
        
        rect.origin.y = 0;
        rect.origin.x = 4;
        rect.size.width -= 8;
        self.addressLabel.frame = rect;
        self.geocodingIndicatorView.frame = rect;
        
        [self.indicatorView setFrame:imageFrame];
        //center
        CGPoint centerPoint = CGPointMake(imageFrame.origin.x + imageFrame.size.width/2, imageFrame.origin.y + imageFrame.size.height/2);
        CGRect pinFrame = CGRectMake(centerPoint.x - 8, centerPoint.y - 36, kPinImageWidth, kPinImageHeight);
        self.pinImageView.frame = pinFrame;
    }
}

@end
