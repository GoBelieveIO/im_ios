#import "PeerMessageDB.h"

@implementation PeerMessageDB
+(PeerMessageDB*)instance {
    static PeerMessageDB *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[PeerMessageDB alloc] init];
        }
    });
    return m;
}
-(id)init {
    self = [super init];
    if (self) {
        self.secret = NO;
    }
    return self;
}
@end
