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

#ifdef ENABLE_TAG
@class TTGTextTagCollectionView;
#endif

@interface InMessageCell : MessageViewCell
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UIImageView *headView;
@property(nonatomic) BOOL showName;
#ifdef ENABLE_TAG
@property (nonatomic, weak) TTGTextTagCollectionView *tagsView;
#else
@property (nonatomic, weak) UIView *tagsView;
#endif

-(id)initWithType:(int)type showName:(BOOL)showName showReply:(BOOL)showReply reuseIdentifier:(NSString *)reuseIdentifier;
@end
