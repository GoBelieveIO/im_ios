#import "ApplicationCustomerMessageViewController.h"
#import "IMService.h"
#import "CustomerMessageHandler.h"


@interface ApplicationCustomerMessageViewController()


@end
@implementation ApplicationCustomerMessageViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];

    [[IMService instance] start];
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
