//
//  MessageConversationCell.m
//  Message
//
//  Created by daozhu on 14-7-6.
//  Copyright (c) 2014年 daozhu. All rights reserved.
//

#import "MessageConversationCell.h"
#import <gobelieve/IMessage.h>

#define kCatchWidth 74.0f


@interface MessageConversationCell () 

@end


@implementation MessageConversationCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    CALayer *imageLayer = [self.headView layer];   //获取ImageView的层
    [imageLayer setMasksToBounds:YES];
    [imageLayer setCornerRadius:self.headView.frame.size.width/2];
    
}

#pragma mark - Private Methods

#pragma mark - Overridden Methods

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

-(void) showNewMessage:(int)count{
//    JSBadgeView *badgeView = [[JSBadgeView alloc] initWithParentView:self.messageContent alignment:JSBadgeViewAlignmentCenterRight];
//    [badgeView setBadgeTextFont:[UIFont systemFontOfSize:14.0f]];
//    [self.messageContent bringSubviewToFront:badgeView];
//    if (count > 99) {
//       badgeView.badgeText = @"99+";
//    }else{
//        badgeView.badgeText = [NSString stringWithFormat:@"%d",count];
//    }
}

-(void) clearNewMessage{
//    for (UIView *vi in [self.messageContent subviews]) {
//        if ([vi isKindOfClass:[JSBadgeView class]]) {
//            [vi removeFromSuperview];
//        }
//    }
}

- (void)dealloc {
    [self.conversation removeObserver:self forKeyPath:@"name"];
    [self.conversation removeObserver:self forKeyPath:@"detail"];
    [self.conversation removeObserver:self forKeyPath:@"newMsgCount"];
    [self.conversation removeObserver:self forKeyPath:@"timestamp"];
    [self.conversation removeObserver:self forKeyPath:@"avatarURL"];
}


+ (NSString *)getConversationTimeString:(NSDate *)date{
    NSMutableString *outStr;
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [gregorian components:NSUIntegerMax fromDate:date];
    NSDateComponents *todayComponents = [gregorian components:NSIntegerMax fromDate:[NSDate date]];
    
    if (components.year == todayComponents.year &&
        components.day == todayComponents.day &&
        components.month == todayComponents.month) {
        NSString *format = @"HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        NSString *timeStr = [formatter stringFromDate:date];
        
        if (components.hour > 11) {
            outStr = [NSMutableString stringWithFormat:@"%@ %@",@"下午",timeStr];
        } else {
            outStr = [NSMutableString stringWithFormat:@"%@ %@",@"上午",timeStr];
        }
        return outStr;
    } else {
        NSString *format = @"MM-dd HH:mm";
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
        [formatter setDateFormat:format];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        
        return [formatter stringFromDate:date];
    }
}


- (void)setConversation:(Conversation *)conversation {
    [self.conversation removeObserver:self forKeyPath:@"name"];
    [self.conversation removeObserver:self forKeyPath:@"detail"];
    [self.conversation removeObserver:self forKeyPath:@"newMsgCount"];
    [self.conversation removeObserver:self forKeyPath:@"timestamp"];
    [self.conversation removeObserver:self forKeyPath:@"avatarURL"];
    
    _conversation = conversation;
    
    
    Conversation *conv = self.conversation;
    if(conv.type == CONVERSATION_PEER){
        [self.headView sd_setImageWithURL: [NSURL URLWithString:conv.avatarURL] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    } else if (conv.type == CONVERSATION_GROUP){
        [self.headView sd_setImageWithURL:[NSURL URLWithString:conv.avatarURL] placeholderImage:[UIImage imageNamed:@"GroupChat"]];
    } else if (self.conversation.type == CONVERSATION_SYSTEM) {
        //todo
    } else if (self.conversation.type == CONVERSATION_CUSTOMER_SERVICE) {
        [self.headView sd_setImageWithURL: [NSURL URLWithString:conv.avatarURL] placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
    }
    
    self.messageContent.text = self.conversation.detail;
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: conv.timestamp];
    NSString *str = [[self class] getConversationTimeString:date ];
    self.timelabel.text = str;
    self.namelabel.text = conv.name;
    
    if (conv.newMsgCount > 0) {
        [self showNewMessage:conv.newMsgCount];
    } else {
        [self clearNewMessage];
    }

    
    [self.conversation addObserver:self
                        forKeyPath:@"name"
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                           context:NULL];
    
    [self.conversation addObserver:self
                        forKeyPath:@"detail"
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                           context:NULL];
    [self.conversation addObserver:self
                        forKeyPath:@"newMsgCount"
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                           context:NULL];
    [self.conversation addObserver:self
                        forKeyPath:@"timestamp"
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                           context:NULL];
    [self.conversation addObserver:self
                        forKeyPath:@"avatarURL"
                           options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                           context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"name"]) {
        self.namelabel.text = self.conversation.name;
    } else if ([keyPath isEqualToString:@"detail"]) {
        self.messageContent.text = self.conversation.detail;
    } else if ([keyPath isEqualToString:@"newMsgCount"]) {
        if (self.conversation.newMsgCount > 0) {
            [self showNewMessage:self.conversation.newMsgCount];
        } else {
            [self clearNewMessage];
        }
    } else if ([keyPath isEqualToString:@"timestamp"]) {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970: self.conversation.timestamp];
        NSString *str = [[self class] getConversationTimeString:date ];
        self.timelabel.text = str;
    } else if ([keyPath isEqualToString:@"avatarURL"]) {
        if(self.conversation.type == CONVERSATION_PEER){
            [self.headView sd_setImageWithURL: [NSURL URLWithString:self.conversation.avatarURL]
                             placeholderImage:[UIImage imageNamed:@"PersonalChat"]];
        } else if (self.conversation.type == CONVERSATION_GROUP){
            [self.headView sd_setImageWithURL:[NSURL URLWithString:self.conversation.avatarURL]
                             placeholderImage:[UIImage imageNamed:@"GroupChat"]];
        } else if (self.conversation.type == CONVERSATION_SYSTEM) {
            //todo
        }

    }
}

@end
