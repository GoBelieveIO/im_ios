/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */


#import "LocationPickerController.h"
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"



@interface LocationPickerController()<MKMapViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property(nonatomic) MBProgressHUD *hub;
@property(nonatomic) UIImageView *annotationView;
@end


@implementation LocationPickerController

- (id)init {
	if (self = [super init]) {
        self.addressArray = [NSMutableArray array];
        self.addressSearchArray = [NSMutableArray array];
        self.userCoordinate = kCLLocationCoordinate2DInvalid;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float h = self.view.bounds.size.height;
    CGRect f = CGRectMake(0, 64, 320, h - 64);
    self.mapView = [[MKMapView alloc] initWithFrame:f];
    self.mapView.zoomEnabled       = YES;
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate          = self;
    self.mapView.mapType = MKMapTypeStandard;
    [self.view addSubview:self.mapView];

    UIImage *image = [UIImage imageNamed:@"Fav_Located"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(f.size.width/2 - 24 + 11, f.size.height/2 - 16 - 16, 48, 32);
    [self.mapView addSubview:imageView];
    self.annotationView = imageView;
    self.annotationView.hidden = YES;
    
    UIButton *itemButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 27, 60,30)];
    [itemButton setTitle:@"取消" forState:UIControlStateNormal];
    [itemButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:itemButton];

    
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(280, 27, 60,30)];
    [rightButton setTitle:@"发送" forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    
    self.navigationItem.title = @"位置";
    
#if !TARGET_IPHONE_SIMULATOR
    if (![CLLocationManager locationServicesEnabled]) {

    }
#endif
    
    self.hub = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.hub];
    self.hub.labelText = @"定位中...";
    [self.hub show:YES];
}

- (void)dealloc {
    self.addressArray = nil;
    self.addressSearchArray = nil;
}


- (void)actionLeft:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)actionRight:(id)sender {
    if (!CLLocationCoordinate2DIsValid(self.userCoordinate)) {
        return;
    }
    
    CGPoint point;
    point.x = self.mapView.bounds.size.width/2;
    point.y = self.mapView.bounds.size.height/2;
    CLLocationCoordinate2D location = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    [self.selectAddressdelegate didFinishSelectAddress:location];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark MKMapViewDelegate
- (void)mapView:(MKMapView *)lmapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!userLocation || !CLLocationCoordinate2DIsValid(userLocation.coordinate)) {
        return;
    }
    
    if (userLocation.location.horizontalAccuracy < 0 || userLocation.location.horizontalAccuracy > 10000) {
        return;
    }
    
    BOOL updateLocationInfo = NO;
    if (!CLLocationCoordinate2DIsValid(self.userCoordinate)) {
        updateLocationInfo = YES;
        
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 300, 500);
        [lmapView setRegion:region animated:YES];
        self.userCoordinate = userLocation.coordinate;
        
        self.annotationView.hidden = NO;
        [self.hub hide:YES];
    }
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"locate error:%@", error);
    
    self.hub.labelText = @"定位失败";
    
    [self.hub hide:YES];
}


- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    NSLog(@"regionWillChangeAnimated");
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    NSLog(@"regionDidChangeAnimated");
}


@end
