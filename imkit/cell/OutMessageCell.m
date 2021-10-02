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

#ifdef ENABLE_TAG
#import "TTGTextTagCollectionViewPatch.h"
#endif

@interface OutMessageCell()
@property (nonatomic) UIActivityIndicatorView *sendingIndicatorView;
@property (nonatomic) TriangleView *triangleView;
@end

@implementation OutMessageCell

-(id)initWithType:(int)type showReply:(BOOL)showReply showReaded:(BOOL)showReaded reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithType:type reuseIdentifier:reuseIdentifier];
    if (self) {
        self.showReply = showReply;
        CGRect frame = CGRectMake(2, 0, 40, 40);
        self.headView = [[UIImageView alloc] initWithFrame:frame];
        CALayer *imageLayer = [self.headView layer];
        [imageLayer setMasksToBounds:YES];
        [imageLayer setCornerRadius:4];
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
        imageLayer = [self.containerView layer];
        [imageLayer setMasksToBounds:YES];
        [imageLayer setCornerRadius:4];
        [self.contentView addSubview:self.containerView];
        [self.containerView addSubview:self.bubbleView];
#ifdef ENABLE_TAG
        TTGTextTagCollectionView *tagCollectionView = [[TTGTextTagCollectionViewPatch alloc] init];
        tagCollectionView.enableTagSelection = YES;
        tagCollectionView.manualCalculateHeight = YES;
        TTGTextTagConfig *config = tagCollectionView.defaultConfig;
        config.selectedTextColor = config.textColor;
        config.selectedBorderColor = config.borderColor;
        config.selectedBorderWidth = config.borderWidth;
        config.selectedCornerRadius = config.cornerRadius;
        config.selectedBackgroundColor = config.backgroundColor;
        config.selectedGradientBackgroundEndColor = config.gradientBackgroundEndColor;
        config.selectedGradientBackgroundStartColor = config.gradientBackgroundStartColor;
        [self.containerView addSubview:tagCollectionView];
        self.tagsView = tagCollectionView;
#else
        UIView *tagsView = [[UIView alloc] init];
        [self.containerView addSubview:tagsView];
        self.tagsView = tagsView;
#endif
        
        self.triangleView = [[TriangleView alloc] init];
        self.triangleView.fillColor = RGBCOLOR(165, 227, 105);
        self.triangleView.backgroundColor = [UIColor clearColor];
        self.triangleView.right = YES;
        [self.contentView addSubview:self.triangleView];
        

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.titleLabel.textAlignment = NSTextAlignmentRight;
        [button.titleLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [button setTitleColor:RGBCOLOR(77, 152, 246) forState:UIControlStateNormal];
        [self.contentView addSubview:button];
        self.readedButton = button;
        self.readedButton.hidden = !showReaded;
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"topic"]];
        [self.contentView addSubview:imageView];
        self.topicView = imageView;
        self.topicView.hidden = !self.showReply;
        
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [button setTitleColor:RGBCOLOR(77, 152, 246) forState:UIControlStateNormal];
        [self.contentView addSubview:button];
        self.replyButton = button;
        self.replyButton.hidden = !self.showReply;
 
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
            make.top.equalTo(self.contentView.mas_top).offset(4);
            make.right.equalTo(self.contentView.mas_right).offset(-8);
        }];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_greaterThanOrEqualTo(10);
            make.top.equalTo(self.headView.mas_top);
            make.right.equalTo(self.headView.mas_left).with.offset(-10);
        }];
        
        [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_top).with.offset(8);
            make.left.equalTo(self.containerView.mas_left).offset(8);
            make.right.equalTo(self.containerView.mas_right).offset(-8);
        }];

        [self.tagsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.bubbleView.mas_bottom).offset(4);
            make.left.equalTo(self.containerView.mas_left).offset(8);
            make.right.equalTo(self.containerView).offset(-8);
            make.bottom.equalTo(self.containerView.mas_bottom).offset(-8);
        }];

        [self.readedButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_bottom).with.offset(2);
            make.right.equalTo(self.containerView.mas_right);
            make.height.mas_equalTo(20);
        }];

        [self.topicView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_bottom).with.offset(2);
            make.left.equalTo(self.containerView.mas_left);
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-4).priorityLow();
        }];

        [self.replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.topicView.mas_top);
            make.bottom.equalTo(self.topicView.mas_bottom);
            make.left.equalTo(self.topicView.mas_right);
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

    [self.replyButton setTitle:[NSString stringWithFormat:@"%d条回复", self.msg.referenceCount] forState:UIControlStateNormal];
    if (self.showReply) {
        self.replyButton.hidden = (self.msg.referenceCount == 0);
        if (self.msg.referenceCount > 0 || self.msg.reference.length > 0)  {
            self.topicView.hidden = NO;
        } else {
            self.topicView.hidden = YES;
        }
    }

#ifdef ENABLE_TAG
    self.tagsView.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width*0.75;
    self.tagsView.frame = CGRectZero;
    [self.tagsView removeAllTags];
    if (self.msg.tags.count > 0) {
        [self.tagsView addTags:self.msg.tags];
    }
#endif
    
    [self updateReadedLabelText];
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    int minWidth = 0;
    if (self.msg.referenceCount > 0) {
        minWidth = 156;
    } else if (self.msg.reference.length > 0) {
        minWidth = 128;
    }
    
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_greaterThanOrEqualTo(minWidth);
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
        
        [self updateReadedLabelText];
    } else if ([keyPath isEqualToString:@"readerCount"]) {
        [self updateReadedLabelText];
    } else if ([keyPath isEqualToString:@"referenceCount"]) {
        [self.replyButton setTitle:[NSString stringWithFormat:@"%d条回复", self.msg.referenceCount] forState:UIControlStateNormal];
        if (self.showReply) {
            self.replyButton.hidden = (self.msg.referenceCount == 0);
            if (self.msg.referenceCount > 0 || self.msg.reference.length > 0)  {
                self.topicView.hidden = NO;
            } else {
                self.topicView.hidden = YES;
            }
        }
        
        [self setNeedsUpdateConstraints];
    }
}

- (void)updateReadedLabelText {
    NSString *title = @"";
    if (self.msg.receiverCount > 0) {
        //群组消息
        if (self.msg.readerCount < self.msg.receiverCount) {
            title = [NSString stringWithFormat:@"%d人未读", self.msg.receiverCount - self.msg.readerCount];
        } else {
            title = @"已读";
        }
    } else {
        if (self.msg.isReaded) {
            title = @"已读";
        } else {
            title = @"未读";
        }
    }
    [self.readedButton setTitle:title forState:UIControlStateNormal];
}



@end

