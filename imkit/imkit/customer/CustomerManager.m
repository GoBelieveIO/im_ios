#import "CustomerManager.h"
#import "XWCustomerMessageViewController.h"
#import "CustomerMessageDB.h"
#import "IMHttpAPI.h"
#import "CustomerMessageHandler.h"
#import "SyncKeyHandler.h"
#import <FMDB/FMDB.h>
#import <sqlite3.h>

#define URL @"http://api.gobelieve.io"

//#define URL @"http://192.168.33.10:5000"

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

-(NSMutableURLRequest*)newClientURLRequest:(NSString*)path {
    NSString *url = [NSString stringWithFormat:@"%@%@", URL, path];
    
    //The default timeout interval is 60 seconds.
    //In iOS versions prior to iOS 6, the minimum (and default) timeout interval for any request containing a request body was 240 seconds.
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];
    
    NSString *basic = [NSString stringWithFormat:@"%lld:%@", self.appID, self.appKey];
    NSString *basic64 = [[basic dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    
    NSLog(@"base64:%@", basic64);
    NSString *auth = [NSString stringWithFormat:@"Basic %@", basic64];
    NSDictionary *headers = @{@"Content-Type":@"application/json", @"Authorization":auth};
    [urlRequest setAllHTTPHeaderFields:headers];
    
    return urlRequest;
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
-(void)registerClient:(NSString*)uid name:(NSString*)name avatar:(NSString*)avatar
           cmopletion:(void (^)(int64_t clientID, NSError *error))completion {

    NSMutableURLRequest *urlRequest = [self newClientURLRequest:@"/customer/register"];
    NSDictionary *dict = @{@"appid":[NSNumber numberWithLongLong:self.appID],
                           @"customer_id":uid,
                           @"name":name ? name :@"",
                           @"avatar":avatar ? avatar :@"",
                           @"platform_id":@1,
                           @"device_id":self.deviceID};
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    [urlRequest setHTTPBody:data];
    [urlRequest setHTTPMethod:@"POST"];
    
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
                               
                               completion(clientID, nil);
                               
                           }];

}

-(BOOL)mkdir:(NSString*)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        NSError *err;
        BOOL r = [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        
        if (!r) {
            NSLog(@"mkdir err:%@", err);
        }
        return r;
    }
    
    return YES;
}

-(void)login {

    NSString *path = [self getDocumentPath];
#ifdef FILE_ENGINE_DB
    NSString *dbPath = [NSString stringWithFormat:@"%@/%lld", path, self.clientID];
    [self mkdir:dbPath];
    [CustomerMessageDB instance].dbPath = [NSString stringWithFormat:@"%@/customer", dbPath];
#elif defined SQL_ENGINE_DB
    NSString *dbPath = [NSString stringWithFormat:@"%@/gobelieve_%lld.db", path, self.clientID];
    //检查数据库文件是否已经存在
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dbPath]) {
        NSString *p = [[NSBundle mainBundle] pathForResource:@"gobelieve" ofType:@"db"];
        [fileManager copyItemAtPath:p toPath:dbPath error:nil];
    }
    FMDatabase *db = [[FMDatabase alloc] initWithPath:dbPath];
    BOOL r = [db openWithFlags:SQLITE_OPEN_READWRITE|SQLITE_OPEN_WAL vfs:nil];
    if (!r) {
        NSLog(@"open database error:%@", [db lastError]);
        db = nil;
        NSAssert(NO, @"");
    }
    [CustomerMessageDB instance].db = db;
#else
#error no engine
#endif
    
    
    [CustomerMessageHandler instance].uid = self.clientID;
    [IMService instance].customerMessageHandler = [CustomerMessageHandler instance];
    [IMService instance].token = self.token;
    [IMHttpAPI instance].accessToken = self.token;
    
    dbPath = [NSString stringWithFormat:@"%@/%lld", path, self.clientID];
    [self mkdir:dbPath];
    NSString *fileName = [NSString stringWithFormat:@"%@/synckey", dbPath];
    SyncKeyHandler *handler = [[SyncKeyHandler alloc] initWithFileName:fileName];
    [IMService instance].syncKeyHandler = handler;
    
    [IMService instance].syncKey = [handler syncKey];
    NSLog(@"sync key:%lld", [handler syncKey]);
    
    [[IMService instance] clearSuperGroupSyncKey];
    NSDictionary *groups = [handler superGroupSyncKeys];
    for (NSNumber *k in groups) {
        NSNumber *v = [groups objectForKey:k];
        NSLog(@"group id:%@ sync key:%@", k, v);
        [[IMService instance] addSuperGroupSyncKey:[v longLongValue] gid:[k longLongValue]];
    }
    
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


