//
//  InsetsLabel.m
//  gobelieve
//
//  Created by houxh on 2017/12/14.
//

#import "InsetsLabel.h"

@implementation InsetsLabel

- (CGSize) intrinsicContentSize {
    UIEdgeInsets insets = self.insets;
    CGSize intrinsicSuperViewContentSize = [super intrinsicContentSize] ;
    intrinsicSuperViewContentSize.height += insets.top + insets.bottom;
    intrinsicSuperViewContentSize.width += insets.left + insets.right;
    return intrinsicSuperViewContentSize ;
}
@end
