/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapAnnotation : NSObject <MKAnnotation>
{

}
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic) NSInteger tag;
- (id) initWithCoordinate: (CLLocationCoordinate2D) aCoordinate;
@end


@interface MapViewController : UIViewController <MKMapViewDelegate> {
}

@property (nonatomic) CLLocationCoordinate2D friendCoordinate;
@property (nonatomic, retain) CLLocation* friendLocation;
@property (nonatomic, retain) CLLocation* userLocation;
@property (nonatomic) MKMapView *mapView;

@end
