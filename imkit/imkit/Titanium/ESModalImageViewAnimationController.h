//
//  ESModalImageViewAnimationController.h
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ESModalImageViewAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, strong) UIView *thumbnailView;

- (instancetype)initWithThumbnailView:(UIView *)thumbnailView;

@end
