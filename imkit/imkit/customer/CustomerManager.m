#import "CustomerManager.h"
#import "ApplicationCustomerMessageViewController.h"
#import "CustomerMessageDB.h"
#import "IMHttpAPI.h"

@interface CustomerManager()

//devicetoken 是否已经绑定成功
@property(nonatomic, assign) BOOL binded;
@property(nonatomic, copy) NSString *deviceToken;

@property(nonatomic, copy) NSString *token;
@property(nonatomic, assign) int64_t storeID;

-(NSDictionary*) loadDictionary;
- (void)storeDictionary:(NSDictionary*)dictionaryToStore;
@end



@implementation CustomerManager
+(CustomerManager*)instance {
    static CustomerManager *m;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!m) {
            m = [[CustomerManager alloc] init];
        }
    });
    return m;
}


//初始化customermanager
-(void)initWithAppID:(int64_t)appID appKey:(NSString*)appKey deviceID:(NSString*)deviceID {
    [self load];
    
    if (self.appID > 0) {
        NSAssert(appID == self.appID, @"");
    }
    
    self.appID = appID;
    self.appKey = appKey;
    self.deviceID = deviceID;
}

-(void)registerClient:(NSString*)name
           cmopletion:(void (^)(int64_t clientID, NSError *error))completion {
    
    [self registerClient:@"" name:name avatar:@"" cmopletion:completion];
}

-(void)registerClient:(NSString*)uid name:(NSString*)name avatar:(NSString*)avatar
           cmopletion:(void (^)(int64_t clientID, NSError *error))completion {
    NSString *url = @"http://api.gobelieve.io/customer/register";
    
    //The default timeout interval is 60 seconds.
    //In iOS versions prior to iOS 6, the minimum (and default) timeout interval for any request containing a request body was 240 seconds.
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];
    [urlRequest setHTTPMethod:@"POST"];
    
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
    [urlRequest setAllHTTPHeaderFields:headers];
    
    NSDictionary *dict = @{@"appid":[NSNumber numberWithLongLong:self.appID],
                           @"uid":uid,
                           @"user_name":name ? name :@"",
                           @"avatar":avatar ? avatar :@"",
                           @"platform_id":@1,
                           @"device_id":self.deviceID};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    [urlRequest setHTTPBody:data];
    
    __weak CustomerManager *wself = self;
    
  
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                               if (connectionError) {
                                   NSLog(@"connection error:%@", connectionError);
                                   NSError *e = [NSError errorWithDomain:@"customer" code:1000 userInfo:nil];
                                   completion(0, e);
                                   return;
                               }
                               
                               NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                               if (statusCode != 200) {
                                   NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                   NSLog(@"customer authorization error:%@", resp);
                                   
                                   NSError *e = [NSError errorWithDomain:@"customer" code:2000 userInfo:nil];
                                   completion(0, e);
                                   return;
                               }
                               NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                               NSLog(@"customer authorization resp:%@", resp);
                               
                               NSString *token = resp[@"data"][@"token"];
                               int64_t storeID = [resp[@"data"][@"store_id"] longLongValue];
                               int64_t clientID = [resp[@"data"][@"client_id"] longLongValue];
                               
                               wself.clientID = clientID;
                               wself.storeID = storeID;
                               wself.token = token;
                               wself.uid = uid;
                               wself.name = name;
                               wself.avatar = avatar;
                      
                               
                               [self storeDictionary];
                               
                               NSString *path = [self getDocumentPath];
                               NSString *dbPath = [NSString stringWithFormat:@"%@/%lld", path, clientID];
                               [CustomerMessageDB instance].dbPath = [NSString stringWithFormat:@"%@/customer", dbPath];
                               
                               completion(clientID, nil);
                      
                           }];

}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(void)setClientName:(NSString*)name avatar:(NSString*)avatar {
    if (self.clientID == 0) {
        NSLog(@"client 0, can't set client name&avatar");
        return;
    }
    self.name = name;
    self.avatar = avatar;
    [self storeDictionary];
}

