/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "MainViewController.h"

#import <gobelieve/IMService.h>
#import <gobelieve/MessageViewController.h>
#import <gobelieve/IMHttpAPI.h>
#import <gobelieve/PeerMessageViewController.h>
#import <gobelieve/GroupMessageViewController.h>
#import <gobelieve/CustomerMessageViewController.h>
#import <gobelieve/PeerMessageDB.h>
#import <gobelieve/GroupMessageDB.h>
#import <gobelieve/CustomerMessageDB.h>
#import <gobelieve/SyncKeyHandler.h>
#import <gobelieve/PeerMessageHandler.h>
#import <gobelieve/GroupMessageHandler.h>
#import <gobelieve/CustomerMessageHandler.h>
#import "RoomViewController.h"
#import <FMDB/FMDB.h>
#import "Database.h"

#define TEST_PEER
//#define TEST_GROUP
//#define TEST_CUSTOMER
//#define TEST_ROOM

#define APPID 7


@interface MainViewController (){
    UITextField *tfSender;
    UITextField *tfReceiver;
}

@property(nonatomic, weak)UIButton *chatButton;
@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    bgImageView.image = [UIImage imageNamed:@"bg"];
    [self.view addSubview:bgImageView];
    
    float startHeight = [[UIScreen mainScreen] bounds].size.height >= 568.0 ? 180 : 100;
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, startHeight + 12, 17, 21)];
    headerImageView.image = [UIImage imageNamed:@"ic_man"];
    [self.view addSubview:headerImageView];
    
    tfSender = [[UITextField alloc] initWithFrame:CGRectMake(52, startHeight + 4, 180, 37)];
    tfSender.textColor = [UIColor whiteColor];
    tfSender.font = [UIFont systemFontOfSize:18];
    tfSender.placeholder = @"发送用户id";
    tfSender.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:tfSender];
    
    UIView *whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
    whiteLine.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:0.4];
    [self.view addSubview:whiteLine];
    
    startHeight += 45;
    headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, startHeight + 12, 17, 21)];
    headerImageView.image = [UIImage imageNamed:@"ic_man"];
    [self.view addSubview:headerImageView];
    
    tfReceiver = [[UITextField alloc] initWithFrame:CGRectMake(52, startHeight + 4, 180, 37)];
    tfReceiver.textColor = [UIColor whiteColor];
    tfReceiver.font = [UIFont systemFontOfSize:18];
#ifdef TEST_PEER
    tfReceiver.placeholder = @"接收用户id";
#elif defined TEST_GROUP
    tfReceiver.placeholder = @"群组id(15)";
#elif defined TEST_CUSTOMER
    tfReceiver.placeholder = @"商店id(7)";
#elif defined TEST_ROOM
    tfReceiver.placeholder = @"房间id";
