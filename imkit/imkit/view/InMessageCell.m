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

@interface InMessageCell()

@property (nonatomic) TriangleView *triangleView;
@end

@implementation InMessageCell
-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithType:type reuseIdentifier:reuseIdentifier];
    if (self) {
        
        CGRect frame = CGRectMake(52,
                                  0,
                                  self.contentView.frame.size.width - 24,
                                  NAME_LABEL_HEIGHT);
        
        self.nameLabel = [[UILabel alloc] initWithFrame:frame];
        self.nameLabel.font =  [UIFont systemFontOfSize:14.0f];
        self.nameLabel.textColor = [UIColor grayColor];
        
        [self.contentView addSubview:self.nameLabel];
        
        frame = CGRectMake(2, 0, 40, 40);
        self.headView = [[UIImageView alloc] initWithFrame:frame];
        [self.contentView addSubview:self.headView];
        
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = [UIColor whiteColor];
        CALayer *imageLayer = [self.containerView layer];
        [imageLayer setMasksToBounds:YES];
        [imageLayer setCornerRadius:4];
        [self.contentView addSubview:self.containerView];
        
        self.triangleView = [[TriangleView alloc] init];
        self.triangleView.fillColor = [UIColor whiteColor];
        self.triangleView.backgroundColor = [UIColor clearColor];
        self.triangleView.right = NO;
        [self.contentView addSubview:self.triangleView];

        [self.contentView bringSubviewToFront:self.bubbleView];
        
        [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.contentView.mas_top);
            make.left.equalTo(self.headView.mas_right).with.offset(10);
            make.right.equalTo(self.contentView.mas_right);
            make.height.mas_equalTo(NAME_LABEL_HEIGHT);
        }];
        
        [self.triangleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(TRIANGLE_WIDTH, TRIANGLE_HEIGHT));
            make.top.equalTo(self.containerView.mas_top).with.offset(10);
            make.right.equalTo(self.containerView.mas_left);
        }];
        
        [self.headView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(40, 40));
            make.top.equalTo(self.contentView.mas_top);
            make.left.equalTo(self.contentView.mas_left);
        }];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.headView.mas_right).with.offset(10);
            make.size.mas_equalTo(CGSizeMake(100, 40));
            make.top.equalTo(self.contentView.mas_top);
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
    
    self.bubbleView.msg = message;
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

    }
}

- (CGSize)bubbleSize {
    return [self.bubbleView bubbleSize];
}


- (void)updateConstraints {
    CGSize size = [self bubbleSize];
    
    size.width += 16;
    size.height += 16;
    
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.headView.mas_right).with.offset(10);
        make.size.mas_equalTo(size);
        if (self.showName) {
            make.top.equalTo(self.contentView.mas_top).with.offset(NAME_LABEL_HEIGHT);
        } else {
            make.top.equalTo(self.contentView.mas_top);
        }
    }];
    
    [super updateConstraints];
}


@end

