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
        CGRect labelFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        self.label = [[UILabel alloc] initWithFrame:labelFrame];
        [self.label setTextAlignment:NSTextAlignmentCenter];
        [self.label setFont:[UIFont systemFontOfSize:11.5f]];
        [self.label setTextColor:[UIColor grayColor]];
        [self addSubview:self.label];
    }
    return self;
}

- (void)dealloc {
    [self.msg.content removeObserver:self forKeyPath:@"notificationDesc"];
}

- (void)setMsg:(IMessage*)msg {
    [self.msg.content removeObserver:self forKeyPath:@"notificationDesc"];
    [super setMsg:msg];
    self.label.text = self.msg.content.notificationDesc;
    [self.msg.content addObserver:self forKeyPath:@"notificationDesc" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if([keyPath isEqualToString:@"notificationDesc"]) {
        self.label.text = self.msg.content.notificationDesc;
    }
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = [[self class] bubbleSizeForText:self.label.text withFont:self.label.font];
    
    if (self.frame.size.width > size.width) {
        CGFloat x = (self.frame.size.width - size.width)/2;
        CGFloat y = 0;
        CGRect labelFrame = CGRectMake(x, y, size.width, size.height);
        self.label.frame = labelFrame;
    } else {
        CGFloat x = 0;
        CGFloat y = 0;
        CGRect labelFrame = CGRectMake(x, y, size.width, size.height);
        self.label.frame = labelFrame;
    }

}
@end