#endif
    tfReceiver.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:tfReceiver];
    
    whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
    whiteLine.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:0.4];
    [self.view addSubview:whiteLine];
    startHeight += 45 + ([[UIScreen mainScreen] bounds].size.height >= 568.0 ? 20 : 15);
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(15, startHeight, self.view.frame.size.width - 30, 48);
    [btn setTitle:@"登录" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"btn_blue"] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17];
    [btn addTarget:self action:@selector(actionChat) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    self.chatButton = btn;
    
    self.navigationController.delegate = self;

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
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

- (void)actionChat {
    if (!tfSender.text.length || !tfSender.text.length) {
        NSLog(@"invalid input");
        return;
    }
    [self.view endEditing:YES];
    
    self.chatButton.userInteractionEnabled = NO;
    long long sender = [tfSender.text longLongValue];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *token = [self login:sender];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.chatButton.userInteractionEnabled = YES;
            
            if (token.length == 0) {
                NSLog(@"login fail");
                return;
            }
            
            NSLog(@"login success");
            NSString *path = [self getDocumentPath];
            NSString *dbPath = [NSString stringWithFormat:@"%@/gobelieve_%lld.db", path, [tfSender.text longLongValue]];
            dbPath = [NSString stringWithFormat:@"%@/gobelieve.db", path];
            NSLog(@"open message db:%@", dbPath);
            FMDatabase *db = [Database openMessageDB:dbPath];

            [PeerMessageDB instance].db = db;
            [GroupMessageDB instance].db = db;
            [CustomerMessageDB instance].db = db;

            [PeerMessageHandler instance].uid = [tfSender.text longLongValue];
            [GroupMessageHandler instance].uid = [tfSender.text longLongValue];
            [CustomerMessageHandler instance].uid = [tfSender.text longLongValue];
            [CustomerMessageHandler instance].appid = APPID;
            
            [IMHttpAPI instance].accessToken = token;
            [IMService instance].token = token;

            
            path = [self getDocumentPath];
            dbPath = [NSString stringWithFormat:@"%@/%lld", path, [tfSender.text longLongValue]];
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
            
            [[IMService instance] start];
            
            if (self.deviceToken.length > 0) {
                
                [IMHttpAPI bindDeviceToken:self.deviceToken
                                   success:^{
                                       NSLog(@"bind device token success");
                                   }
                                      fail:^{
                                          NSLog(@"bind device token fail");
                                      }];
            }
            
#ifdef TEST_PEER
            PeerMessageViewController *msgController = [[PeerMessageViewController alloc] init];
            msgController.currentUID = [tfSender.text longLongValue];
            msgController.peerUID = [tfReceiver.text longLongValue];
            msgController.peerName = @"测试";
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:msgController animated:YES];
#elif defined TEST_GROUP
            GroupMessageViewController *msgController = [[GroupMessageViewController alloc] init];
            msgController.currentUID = [tfSender.text longLongValue];
            msgController.groupID = [tfReceiver.text longLongValue];
            msgController.groupName = @"测试群";
            msgController.isShowUserName = YES;
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:msgController animated:YES];
#elif defined TEST_CUSTOMER
            CustomerMessageViewController *msgController = [[CustomerMessageViewController alloc] init];
            msgController.currentUID = [tfSender.text longLongValue];
            msgController.appid = APPID;
            msgController.peerUID = 0;
            msgController.peerAppID = 0;
            msgController.storeID = [tfReceiver.text longLongValue];
            msgController.name = @"测试用户";
            msgController.appName = @"demo";
            msgController.storeName = @"测试商店";
            msgController.peerName = @"";
            msgController.peerAppName = @"";
            msgController.isShowUserName = YES;
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:msgController animated:YES];
#elif defined TEST_ROOM
            RoomViewController *msgController = [[RoomViewController alloc] init];
            msgController.uid = [tfSender.text longLongValue];
            msgController.roomID = [tfReceiver.text longLongValue];
            
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:msgController animated:YES];
#endif
            
#if 0
            MessageListViewController *ctrl = [[MessageListViewController alloc] init];
            ctrl.currentUID = [tfSender.text longLongValue];
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:ctrl animated:YES];
#endif
        });
    });
}

-(NSString*)login:(long long)uid {
    //调用app自身的服务器获取连接im服务必须的access token
    NSString *url = @"http://demo.gobelieve.io/auth/token";
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];
    
    
    [urlRequest setHTTPMethod:@"POST"];
    
    NSDictionary *headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];

    [urlRequest setAllHTTPHeaderFields:headers];


    
#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
    NSLog(@"device id:%@", @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61");
#else
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"device id:%@", [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
#endif
    
    
    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    [obj setObject:[NSNumber numberWithLongLong:uid] forKey:@"uid"];
    [obj setObject:[NSString stringWithFormat:@"测试用户%lld", uid] forKey:@"user_name"];
    [obj setObject:[NSNumber numberWithInt:PLATFORM_IOS] forKey:@"platform_id"];
    [obj setObject:deviceID forKey:@"device_id"];
    
    NSData *postBody = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];

    [urlRequest setHTTPBody:postBody];

    NSURLResponse *response = nil;

    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"error:%@", error);
        return nil;
    }
    NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*)response;
    if (httpResp.statusCode != 200) {
        return nil;
    }
    NSDictionary *e = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    return [e objectForKey:@"token"];
}


- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController == self) {
        [[IMService instance] stop];
        
        if (self.deviceToken.length > 0) {
            
            [IMHttpAPI unbindDeviceToken:self.deviceToken
                            pushKitToken:@""
                               success:^{
                                   NSLog(@"unbind device token success");
                               }
                                  fail:^{
                                      NSLog(@"unbind device token fail");
                                  }];
        }
    }
}

@end
