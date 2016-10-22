#import "ApplicationCustomerMessageViewController.h"
#import "IMService.h"
#import "CustomerMessageHandler.h"


@interface ApplicationCustomerMessageViewController()


@end
@implementation ApplicationCustomerMessageViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    if (self.token.length == 0) {
        return;
    }
    
    [IMService instance].customerMessageHandler = [CustomerMessageHandler instance];
    [IMService instance].uid = self.currentUID;
    [IMService instance].token = self.token;
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
