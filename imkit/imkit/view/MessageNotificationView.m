/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MessageNotificationView.h"

@implementation MessageNotificationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.label = [[UILabel alloc] init];
        self.label.textColor = [UIColor whiteColor];
        self.label.textAlignment = NSTextAlignmentCenter;
        [self.label setFont:[UIFont systemFontOfSize:11.5f]];
        [self addSubview:self.label];
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
        MessageNotificationContent *notification = self.msg.notificationContent;
        self.label.text = notification.notificationDesc;
    }
}

- (CGSize)bubbleSize {
    CGFloat width = [UIScreen mainScreen].applicationFrame.size.width * 0.75f;
    CGRect bounds = CGRectMake(0, 0, width, 44);
    
    CGRect r = [self.label textRectForBounds:bounds limitedToNumberOfLines:1];
    return r.size;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect bubbleFrame = self.bounds;
    self.label.frame = bubbleFrame;
    [self.label sizeToFit];
}
@end
