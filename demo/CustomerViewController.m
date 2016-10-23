//
//  CustomerViewController.m
//  im_demo
//
//  Created by houxh on 16/10/22.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "CustomerViewController.h"

#import "CustomerManager.h"
#import "AppDelegate.h"

@interface CustomerViewController ()

@property(nonatomic, weak)UITextField *tfSender;
@property(nonatomic, weak)UITextField *tfName;
@property(nonatomic, weak)UIButton *chatButton;

@property(nonatomic, weak) UILabel *unreadLabel;

@property(nonatomic, weak) UIView *loginedView;
@property(nonatomic, weak) UIView *loginView;

@end

@implementation CustomerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    self.title = @"Demo";
    
    UIView *loginedView = [[UIView alloc] initWithFrame:self.view.bounds];
    float startHeight = [[UIScreen mainScreen] bounds].size.height >= 568.0 ? 100 : 100;
    CGRect frame = CGRectMake(15, startHeight + 12, self.view.frame.size.width - 30, 36);
    UILabel *unread = [[UILabel alloc] initWithFrame:frame];
    unread.textAlignment = NSTextAlignmentCenter;
    unread.text = @"没有未读消息";
    unread.textColor = [UIColor blackColor];
    [loginedView addSubview:unread];
    
    startHeight += 45;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(15, startHeight, self.view.frame.size.width - 30, 48);
    [btn setTitle:@"客服" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"btn_blue"] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17];
    [btn addTarget:self action:@selector(actionChat) forControlEvents:UIControlEventTouchUpInside];
    [loginedView addSubview:btn];
    
    [self.view addSubview:loginedView];
    
    startHeight += 64;
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(15, startHeight, self.view.frame.size.width - 30, 48);
    [btn setTitle:@"注销" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"btn_blue"] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17];
    [btn addTarget:self action:@selector(actionLogout) forControlEvents:UIControlEventTouchUpInside];
    [loginedView addSubview:btn];
    
    [self.view addSubview:loginedView];
    
    self.unreadLabel = unread;
    self.loginedView = loginedView;
    
    
    UIView *loginView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    bgImageView.image = [UIImage imageNamed:@"bg"];
    [loginView addSubview:bgImageView];
    
    startHeight = [[UIScreen mainScreen] bounds].size.height >= 568.0 ? 100 : 100;
    UIImageView *headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, startHeight + 12, 17, 21)];
    headerImageView.image = [UIImage imageNamed:@"ic_man"];
    [loginView addSubview:headerImageView];
    
    UITextField *tfSender = [[UITextField alloc] initWithFrame:CGRectMake(52, startHeight + 4, 180, 37)];
    
    self.tfSender = tfSender;
    self.tfSender.textColor = [UIColor whiteColor];
    self.tfSender.font = [UIFont systemFontOfSize:18];
    self.tfSender.placeholder = @"用户id";
    self.tfSender.keyboardType = UIKeyboardTypeNumberPad;
    [loginView addSubview:self.tfSender];
    
    UIView *whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
    whiteLine.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:0.4];
    [loginView addSubview:whiteLine];
    
    startHeight += 45;
    headerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, startHeight + 12, 17, 21)];
    headerImageView.image = [UIImage imageNamed:@"ic_man"];
    [loginView addSubview:headerImageView];
    
    UITextField *tfName = [[UITextField alloc] initWithFrame:CGRectMake(52, startHeight + 4, 180, 37)];
    tfName.textColor = [UIColor whiteColor];
    tfName.font = [UIFont systemFontOfSize:18];
    tfName.placeholder = @"用户名";
    tfName.keyboardType = UIKeyboardTypeDefault;
    [loginView addSubview:tfName];
    self.tfName = tfName;
    
    
    whiteLine = [[UIView alloc] initWithFrame:CGRectMake(15, startHeight + 45, 290, 1)];
    whiteLine.backgroundColor = [UIColor colorWithRed:255 / 255.0 green:255 / 255.0 blue:255 / 255.0 alpha:0.4];
    [loginView addSubview:whiteLine];
    startHeight += 45 + ([[UIScreen mainScreen] bounds].size.height >= 568.0 ? 20 : 15);
    
    btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(15, startHeight, self.view.frame.size.width - 30, 48);
    [btn setTitle:@"登录" forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"btn_blue"] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:17];
    [btn addTarget:self action:@selector(actionLogin) forControlEvents:UIControlEventTouchUpInside];
    [loginView addSubview:btn];
    
    [self.view addSubview:loginView];
    self.loginView = loginView;
    
    self.chatButton = btn;
    
    self.loginView.hidden = NO;
    self.loginedView.hidden = YES;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(clearNewState) name:CLEAR_CUSTOMER_NEW_MESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessage:) name:@"new_message" object:nil];
}

