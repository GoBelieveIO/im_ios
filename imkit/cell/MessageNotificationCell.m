/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MessageNotificationCell.h"
#import <Masonry/Masonry.h>

@interface MessageNotificationCell()

@end

@implementation MessageNotificationCell

-(id)initWithType:(int)type reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithType:type reuseIdentifier:reuseIdentifier];
    if (self) {
        self.containerView = [[UIView alloc] init];
        self.containerView.backgroundColor = RGBCOLOR(207, 207, 207);
        CALayer *imageLayer = [self.containerView layer];
        [imageLayer setMasksToBounds:YES];
        [imageLayer setCornerRadius:4];
        [self.contentView addSubview:self.containerView];
        
        [self.contentView bringSubviewToFront:self.bubbleView];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.centerY.equalTo(self.contentView.mas_centerY);
            make.size.mas_equalTo(CGSizeMake(100, 30));
        }];
        
        [self.bubbleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.containerView.mas_top).with.offset(4);
            make.bottom.equalTo(self.containerView.mas_bottom).with.offset(-4);
            make.left.equalTo(self.containerView.mas_left).offset(8);
            make.right.equalTo(self.containerView.mas_right).offset(-8);
        }];
        
    }
    return self;
}


- (void)setMsg:(IMessage*)message {
    [super setMsg:message];
    self.bubbleView.msg = message;
    [self setNeedsUpdateConstraints];
}

- (void)updateConstraints {
    CGSize size = [self.bubbleView bubbleSize];
    
    size.width += 16;
    size.height += 8;
    
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView.mas_centerX);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.size.mas_equalTo(size);
    }];
    
    [super updateConstraints];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}

@end
