//
//  ESImageViewController-Internals.h
//  Titanium
//
//  Created by Camille Kander on 6/24/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import "ESImageViewController.h"

@interface ESImageViewController ()

@property (strong, nonatomic) UIImageView *imageView;

- (CGRect)imageViewFrameForImage:(UIImage *)image;

@end
