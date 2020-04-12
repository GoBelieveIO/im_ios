//
//  InMessageCell.h
//  gobelieve
//
//  Created by houxh on 2017/12/14.
//

#import <UIKit/UIKit.h>
#import "BubbleView.h"
#import "IMessage.h"
#import "MessageViewCell.h"

#define NAME_LABEL_HEIGHT 20

@interface InMessageCell : MessageViewCell
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIImageView *headView;
@property(nonatomic) BOOL showName;
@end
