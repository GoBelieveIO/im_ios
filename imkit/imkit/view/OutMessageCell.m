/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */


#import "OutMessageCell.h"
#import "MessageTextView.h"
#import "MessageImageView.h"
#import "MessageAudioView.h"
#import "MessageNotificationView.h"
#import "MessageLocationView.h"
#import "MessageLinkView.h"
#import "MessageVOIPView.h"
#import "MessageUnknownView.h"
#import "TriangleView.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Masonry/Masonry.h>

@interface OutMessageCell()
@property (nonatomic) UIActivityIndicatorView *sendingIndicatorView;
@property (nonatomic) TriangleView *triangleView;
@end

@implementation OutMessageCell

-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithType:type reuseIdentifier:reuseIdentifier];
    if (self) {
        CGRect frame = CGRectMake(2, 0, 40, 40);
        self.headView = [[UIImageView alloc] initWithFrame:frame];
        [self.contentView addSubview:self.headView];
        
        self.msgSendErrorBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [self.msgSendErrorBtn setImage:[UIImage imageNamed:@"MessageSendError"] forState:UIControlStateNormal];
        [self.msgSendErrorBtn setImage:[UIImage imageNamed:@"MessageSendError"]  forState: UIControlStateHighlighted];
        self.msgSendErrorBtn.hidden = YES;
        [self.contentView addSubview:self.msgSendErrorBtn];
        
        self.sendingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:self.sendingIndicatorView];
        
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = RGBCOLOR(165, 227, 105);
        CALayer *imageLayer = [self.containerView layer];
        [imageLayer setMasksToBounds:YES];
        [imageLayer setCornerRadius:4];
        [self.contentView addSubview:self.containerView];
        
        
        self.triangleView = [[TriangleView alloc] init];
        self.triangleView.fillColor = RGBCOLOR(165, 227, 105);
        self.triangleView.backgroundColor = [UIColor clearColor];
        self.triangleView.right = YES;
        [self.contentView addSubview:self.triangleView];
        
        if (self.bubbleView) {
            [self.contentView bringSubviewToFront:self.bubbleView];
        }
        
        [self.triangleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(TRIANGLE_WIDTH, TRIANGLE_HEIGHT));
            make.top.equalTo(self.containerView.mas_top).with.offset(10);
            make.left.equalTo(self.containerView.mas_right);
        }];
        
        [self.msgSendErrorBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.bottom.equalTo(self.containerView.mas_bottom);
            make.right.equalTo(self.containerView.mas_left);
        }];
        
        [self.sendingIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.bottom.equalTo(self.containerView.mas_bottom);
            make.right.equalTo(self.containerView.mas_left);
        }];
        
        [self.headView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(40, 40));
            make.top.equalTo(self.contentView.mas_top);
            make.right.equalTo(self.contentView.mas_right);
        }];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.headView.mas_left).with.offset(-10);
            make.size.mas_equalTo(CGSizeMake(100, 40));
        }];
        
        [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_top).with.offset(8);
            make.bottom.equalTo(self.containerView.mas_bottom).with.offset(-8);
            make.left.equalTo(self.containerView.mas_left).offset(8);
            make.right.equalTo(self.containerView.mas_right).offset(-8);
        }];
    }
    return self;
}

- (void)setSelectedToShowCopyMenu:(BOOL)isSelected{
    [super setSelectedToShowCopyMenu:isSelected];
    if (self.selectedToShowCopyMenu) {
        self.containerView.backgroundColor = RGBCOLOR(148, 204, 94);
        self.triangleView.fillColor = RGBCOLOR(148, 204, 94);
    } else {
        self.containerView.backgroundColor = RGBCOLOR(165, 227, 105);
        self.triangleView.fillColor = RGBCOLOR(165, 227, 105);
    }
}

- (void)setMsg:(IMessage*)message {
    [super setMsg:message];

    self.bubbleView.msg = message;
    
    UIImage *placehodler = [UIImage imageNamed:@"PersonalChat"];
    NSURL *url = [NSURL URLWithString:self.msg.senderInfo.avatarURL];
    [self.headView sd_setImageWithURL: url placeholderImage:placehodler
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                
                            }];

    if (self.msg.isFailure) {
        self.msgSendErrorBtn.hidden = NO;
        [self.sendingIndicatorView stopAnimating];
    } else if (self.msg.isACK) {
        self.msgSendErrorBtn.hidden = YES;
        [self.sendingIndicatorView stopAnimating];
    } else if (self.msg.uploading) {
        self.msgSendErrorBtn.hidden = YES;
        [self.sendingIndicatorView stopAnimating];
    } else {
        self.msgSendErrorBtn.hidden = YES;
        [self.sendingIndicatorView startAnimating];
    }

    [self setNeedsUpdateConstraints];

}

- (void)updateConstraints {
    CGSize size = [self bubbleSize];

    size.width += 16;
    size.height += 16;
    
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.headView.mas_left).with.offset(-10);
        make.size.mas_equalTo(size);
    }];
    
    [super updateConstraints];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"senderInfo"]) {
        UIImage *placehodler = [UIImage imageNamed:@"PersonalChat"];
        NSURL *url = [NSURL URLWithString:self.msg.senderInfo.avatarURL];
        [self.headView sd_setImageWithURL: url placeholderImage:placehodler
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                    
                                }];
    } else if([keyPath isEqualToString:@"flags"] || [keyPath isEqualToString:@"uploading"]) {
        if (self.msg.isFailure) {
            self.msgSendErrorBtn.hidden = NO;
            [self.sendingIndicatorView stopAnimating];
        } else if (self.msg.isACK) {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView stopAnimating];
        } else if (self.msg.uploading) {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView stopAnimating];
        } else {
            self.msgSendErrorBtn.hidden = YES;
            [self.sendingIndicatorView startAnimating];
        }
    }
}

- (CGSize)bubbleSize {
    return [self.bubbleView bubbleSize];
}
@end

