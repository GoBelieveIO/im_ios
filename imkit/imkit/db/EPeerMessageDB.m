//
//  EPeerMessageDB.m
//  gobelieve
//
//  Created by houxh on 2018/1/17.
//

#import "EPeerMessageDB.h"


@implementation EPeerMessageDB
+(EPeerMessageDB*)instance {
    static EPeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[EPeerMessageDB alloc] init];
        }
    });
    return m;
}

-(id)init {
    self = [super init];
    if (self) {
        self.secret = YES;
    }
    return self;
}
@end
