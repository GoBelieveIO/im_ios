/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageNotificationView.h"
#import "Constants.h"

@interface PaddingLabel : UILabel

@end

@implementation PaddingLabel

-(CGSize)intrinsicContentSize{
    CGSize contentSize = [super intrinsicContentSize];
    return CGSizeMake(contentSize.width + 16, contentSize.height + 6);
}

@end

@implementation MessageNotificationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.label = [[PaddingLabel alloc] init];
        self.label.layer.cornerRadius = 6;
        self.label.layer.masksToBounds = YES;
        self.label.backgroundColor = RGBCOLOR(207, 207, 207);
        self.label.textColor = [UIColor whiteColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        self.label.translatesAutoresizingMaskIntoConstraints = NO;
        [self.label setFont:[UIFont systemFontOfSize:11.5f]];
        
        [self addSubview:self.label];
        
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        
        self.alpha = 1.0;
        
     }
    return self;
}

- (void)dealloc {
    [self.msg.notificationContent removeObserver:self forKeyPath:@"notificationDesc"];
}

- (void)setMsg:(IMessage*)msg {
    [self.msg.notificationContent removeObserver:self forKeyPath:@"notificationDesc"];
    [super setMsg:msg];
    MessageNotificationContent *notification = self.msg.notificationContent;
    self.label.text = notification.notificationDesc;
    [self.msg.notificationContent addObserver:self forKeyPath:@"notificationDesc" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if([keyPath isEqualToString:@"notificationDesc"]) {
        MessageGroupNotificationContent *notification = self.msg.notificationContent;
        self.label.text = notification.notificationDesc;
    }
}
@end
