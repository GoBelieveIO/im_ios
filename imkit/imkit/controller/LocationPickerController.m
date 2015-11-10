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


@interface PlaceAnnotation : NSObject <MKAnnotation>

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, retain) NSURL *url;

@end


@implementation PlaceAnnotation

@end

@interface LocationPickerController()<MKMapViewDelegate, CLLocationManagerDelegate> {
    CLLocationManager *_locationManager;
}

@property(nonatomic) MBProgressHUD *hub;
@property(nonatomic) UIView *annotationView;

@property(nonatomic) BOOL locating;
@property(nonatomic) PlaceAnnotation *annotation;
@end


@implementation LocationPickerController

- (id)init {
	if (self = [super init]) {
        self.addressArray = [NSMutableArray array];
        self.addressSearchArray = [NSMutableArray array];
        self.userCoordinate = kCLLocationCoordinate2DInvalid;
        self.locating = YES;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    float h = self.view.bounds.size.height;
    CGRect f = CGRectMake(0, 64, self.view.bounds.size.width, h - 64);
    self.mapView = [[MKMapView alloc] initWithFrame:f];
    self.mapView.zoomEnabled       = YES;
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate          = self;
    self.mapView.mapType = MKMapTypeStandard;
    [self.view addSubview:self.mapView];

    //create annotation view
    self.annotationView = [[UIView alloc] init];
    UIImage *image = [UIImage imageNamed:@"PinFloatingGreen"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(0, 0, 32, 39);
    [self.annotationView addSubview:imageView];
    image = [UIImage imageNamed:@"PinHole"];
    imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = CGRectMake(6, 49, 5, 4);
    [self.annotationView addSubview:imageView];

    self.annotationView.frame = CGRectMake(f.size.width/2 - 8, f.size.height/2 - 51, 32, 53);
    [self.mapView addSubview:self.annotationView];

    self.annotationView.hidden = YES;
    
    UIButton *itemButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 27, 60,30)];
    [itemButton setTitle:@"取消" forState:UIControlStateNormal];
    [itemButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [itemButton addTarget:self action:@selector(actionLeft:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:itemButton];

    
    UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(280, 27, 60,30)];
    [rightButton setTitle:NSLocalizedString(@"send", @"Send")  forState:UIControlStateNormal];
    [rightButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(actionRight:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    
    self.title = NSLocalizedString(@"location.messageType", @"location message");

    self.hub = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.hub];
    self.hub.labelText = NSLocalizedString(@"location.ongoning", @"locating...");
    [self.hub show:YES];
    
    [self startLocation];
}

- (void)dealloc {
    self.addressArray = nil;
    self.addressSearchArray = nil;
}

- (void)startLocation
{
    if([CLLocationManager locationServicesEnabled]){
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = 5;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;//kCLLocationAccuracyBest;
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
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
    [self.selectAddressdelegate didFinishSelectAddress:location address:self.annotation.title];
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

    if (self.locating) {
        self.locating = NO;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 300, 500);
        [lmapView setRegion:region animated:NO];
        [self.hub hide:YES];
    }
    
    self.userCoordinate = userLocation.coordinate;
    self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
    NSLog(@"locate error:%@", error);
    
    self.hub.labelText = @"定位失败";
    
    [self.hub hide:YES];
}


- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    NSLog(@"regionWillChangeAnimated");
    if (self.locating) {
        return;
    }
    self.annotationView.hidden = NO;
    if (self.annotation) {
        [self.mapView removeAnnotation:self.annotation];
        self.annotation = nil;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    NSLog(@"regionDidChangeAnimated");
    
    if (self.locating) {
        return;
    }
    
    self.annotationView.hidden = YES;
    
    
    CGPoint point;
    point.x = self.mapView.bounds.size.width/2;
    point.y = self.mapView.bounds.size.height/2;
    
    CLLocationCoordinate2D location = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
    
    if (self.annotation) {
        [self.mapView removeAnnotation:self.annotation];
        self.annotation = nil;
    }

    PlaceAnnotation *annotation = [[PlaceAnnotation alloc] init];
    annotation.coordinate = location;
    [self.mapView addAnnotation:annotation];
    self.annotation = annotation;
    
    __weak LocationPickerController *wself = self;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *array, NSError *error) {
        if (!error && array.count > 0) {
            CLPlacemark *placemark = [array objectAtIndex:0];
            annotation.title = placemark.name;
            if (wself.annotation) {
                [wself.mapView selectAnnotation:wself.annotation animated:YES];
            }
        }
    }];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    MKPinAnnotationView *annotationView = nil;
    
    if ([annotation isKindOfClass:[PlaceAnnotation class]]) {
        annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
        
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
            annotationView.canShowCallout = YES;
            annotationView.animatesDrop = NO;
            annotationView.pinColor = MKPinAnnotationColorGreen;
        }
    }
    return annotationView;
}


#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
            {
                [_locationManager requestWhenInUseAuthorization];
            }
            break;
        case kCLAuthorizationStatusDenied:
        {
            
        }
        default:
            break;
    }
}


@end
