/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import "MessageViewCell.h"

@interface OutMessageCell : MessageViewCell
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIImageView *headView;
@property (nonatomic, strong) UIButton *msgSendErrorBtn;

@end
