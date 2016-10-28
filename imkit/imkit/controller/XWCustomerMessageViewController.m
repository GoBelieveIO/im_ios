#import "XWCustomerMessageViewController.h"
#import "IMService.h"
#import "CustomerMessageHandler.h"
#import "UIView+Toast.h"

#define URL @"http://api.gobelieve.io"

@interface XWCustomerMessageViewController()
//客服信息
@property(nonatomic, assign) int64_t lastSellerID;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatar;
@property(nonatomic, copy) NSString *status;
@property(nonatomic, assign) int gotTimestamp;
@end

@implementation XWCustomerMessageViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    
    

    [[IMService instance] start];
    
    [self loadSupporter];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    int now = (int)time(NULL);
    if (self.sellerID == 0 || now - self.gotTimestamp > 3600) {
        self.lastSellerID = self.sellerID;
        self.sellerID = 0;
        [self disableSend];
        [self getSupporter];
    }
}

-(NSMutableURLRequest*)newUserURLRequest:(NSString*)path {
    NSString *url = [NSString stringWithFormat:@"%@%@", URL, path];
    
    //The default timeout interval is 60 seconds.
    //In iOS versions prior to iOS 6, the minimum (and default) timeout interval for any request containing a request body was 240 seconds.
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    NSString *auth = [NSString stringWithFormat:@"Bearer %@", self.token];
    [headers setObject:auth forKey:@"Authorization"];
    [urlRequest setAllHTTPHeaderFields:headers];
    
    return urlRequest;
    
}

-(NSMutableURLRequest*)newGetSupporterRequest:(int64_t)storeID {
    NSString *t = [NSString stringWithFormat:@"/supporters?store_id=%lld", storeID];
    NSMutableURLRequest *urlRequest = [self newUserURLRequest:t];
    [urlRequest setHTTPMethod:@"GET"];
    return urlRequest;
}

- (void)onGetSupporterFailure {
    [self.view makeToast:@"无法请求客服服务，请检查你的网络"];
}

- (void)onGetSupporterSuccess:(NSData*)data {
    NSDictionary *obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    NSLog(@"get supporter resp:%@", obj);
    NSDictionary *r = [obj objectForKey:@"data"];
    int64_t sellerID = [[r objectForKey:@"seller_id"] longLongValue];
    NSString *name = [r objectForKey:@"name"];
    NSString *avatar = [r objectForKey:@"avatar"];
    NSString *status = [r objectForKey:@"status"];
    
    int gotTimestamp = (int)time(NULL);

    self.sellerID = sellerID;
    self.name = name;
    self.avatar = avatar;
    self.status = status;
    self.gotTimestamp = (int)time(NULL);
    
    [self saveSupporter];
    
    //获得新的客服人员
    if (self.sellerID != self.lastSellerID) {
        if ([IMService instance].connectState == STATE_CONNECTED) {
            [self enableSend];
        }
        
        ICustomerMessage *msg = [[ICustomerMessage alloc] init];
        
        msg.customerAppID = self.appID;
        msg.customerID = self.currentUID;
        msg.storeID = self.storeID;
        msg.sellerID = self.sellerID;
        
        msg.sender = self.sellerID;
        msg.receiver = self.currentUID;
        
        NSString *headline = [NSString stringWithFormat:@"%@为您服务", self.name];
        
        MessageHeadlineContent *content = [[MessageHeadlineContent alloc] initWithHeadline:headline];
        msg.rawContent = content.raw;
        
        msg.timestamp = (int)time(NULL);
        msg.isSupport = YES;
        msg.isOutgoing = NO;
        
        [self saveMessage:msg];
        
        [self insertMessage:msg];

    }
}

- (void)getSupporter {
    __weak XWCustomerMessageViewController *wself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *respData = nil;
        for (int i = 0; i < 5; i++) {
            NSURLResponse *response = nil;
            NSError *error = nil;
            NSMutableURLRequest *request = [self newGetSupporterRequest:self.storeID];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

            if (error != nil) {
                NSLog(@"get supporter error:%@", error);
                [NSThread sleepForTimeInterval:1.0];
                continue;
            }
            
            NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
            if (resp.statusCode != 200) {
                NSString *t = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"get supporter error:%@---%@", resp, t);
                break;
            }
            respData = data;
            break;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (respData) {
                [wself onGetSupporterSuccess:respData];
            } else {
                [wself onGetSupporterFailure];
            }
        });
    });
}

- (void) onConnectState:(int)state {
    if(state == STATE_CONNECTED && self.sellerID > 0){
        [self enableSend];
    } else {
        [self disableSend];
    }
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


- (NSDictionary*)loadDictionary {
    NSString *docPath = [self getDocumentPath];
    NSString *fullFileName = [NSString stringWithFormat:@"%@/supporter", docPath];
    NSDictionary* panelLibraryContent = [NSDictionary dictionaryWithContentsOfFile:fullFileName];
    return panelLibraryContent;
}


- (void)storeDictionary:(NSDictionary*) dictionaryToStore {
    NSString *docPath = [self getDocumentPath];
    NSString *fullFileName = [NSString stringWithFormat:@"%@/supporter", docPath];
    
    if (dictionaryToStore != nil) {
        [dictionaryToStore writeToFile:fullFileName atomically:YES];
    }
}

- (void)loadSupporter {
    NSDictionary *dict = [self loadDictionary];
    int64_t storeID = [[dict objectForKey:@"store_id"] longLongValue];
    int64_t sellerID = [[dict objectForKey:@"seller_id"] longLongValue];
    
    if (storeID != self.storeID) {
        return;
    }
    

    self.name = [dict objectForKey:@"name"];
    self.avatar = [dict objectForKey:@"avatar"];
    self.status = [dict objectForKey:@"status"];
    self.gotTimestamp = [[dict objectForKey:@"timestamp"] intValue];
    self.storeID = storeID;
    self.sellerID = sellerID;
    
    NSAssert(self.storeID > 0, @"");
}

- (void)saveSupporter {
    NSDictionary *dict = @{@"name":self.name ? self.name : @"",
                           @"avatar":self.avatar ? self.avatar : @"",
                           @"status":self.status ? self.status : @"",
                           @"timestamp":[NSNumber numberWithInt:self.gotTimestamp],
                           @"store_id":[NSNumber numberWithLongLong:self.storeID],
                           @"seller_id":[NSNumber numberWithLongLong:self.sellerID]
                           };
    [self storeDictionary:dict];
}

-(void)onBack {
    [super onBack];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[IMService instance] stop];
}


- (void)appDidEnterBackground:(NSNotification*)notification {
    [[IMService instance] enterBackground];
}

- (void)appWillEnterForeground:(NSNotification*)notification {
    [[IMService instance] enterForeground];
}



@end
