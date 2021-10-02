/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import "MessageViewCell.h"

#define READED_LABEL_HEIGHT 20

#ifdef ENABLE_TAG
@class TTGTextTagCollectionView;
#endif

@interface OutMessageCell : MessageViewCell
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UIImageView *headView;
@property (nonatomic) UIButton *msgSendErrorBtn;
@property (nonatomic, weak) UIButton *readedButton;//已读/未读
#ifdef ENABLE_TAG
@property (nonatomic, weak) TTGTextTagCollectionView *tagsView;
#else
@property (nonatomic, weak) UIView *tagsView;
#endif

-(id)initWithType:(int)type showReply:(BOOL)showReply showReaded:(BOOL)showReaded reuseIdentifier:(NSString *)reuseIdentifier;
@end
