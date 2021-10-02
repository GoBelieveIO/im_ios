//
//  MessageLocation.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageLocation.h"

@implementation MessageLocation

- (id)initWithLocation:(CLLocationCoordinate2D)location {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSDictionary *loc = @{
        @"latitude":[NSNumber numberWithDouble:location.latitude],
        @"longitude":[NSNumber numberWithDouble:location.longitude]
    };
    NSDictionary *dic = @{@"location":loc, @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)location address:(NSString*)address {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSMutableDictionary *loc = [NSMutableDictionary dictionary];
    [loc setObject:[NSNumber numberWithDouble:location.latitude] forKey:@"latitude"];
    [loc setObject:[NSNumber numberWithDouble:location.longitude] forKey:@"longitude"];
    if (address.length > 0) {
        [loc setObject:address forKey:@"address"];
    }
    NSDictionary *dic = @{@"location":loc, @"uuid":uuid};
    self = [super initWithDictionary:dic];
    if (self) {

    }
    return self;
}


-(CLLocationCoordinate2D)location {
    CLLocationCoordinate2D lc;
    NSDictionary *location = [self.dict objectForKey:@"location"];
    lc.latitude = [[location objectForKey:@"latitude"] doubleValue];
    lc.longitude = [[location objectForKey:@"longitude"] doubleValue];
    return lc;
}

-(NSString*)snapshotURL {
    CLLocationCoordinate2D location = self.location;
    NSString *s = [NSString stringWithFormat:@"%f-%f", location.latitude, location.longitude];
    NSString *t = [NSString stringWithFormat:@"http://localhost/snapshot/%@.png", s];
    return t;
}

-(NSString*)address {
    return [[self.dict objectForKey:@"location"] objectForKey:@"address"];
}

-(int)type {
    return MESSAGE_LOCATION;
}

-(MessageLocation*)cloneWithAddress:(NSString*)address {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self.dict];
    NSMutableDictionary *location = [NSMutableDictionary dictionaryWithDictionary:[dict objectForKey:@"location"]];
    [location setObject:address forKey:@"address"];
    [dict setObject:location forKey:@"location"];
    
    MessageLocation *newContent = [[MessageLocation alloc] initWithDictionary:dict];
    return newContent;
}
@end
