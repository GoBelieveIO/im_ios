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


-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address {
    //以附件的形式存储，以免第二次查询
    [self updateMessageContent:msg.msgLocalID content:msg.rawContent];
}

-(BOOL)saveMessage:(IMessage*)msg {
    NSAssert(msg.isOutgoing, @"");
    return [self insertMessage:msg uid:msg.receiver];
}


@end
