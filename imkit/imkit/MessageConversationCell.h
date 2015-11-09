//
//  MessageConversationCell.h
//  Message
//
//  Created by daozhu on 14-7-6.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIImageView+WebCache.h"

@class MessageConversationCell;


@interface MessageConversationCell : UITableViewCell

@property (weak, nonatomic)     IBOutlet UIImageView* headView;
@property (weak, nonatomic)     IBOutlet UILabel* namelabel;
@property (weak, nonatomic)     IBOutlet UILabel* messageContent;
@property (weak, nonatomic)     IBOutlet UILabel* timelabel;

@property (weak,nonatomic) UIView *badgeFatherView;

-(void) showNewMessage:(int)count;
-(void) clearNewMessage;

@end
