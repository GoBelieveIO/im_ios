/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/
#import <imsdk/IMService.h>
#import <imkit/IMHttpAPI.h>
#import <imkit/MessageDB.h>
#import <imkit/PeerMessageDB.h>
#import <imkit/GroupMessageDB.h>
#import <imkit/CustomerMessageDB.h>
#import "CustomerLoginViewController.h"
#import "CustomerMessageListViewController.h"

@interface CustomerLoginViewController ()<MessageViewControllerUserDelegate>
    {
    UITextField *tfSender;
}

@property(nonatomic, weak)UIButton *chatButton;
@end


@implementation CustomerLoginViewController

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
    tfSender.placeholder = @"客服id";
    tfSender.keyboardType = UIKeyboardTypeNumberPad;
    [self.view addSubview:tfSender];
    
    UIView *whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
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

- (void)actionChat {
    if (!tfSender.text.length) {
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
            NSString *dbPath = [NSString stringWithFormat:@"%@/%lld", path, [tfSender.text longLongValue]];
            [PeerMessageDB instance].dbPath = [NSString stringWithFormat:@"%@/peer", dbPath];
            [GroupMessageDB instance].dbPath = [NSString stringWithFormat:@"%@/group", dbPath];
            [CustomerMessageDB instance].dbPath = [NSString stringWithFormat:@"%@/customer", dbPath];
            
            [IMHttpAPI instance].accessToken = token;
            [IMService instance].token = token;
            [IMService instance].uid = [tfSender.text longLongValue];
            
            [[IMService instance] start];
  
            CustomerMessageListViewController *ctrl = [[CustomerMessageListViewController alloc] init];
            ctrl.currentUID = [tfSender.text longLongValue];
            ctrl.userDelegate = self;
            
            self.navigationController.navigationBarHidden = NO;
            [self.navigationController pushViewController:ctrl animated:YES];
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


    NSMutableDictionary *obj = [NSMutableDictionary dictionary];
    [obj setObject:[NSNumber numberWithLongLong:uid] forKey:@"uid"];
    [obj setObject:[NSString stringWithFormat:@"测试用户%lld", uid] forKey:@"user_name"];
    
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
    }
}

#pragma mark - MessageViewControllerUserDelegate
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid {
    IUser *u = [[IUser alloc] init];
    u.uid = uid;
    u.name = @"";
    u.avatarURL = @"http://api.gobelieve.io/images/e837c4c84f706a7988d43d62d190e2a1.png";
    u.identifier = [NSString stringWithFormat:@"uid:%lld", uid];
    return u;
}
//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        IUser *u = [[IUser alloc] init];
        u.uid = uid;
        u.name = [NSString stringWithFormat:@"name:%lld", uid];
        u.avatarURL = @"http://api.gobelieve.io/images/e837c4c84f706a7988d43d62d190e2a1.png";
        u.identifier = [NSString stringWithFormat:@"uid:%lld", uid];
        dispatch_async(dispatch_get_main_queue(), ^{
            cb(u);
        });
    });
}
@end
