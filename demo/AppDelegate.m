/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "AppDelegate.h"
#ifdef TEST_ROOM
#import "RoomLoginViewController.h"
#elif defined TEST_GROUP
#import "GroupLoginViewController.h"
#elif defined TEST_CUSTOMER
#import "CustomerViewController.h"
#import "CustomerManager.h"
#else
#import "MainViewController.h"
#endif

#import <gobelieve/IMService.h>
#import <gobelieve/PeerMessageHandler.h>
#import <gobelieve/GroupMessageHandler.h>
#import <gobelieve/CustomerMessageHandler.h>
#import <gobelieve/CustomerMessageDB.h>
#import <gobelieve/CustomerOutbox.h>
#import <gobelieve/IMHttpAPI.H>

#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>


@interface AppDelegate ()

#ifdef TEST_ROOM

#elif defined TEST_GROUP
@property(nonatomic) GroupLoginViewController *mainViewController;
#elif defined TEST_CUSTOMER

#else
@property(nonatomic) MainViewController *mainViewController;
#endif

@end

@implementation AppDelegate
+(AppDelegate*)instance {
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

-(NSString*)getDocumentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"remote notification:%@", [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]);

    //app可以单独部署服务器，给予第三方应用更多的灵活性
    [IMHttpAPI instance].apiURL = @"http://api.gobelieve.io";
    [IMService instance].host = @"imnode2.gobelieve.io";
    
  
#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
    [IMService instance].deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
    NSLog(@"device id:%@", @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61");
#else
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [IMService instance].deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSLog(@"device id:%@", [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
#endif

    [IMService instance].peerMessageHandler = [PeerMessageHandler instance];
    [IMService instance].groupMessageHandler = [GroupMessageHandler instance];
    [IMService instance].customerMessageHandler = [CustomerMessageHandler instance];
    [[IMService instance] startRechabilityNotifier];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
#ifdef TEST_ROOM
    RoomLoginViewController *mainViewController = [[RoomLoginViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
#elif defined TEST_GROUP
    GroupLoginViewController *mainViewController = [[GroupLoginViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    self.mainViewController = mainViewController;
#elif defined TEST_CUSTOMER
    
    [[CustomerManager instance] initWithAppID:7 appKey:@"sVDIlIiDUm7tWPYWhi6kfNbrqui3ez44" deviceID:deviceID];
    CustomerViewController *mainViewController = [[CustomerViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
#else
    MainViewController *mainViewController = [[MainViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    self.mainViewController = mainViewController;
#endif

    
#ifdef __IPHONE_8_0
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {

        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert
                                                                                             | UIUserNotificationTypeBadge
                                                                                             | UIUserNotificationTypeSound) categories:nil];
        [application registerUserNotificationSettings:settings];

    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
#else
    UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
    [application registerForRemoteNotificationTypes:myTypes];
#endif
    
    [self refreshHost];
    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
  
    NSLog(@"device token is: %@:%@", deviceToken, newToken);
    
    self.deviceToken = deviceToken;
    
#ifdef TEST_ROOM

#elif defined TEST_GROUP
    self.mainViewController.deviceToken = newToken;
#elif defined TEST_CUSTOMER
    if ([CustomerManager instance].clientID > 0) {
        [[CustomerManager instance] bindDeviceToken:deviceToken  completion:^(NSError *error) {
            if (error) {
                NSLog(@"bind device token fail");
            } else {
                NSLog(@"bind device token success");
            }
        }];
    }
#else
    self.mainViewController.deviceToken = newToken;
#endif
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"register remote notification error:%@", error);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"did receive remote notification1:%@", userInfo);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    if (notificationSettings.types != UIUserNotificationTypeNone) {
        NSLog(@"didRegisterUser");
        [application registerForRemoteNotifications];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    NSLog(@"did receive remote notification2:%@", userInfo);
    if ([[[userInfo objectForKey:@"xiaowei"] objectForKey:@"new"] intValue] == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"new_message" object:nil userInfo:userInfo];
    }
    //Success
    handler(UIBackgroundFetchResultNewData);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    [[IMService instance] enterBackground];
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    [[IMService instance] enterForeground];

    [self refreshHost];
}



- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(void)refreshHost {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSLog(@"refresh host ip...");
        
        for (int i = 0; i < 10; i++) {
            NSString *host = @"imnode.gobelieve.io";
            NSString *ip = [self resolveIP:host];
            
            NSString *apiHost = @"api.gobelieve.io";
            NSString *apiIP = [self resolveIP:apiHost];
            
            
            NSLog(@"host:%@ ip:%@", host, ip);
            NSLog(@"api host:%@ ip:%@", apiHost, apiIP);
            
            if (ip.length == 0 || apiIP.length == 0) {
                continue;
            } else {
                break;
            }
        }
    });
}

-(NSString*)IP2String:(struct in_addr)addr {
    char buf[64] = {0};
    const char *p = inet_ntop(AF_INET, &addr, buf, 64);
    if (p) {
        return [NSString stringWithUTF8String:p];
    }
    return nil;
    
}

-(NSString*)resolveIP:(NSString*)host {
    struct addrinfo hints;
    struct addrinfo *result, *rp;
    int s;
    
    char buf[32];
    snprintf(buf, 32, "%d", 0);
    
    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = 0;
    
    s = getaddrinfo([host UTF8String], buf, &hints, &result);
    if (s != 0) {
        NSLog(@"get addr info error:%s", gai_strerror(s));
        return nil;
    }
    NSString *ip = nil;
    rp = result;
    if (rp != NULL) {
        struct sockaddr_in *addr = (struct sockaddr_in*)rp->ai_addr;
        ip = [self IP2String:addr->sin_addr];
    }
    freeaddrinfo(result);
    return ip;
}

@end
