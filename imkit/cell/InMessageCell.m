/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "InMessageCell.h"
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

#define NAME_LABEL_HEIGHT 20

@interface InMessageCell()
@property (nonatomic) TriangleView *triangleView;

@end

@implementation InMessageCell
-(id)initWithType:(int)type showName:(BOOL)showName showReply:(BOOL)showReply reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithType:type reuseIdentifier:reuseIdentifier];
    if (self) {
        self.showReply = showReply;
        self.showName = showName;
        self.nameLabel = [[UILabel alloc] init];
        self.nameLabel.font =  [UIFont systemFontOfSize:14.0f];
        self.nameLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:self.nameLabel];

        self.headView = [[UIImageView alloc] init];
        CALayer *imageLayer = [self.headView layer];
        [imageLayer setMasksToBounds:YES];
        [imageLayer setCornerRadius:4];
        [self.contentView addSubview:self.headView];
        
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = [UIColor whiteColor];
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
        self.triangleView.fillColor = [UIColor whiteColor];
        self.triangleView.backgroundColor = [UIColor clearColor];
        self.triangleView.right = NO;
        [self.contentView addSubview:self.triangleView];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"topic"]];
        [self.contentView addSubview:imageView];
        self.topicView = imageView;
        self.topicView.hidden = !self.showReply;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button.titleLabel setFont:[UIFont systemFontOfSize:12.0f]];
        [button setTitleColor:RGBCOLOR(77, 152, 246) forState:UIControlStateNormal];
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 0.01, 0, 0.01);
        
        [self.contentView addSubview:button];
        self.replyButton = button;
        self.replyButton.hidden = !self.showReply;
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top);
            make.left.equalTo(self.headView.mas_right).with.offset(10);
            make.right.equalTo(self.contentView.mas_right);
            if (showName) {
                make.height.mas_equalTo(NAME_LABEL_HEIGHT);
            } else {
                make.height.mas_equalTo(0);
            }
        }];
        
        [self.triangleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(TRIANGLE_WIDTH, TRIANGLE_HEIGHT));
            make.top.equalTo(self.containerView.mas_top).with.offset(10);
            make.right.equalTo(self.containerView.mas_left);
        }];
        
        [self.headView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(40, 40));
            make.left.mas_equalTo(8);
            make.top.equalTo(self.contentView.mas_top);
        }];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_greaterThanOrEqualTo(10);
            if (showName) {
                make.top.equalTo(self.nameLabel.mas_bottom).offset(4);
            } else {
                make.top.equalTo(self.nameLabel.mas_bottom);
            }
            make.left.equalTo(self.headView.mas_right).with.offset(10);

        }];
        
        [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_top).offset(8);
            make.left.equalTo(self.containerView.mas_left).offset(8);
            make.right.equalTo(self.containerView.mas_right).offset(-8);
        }];

        [self.tagsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.bubbleView.mas_bottom).offset(4);
            make.left.equalTo(self.containerView.mas_left).offset(8);
            make.right.equalTo(self.containerView).offset(-8);
            make.bottom.equalTo(self.containerView.mas_bottom).offset(-8);
        }];
        
        [self.topicView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_bottom).with.offset(2);
            make.left.equalTo(self.containerView.mas_left);
            make.size.mas_equalTo(CGSizeMake(20, 20));
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-4);
        }];

        [self.replyButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.topicView.mas_right);
            make.centerY.equalTo(self.topicView.mas_centerY);
        }];
    }
    return self;
}


- (void)setSelectedToShowCopyMenu:(BOOL)isSelected{
    [super setSelectedToShowCopyMenu:isSelected];
    if (self.selectedToShowCopyMenu) {
        self.containerView.backgroundColor = RGBCOLOR(229, 229, 229);
        self.triangleView.fillColor = RGBCOLOR(229, 229, 229);
    } else {
        self.containerView.backgroundColor = [UIColor whiteColor];
        self.triangleView.fillColor = [UIColor whiteColor];
    }
}


- (void)setMsg:(IMessage*)message {
    [super setMsg:message];
    
    NSString *name = self.msg.senderInfo.name;
    if (name.length == 0) {
        name = self.msg.senderInfo.identifier;
    }
    
    self.nameLabel.text = name;
    self.nameLabel.textAlignment = NSTextAlignmentLeft;
    self.nameLabel.hidden = !self.showName;
    
    UIImage *placehodler = [UIImage imageNamed:@"PersonalChat"];
    NSURL *url = [NSURL URLWithString:self.msg.senderInfo.avatarURL];
    [self.headView sd_setImageWithURL: url placeholderImage:placehodler
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                
                            }];

    [self.replyButton setTitle:[NSString stringWithFormat:@"%d条回复", self.msg.referenceCount] forState:UIControlStateNormal];
    if (self.showReply) {
        self.replyButton.hidden = (self.msg.referenceCount == 0);
        if (self.msg.referenceCount > 0 || self.msg.reference.length > 0)  {
            self.topicView.hidden = NO;
        } else {
            self.topicView.hidden = YES;
        }
    }
    
    self.bubbleView.msg = message;
#ifdef ENABLE_TAG
    self.tagsView.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width*0.75;
    self.tagsView.frame = CGRectZero;
    [self.tagsView removeAllTags];
    if (self.msg.tags.count > 0) {
        [self.tagsView addTags:self.msg.tags];
    }
#endif
    
    [self setNeedsUpdateConstraints];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"senderInfo"]) {
        if (self.showName) {
            if (self.msg.senderInfo.name.length > 0) {
                self.nameLabel.text = self.msg.senderInfo.name;
            } else {
                self.nameLabel.text = self.msg.senderInfo.identifier;
            }
        }

        UIImage *placehodler = [UIImage imageNamed:@"PersonalChat"];
        NSURL *url = [NSURL URLWithString:self.msg.senderInfo.avatarURL];
        [self.headView sd_setImageWithURL: url placeholderImage:placehodler
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                    
                                }];

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


- (void)updateConstraints {
    int minWidth = 0;
    if (self.msg.referenceCount > 0) {
        minWidth = 128;
    }

    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_greaterThanOrEqualTo(minWidth);
    }];
    [super updateConstraints];
}


@end

