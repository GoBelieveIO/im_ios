/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import "AppDelegate.h"
#import "MainViewController.h"
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
#import "GOReachability.h"

@interface AppDelegate ()
@property(nonatomic) MainViewController *mainViewController;
@property(nonatomic) GOReachability *reach;
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
    [IMHttpAPI instance].apiURL = @"https://api.gobelieve.io/v2";
    [IMService instance].host = @"imnode2.gobelieve.io";

  
#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"7C8A8F5B-E5F4-4797-8758-05367D2A4D61";
#else
    NSString *deviceID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
#endif
    [IMService instance].deviceID = deviceID;
    NSLog(@"device id:%@", deviceID);
    
    [IMService instance].peerMessageHandler = [PeerMessageHandler instance];
    [IMService instance].groupMessageHandler = [GroupMessageHandler instance];
    [IMService instance].customerMessageHandler = [CustomerMessageHandler instance];
    [self startRechabilityNotifier];
    [IMService instance].reachable = [self.reach isReachable];
    
    dispatch_queue_t queue = dispatch_queue_create("com.beetle.im", DISPATCH_QUEUE_SERIAL);
    [IMService instance].queue = queue;
    
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    MainViewController *mainViewController = [[MainViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    self.mainViewController = mainViewController;

    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert
                                                                                         | UIUserNotificationTypeBadge
                                                                                         | UIUserNotificationTypeSound) categories:nil];
    [application registerUserNotificationSettings:settings];

    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString* newToken = [deviceToken description];
    newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
  
    NSLog(@"device token is: %@:%@", deviceToken, newToken);
    
    self.deviceToken = deviceToken;
    self.mainViewController.deviceToken = newToken;
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
    [[IMService instance] enterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[IMService instance] enterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)startRechabilityNotifier {
    self.reach = [GOReachability reachabilityForInternetConnection];
    self.reach.reachableBlock = ^(GOReachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"internet reachable");
            [[IMService instance] onReachabilityChange:YES];
        });
    };
    
    self.reach.unreachableBlock = ^(GOReachability*reach) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"internet unreachable");
            [[IMService instance] onReachabilityChange:NO];
        });
    };
    
    [self.reach startNotifier];

}


@end
