//
//  UIImage+HCD_Extension.m
//  WeChatInputBar
//
//  Created by hcd on 2018/11/6.
//  Copyright © 2018 hcd. All rights reserved.
//

#import "UIImage+HCD_Extension.h"

@implementation UIImage (HCD_Extension)
+ (UIImage *)imageWithColor:(UIColor *)aColor {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [aColor CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end
