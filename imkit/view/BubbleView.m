/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/
#import "BubbleView.h"

@implementation BubbleView

- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    if(self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)dealloc {
    [self.msg removeObserver:self forKeyPath:@"flags"];
}

-(CGSize)bubbleSize {
    return CGSizeZero;
}

-(void)setMsg:(IMessage *)msg {
    [self.msg removeObserver:self forKeyPath:@"flags"];
    _msg = msg;
    [self.msg addObserver:self forKeyPath:@"flags" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
}
@end