-(void)bindDeviceToken:(NSData*)deviceToken {
    NSString* newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if ([self.deviceToken isEqualToString:newToken] && self.binded) {
        return;
    }
    
    self.binded = NO;
    self.deviceToken = deviceToken;
    [self storeDictionary];
    
    if (self.token.length > 0 && self.deviceToken.length > 0) {
        //bind device token
        [IMHttpAPI instance].accessToken = self.token;
        [IMHttpAPI bindDeviceToken:deviceToken success:^{
            self.binded = YES;
            [self storeDictionary];
            NSLog(@"bind device token success");
        } fail:^{
            NSLog(@"bind device token success");
        }];
    }
}

-(void)unbindDeviceToken {
    [self storeDictionary];
    if (self.token.length > 0 && self.deviceToken.length > 0) {
        [IMHttpAPI instance].accessToken = self.token;
        [IMHttpAPI unbindDeviceToken:self.deviceToken success:^{
            NSLog(@"unbind device token success");
        } fail:^{
            NSLog(@"unbind device token fail");
        }];
    }
}

-(void)getUnreadMessageWithCompletion:(void(^)(BOOL hasUnread, NSError* error))completion {
    
}


- (void)load {
    NSDictionary *dict = [self loadDictionary];
    self.token = [dict objectForKey:@"token"];
    self.storeID = [[dict objectForKey:@"store_id"] longLongValue];
    self.uid = [dict objectForKey:@"uid"];
    self.appID = [[dict objectForKey:@"appid"] longLongValue];
    self.clientID = [[dict objectForKey:@"client_id"] longLongValue];
    self.name = [dict objectForKey:@"name"];
    self.avatar = [dict objectForKey:@"avatar"];
    self.deviceID = [dict objectForKey:@"device_id"];
    self.deviceToken = [dict objectForKey:@"device_token"];
    self.binded = [[dict objectForKey:@"binded"] intValue];
}

-(NSDictionary*) loadDictionary {
    NSString *docPath = [self getDocumentPath];
    NSString *fullFileName = [NSString stringWithFormat:@"%@/customer", docPath];
    NSDictionary* panelLibraryContent = [NSDictionary dictionaryWithContentsOfFile:fullFileName];
    return panelLibraryContent;
}

-(void)storeDictionary {
    NSDictionary *dict = @{@"token":self.token ? self.token : @"",
                           @"store_id":[NSNumber numberWithLongLong:self.storeID],
                           @"uid":self.uid ? self.uid : @"",
                           @"appid":[NSNumber numberWithLongLong:self.appID],
                           @"client_id":[NSNumber numberWithLongLong:self.clientID],
                           @"name":self.name ? self.name : @"",
                           @"avatar":self.avatar ? self.name : @"",
                           @"device_id":self.deviceID ? self.deviceID : @"",
                           @"device_token":self.deviceToken ? self.deviceToken : @"",
                           @"binded":[NSNumber numberWithInt:(self.binded ? 1 : 0)]};
    
    [self storeDictionary:dict];
}

-(void) storeDictionary:(NSDictionary*) dictionaryToStore {
    NSString *docPath = [self getDocumentPath];
    NSString *fullFileName = [NSString stringWithFormat:@"%@/customer", docPath];
    
    if (dictionaryToStore != nil) {
        [dictionaryToStore writeToFile:fullFileName atomically:YES];
    }
}

-(void)pushCustomerViewControllerInViewController:(UINavigationController*)controller title:(NSString*)title {
    if (self.clientID == 0) {
        return;
    }
    
    ApplicationCustomerMessageViewController *ctrl = [[ApplicationCustomerMessageViewController alloc] init];
    ctrl.token = self.token;
    ctrl.storeID = self.storeID;
    ctrl.currentUID = self.clientID;
    ctrl.appID = self.appID;
    ctrl.peerName = title;
    ctrl.sellerID = 100083;
    [controller pushViewController:ctrl animated:YES];
}


@end
