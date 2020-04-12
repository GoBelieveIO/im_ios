//
//  ESImageViewController.h
//  Titanium
//
//  Created by Camille Kander on 5/29/14.
//  Copyright (c) 2014 Quri. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ESImageViewController : UIViewController

/**
 *  The image that will be displayed. Make sure to set this property before presenting the controller.
 */
@property (nonatomic, strong) UIImage *image;

@property (nonatomic,strong) NSString *imgUrl;

@property (nonatomic,strong) UIActivityIndicatorView * indicatorView;

/**
 * The thumbnail view that corresponds to the image that will be displayed.
 * This will be used to animate from the thumbnail into the full-screen imageView.
 */
@property (strong, nonatomic) UIView *tappedThumbnail;


@end