-(NSMutableURLRequest*)newBindDeviceTokenRequest:(NSString*)deviceToken {
    NSMutableURLRequest *urlRequest = [self newUserURLRequest:@"/device/unbind"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.deviceToken forKey:@"apns_device_token"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    [urlRequest setHTTPBody:data];
    [urlRequest setHTTPMethod:@"POST"];
    return urlRequest;
}
-(NSMutableURLRequest*)newUnbindDeviceTokenRequest:(NSString*)deviceToken {
    NSMutableURLRequest *urlRequest = [self newUserURLRequest:@"/device/unbind"];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.deviceToken forKey:@"apns_device_token"];
    NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
    [urlRequest setHTTPBody:data];
    [urlRequest setHTTPMethod:@"POST"];
    return urlRequest;
}

-(void)unregisterClient {
    self.clientID = 0;
    self.binded = NO;
    self.deviceToken = @"";
    self.storeID = 0;
    self.token = @"";
    self.name = @"";
    self.avatar = @"";
    [self storeDictionary];
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

-(void)bindDeviceToken:(NSData*)deviceToken completion:(void (^)(NSError *error))completion {
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
        NSMutableURLRequest *urlRequest = [self newBindDeviceTokenRequest:self.deviceToken];
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                                   NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                                   
                                   if (connectionError) {
                                       NSLog(@"connection error:%@", connectionError);
                                       NSError *e = [NSError errorWithDomain:@"customer" code:1000 userInfo:nil];
                                       completion(e);
                                       return;
                                   }
                                   if (statusCode != 200) {
                                       NSLog(@"bind device token fail");
                                       NSError *e = [NSError errorWithDomain:@"customer" code:2000 userInfo:nil];
                                       completion(e);
                                       return;
                                   } else {
                                       NSLog(@"bind device token success");
                                    
                                       self.binded = YES;
                                       [self storeDictionary];
                                       completion(nil);
                                   }
                               }];

    }
}

-(void)unbindDeviceToken:(void (^)(NSError *error))completion {
    if (self.binded && self.deviceToken.length > 0) {
        NSMutableURLRequest *urlRequest = [self newUnbindDeviceTokenRequest:self.deviceToken];
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                                   NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                                   
                                   if (connectionError) {
                                       NSLog(@"connection error:%@", connectionError);
                                       NSError *e = [NSError errorWithDomain:@"customer" code:1000 userInfo:nil];
                                       completion(e);
                                       return;
                                   }
                                   if (statusCode != 200) {
                                       NSError *e = [NSError errorWithDomain:@"customer" code:2000 userInfo:nil];
                                       completion(e);
                                       return;
                                   } else {
                                       NSLog(@"unbind device token success");
                                       
                                       self.deviceToken = @"";
                                       self.binded = NO;
                                       [self storeDictionary];
                                       
                                       completion(nil);
                                   }
                               }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.deviceToken = @"";
            self.binded = NO;
            [self storeDictionary];
            
            completion(nil);
        });
    }
}

-(void)unbindDeviceToken {
    [self storeDictionary];
    if (self.token.length > 0 && self.deviceToken.length > 0) {
        [IMHttpAPI unbindDeviceToken:self.deviceToken success:^{
            NSLog(@"unbind device token success");
        } fail:^{
            NSLog(@"unbind device token fail");
        }];
    }
}

-(NSMutableURLRequest*)newGetOfflineRequest {
    NSMutableURLRequest *urlRequest = [self newUserURLRequest:@"/messages/offline"];
    [urlRequest setHTTPMethod:@"GET"];
    return urlRequest;
}

-(void)getUnreadMessageWithCompletion:(void(^)(BOOL hasUnread, NSError* error))completion {
    if (self.token.length == 0) {
        NSLog(@"token is null");
        return;
    }

    NSMutableURLRequest *urlRequest = [self newGetOfflineRequest];
    __weak CustomerManager *wself = self;
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
                               if (connectionError) {
                                   NSLog(@"connection error:%@", connectionError);
                                   NSError *e = [NSError errorWithDomain:@"customer" code:1000 userInfo:nil];
                                   completion(NO, e);
                                   return;
                               }
                               
                               NSInteger statusCode = [(NSHTTPURLResponse*)response statusCode];
                               if (statusCode != 200) {
                                   NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                                   NSLog(@"customer authorization error:%@", resp);
                                   
                                   NSError *e = [NSError errorWithDomain:@"customer" code:2000 userInfo:nil];
                                   completion(NO, e);
                                   return;
                               }
                               NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
                               NSLog(@"customer authorization resp:%@", resp);
                               
                               int new = [resp[@"data"][@"new"] intValue];
                               completion(new, nil);
                           }];
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

    XWCustomerMessageViewController *ctrl = [[XWCustomerMessageViewController alloc] init];
    ctrl.token = self.token;
    ctrl.storeID = self.storeID;
    ctrl.currentUID = self.clientID;
    ctrl.appID = self.appID;
    ctrl.peerName = title;
    [controller pushViewController:ctrl animated:YES];
}


@end
