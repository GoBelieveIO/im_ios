//
//  MessageLocation.m
//  gobelieve
//
//  Created by houxh on 2018/1/25.
//

#import "MessageLocation.h"

@implementation MessageLocation

- (id)initWithLocation:(CLLocationCoordinate2D)location {
    self = [super init];
    if (self) {
        NSString *uuid = [[NSUUID UUID] UUIDString];
        NSDictionary *loc = @{@"latitude":[NSNumber numberWithDouble:location.latitude],
                              @"longitude":[NSNumber numberWithDouble:location.longitude]};
        NSDictionary *dic = @{@"location":loc, @"uuid":uuid};
        NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
        self.raw =  newStr;
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

-(void)setAddress:(NSString *)address {
    _address = [address copy];
    
    CLLocationCoordinate2D location = self.location;
    NSDictionary *loc = @{@"latitude":[NSNumber numberWithDouble:location.latitude],
                          @"longitude":[NSNumber numberWithDouble:location.longitude],
                          @"address":address};
    NSDictionary *dic = @{@"location":loc, @"uuid":self.uuid};
    NSString* newStr = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dic options:0 error:nil] encoding:NSUTF8StringEncoding];
    self.raw = newStr;
}

-(int)type {
    return MESSAGE_LOCATION;
}
@end
