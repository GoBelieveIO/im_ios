/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import "MapViewController.h"


#define FRIEND_ANNOTATION_TAG 1

@implementation MapAnnotation

- (id)initWithCoordinate:(CLLocationCoordinate2D)aCoordinate {
    if (self = [super init]) {
        self.coordinate = aCoordinate;
    }
	return self;
}

@end


@implementation MapViewController

- (id)init {
    self = [super init];
    if (self) {

    }
    return self;
}




- (void)dealloc {
}

- (MapAnnotation*)annotationWithTag:(NSInteger)tag {
    for (MapAnnotation* annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MapAnnotation class]] && annotation.tag == tag) {
            return annotation;
        }
    }
    return nil;
}
- (void) viewDidLoad {
    
    [super viewDidLoad];
    
    self.friendLocation = [[CLLocation alloc] initWithLatitude:self.friendCoordinate.latitude
                                                     longitude:self.friendCoordinate.longitude];
    float w = [UIScreen mainScreen].bounds.size.width;
    float h = [UIScreen mainScreen].bounds.size.height;
    
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 0, w, h)] ;
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
  	self.mapView.zoomEnabled = YES;
    
    [self.view addSubview:self.mapView];
    
    if (!CLLocationCoordinate2DIsValid(self.friendCoordinate)) {
        return;
    }
    
    MapAnnotation* annotation = [[MapAnnotation alloc] initWithCoordinate:self.friendCoordinate] ;
    annotation.tag = FRIEND_ANNOTATION_TAG;
    [self.mapView addAnnotation:annotation];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.friendCoordinate, 300, 500);
    [self.mapView setRegion:region animated:YES];
    
    [self updateAddress];
}

- (void)updateAddress {
    __weak MapViewController *wself = self;
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    CLLocationCoordinate2D location = self.friendCoordinate;
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
    [geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray *array, NSError *error) {
        if (!error && array.count > 0) {
            CLPlacemark *placemark = [array objectAtIndex:0];
            MapAnnotation* annotation = [wself annotationWithTag:FRIEND_ANNOTATION_TAG];
            annotation.title = placemark.name;
            if (annotation) {
                [wself.mapView selectAnnotation:annotation animated:YES];
            }
        }
    }];
}

- (void)updateDistance {
    MapAnnotation* annotation = [self annotationWithTag:FRIEND_ANNOTATION_TAG];
    if (annotation) {
        CLLocation *loc = self.friendLocation;
        CLLocation *loc2 = self.userLocation;
        
        CLLocationDistance dist = [loc distanceFromLocation:loc2];
        int distance = dist;
        annotation.title = @"距离";
        annotation.subtitle = [NSString stringWithFormat:@"%d米", distance];
        
        [self.mapView selectAnnotation:annotation animated:NO];
    }
}

#pragma MKMapViewDelegate
- (void)mapView:(MKMapView *)lmapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    self.userLocation = userLocation.location;
}

- (void)mapView:(MKMapView *)lmapView didAddAnnotationViews:(NSArray *)views {
}

- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[MKUserLocation class]]) {
        MKAnnotationView *returnedAnnotationView =
        [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
        if (returnedAnnotationView == nil) {
            returnedAnnotationView =
            [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                            reuseIdentifier:@"annotation"];
            
            ((MKPinAnnotationView *)returnedAnnotationView).pinColor = MKPinAnnotationColorPurple;
            ((MKPinAnnotationView *)returnedAnnotationView).animatesDrop = YES;
            ((MKPinAnnotationView *)returnedAnnotationView).canShowCallout = YES;
        }
        
        return returnedAnnotationView;
    }
    return nil;
}

@end
