//
//  MessageLocation.h
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>
#import "MessageContent.h"

@interface MessageLocation : MessageContent
- (id)initWithLocation:(CLLocationCoordinate2D)location;

@property(nonatomic, readonly) CLLocationCoordinate2D location;
@property(nonatomic, readonly) NSString *snapshotURL;
@property(nonatomic, copy) NSString *address;

@end

typedef MessageLocation MessageLocationContent;