- (void)appWillEnterForeground:(NSNotification*)notification {
    [[CustomerManager instance] getUnreadMessageWithCompletion:^(BOOL hasUnread, NSError *error) {
        if (error) {
            NSLog(@"get unread message fail");
        } else {
            if (hasUnread) {
                self.unreadLabel.text = @"新消息";
                self.unreadLabel.textColor = [UIColor redColor];
            } else {
                self.unreadLabel.text = @"没有未读消息";
                self.unreadLabel.textColor = [UIColor blackColor];
            }
        }
    }];
}

- (void)newMessage:(id)userInfo {
    NSLog(@"new message");
    self.unreadLabel.text = @"新消息";
    self.unreadLabel.textColor = [UIColor redColor];
}


- (void)clearNewState {
    self.unreadLabel.text = @"没有未读消息";
    self.unreadLabel.textColor = [UIColor blackColor];
}


- (void)actionChat {
    if ([CustomerManager instance].clientID == 0) {
        return;
    }
    [[CustomerManager instance] pushCustomerViewControllerInViewController:self.navigationController title:@"客服"];
}

- (void)actionLogout {
    [[CustomerManager instance] unbindDeviceToken:^(NSError *error) {
        //unbind失败，
        //忽略此错误,则会导致注销后还会收到apns推送消息
        if (error) {
            NSLog(@"unbind device token fail");
            return;
        }
        
        [[CustomerManager instance] unregisterClient];
        
        self.loginView.hidden = NO;
        self.loginedView.hidden = YES;
    }];
}
- (void)actionLogin {
    if (!self.tfSender.text.length || !self.tfName.text.length) {
        NSLog(@"invalid input");
        return;
    }
    [self.view endEditing:YES];
    
    NSString *uid = self.tfSender.text;
    NSString *name = self.tfName.text;
    

    if ([CustomerManager instance].clientID > 0 &&
        [[CustomerManager instance].uid isEqualToString:uid]) {
        //顾客已经注册,此处只要做登录动作
        NSLog(@"register client id:%lld", [CustomerManager instance].clientID);

        if ([AppDelegate instance].deviceToken.length > 0) {
            [[CustomerManager instance] bindDeviceToken:[AppDelegate instance].deviceToken
                                             completion:^(NSError *error) {
                                                 if (error) {
                                                     NSLog(@"bind device token fail");
                                                 } else {
                                                     NSLog(@"bind device token success");
                                                 }
                                             }];
        }

        [[CustomerManager instance] login];
        self.loginView.hidden = YES;
        self.loginedView.hidden = NO;
        return;
    }

    [[CustomerManager instance] registerClient:uid name:name avatar:@""
                                    cmopletion:^(int64_t clientID, NSError *error) {
                                        if (error) {
                                            NSLog(@"register client error:%@", error);
                                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                                                message:@"注册顾客id失败"
                                                                                               delegate:self
                                                                                      cancelButtonTitle:@"取消"
                                                                                      otherButtonTitles:@"确定", nil];
                                            [alertView show];
                                            return;
                                        }
                                        
                                        NSLog(@"register client id:%lld", clientID);
                                        self.loginView.hidden = YES;
                                        self.loginedView.hidden = NO;
                                        
                                        if ([AppDelegate instance].deviceToken.length > 0) {
                                            [[CustomerManager instance] bindDeviceToken:[AppDelegate instance].deviceToken
                                                                             completion:^(NSError *error) {
                                                                                 if (error) {
                                                                                     NSLog(@"bind device token fail");
                                                                                 } else {
                                                                                     NSLog(@"bind device token success");
                                                                                 }
                                                                             }];
                                        }
                                        
                                        [[CustomerManager instance] login];
                                        
    }];
}



@end
