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
        
        [self.containerView addSubview:self.bubbleView];
        
        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.contentView.mas_centerX);
            make.top.equalTo(self.contentView.mas_top).offset(4);
            make.bottom.equalTo(self.contentView.mas_bottom).offset(-4);
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
}

- (void)updateConstraints {
    [super updateConstraints];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}

@end
