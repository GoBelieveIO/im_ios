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



@protocol LocationPickerControllerDelegate <NSObject>
- (void)didFinishSelectAddress:(CLLocationCoordinate2D)corrdinate address:(NSString*)address;
@end

@interface LocationPickerController : UIViewController  {
}

@property (nonatomic, weak) id<LocationPickerControllerDelegate> selectAddressdelegate;
@property (nonatomic, retain) NSMutableArray* addressArray;
@property (nonatomic, retain) NSMutableArray* addressSearchArray;

@property (nonatomic, strong) MKLocalSearch *localSearch;
@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic) MKMapView *mapView;
@property (nonatomic) UITableView *addressTable;
@property (nonatomic) CLLocationCoordinate2D userCoordinate;

@end
