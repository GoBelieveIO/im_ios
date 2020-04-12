/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "TriangleView.h"

@implementation TriangleView

-(void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    CGPoint sPoints[3];
    if (self.fillColor) {
        UIColor*aColor = self.fillColor;
        CGContextSetFillColorWithColor(context, aColor.CGColor);
    }
    if (self.right) {
        sPoints[0] =CGPointMake(0, 0);
        sPoints[1] =CGPointMake(w, h/2);
        sPoints[2] =CGPointMake(0, h);
    } else {
        sPoints[0] =CGPointMake(w, 0);
        sPoints[1] =CGPointMake(0, h/2);
        sPoints[2] =CGPointMake(w, h);
    }
    CGContextAddLines(context, sPoints, 3);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
}
@end
