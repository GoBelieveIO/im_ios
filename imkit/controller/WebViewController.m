//
//  WebViewController.m
//  imkit
//
//  Created by houxh on 15/11/19.
//  Copyright © 2015年 beetle. All rights reserved.
//

#import "WebViewController.h"
#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>

// https://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
@interface WebWeakWebViewScriptMessageDelegate : NSObject<WKScriptMessageHandler>


@property (nonatomic, weak) id<WKScriptMessageHandler> scriptDelegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate;

@end
@implementation WebWeakWebViewScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptDelegate {
    self = [super init];
    if (self) {
        _scriptDelegate = scriptDelegate;
    }
    return self;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.scriptDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end

@interface WebViewController ()<WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>

@property(nonatomic) WKWebView *webView;
@property(nonatomic) UIProgressView *progressView;
@end

@implementation WebViewController

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.title;
    
    WKWebView *webView = [self createWebView];
    [self.view addSubview:webView];
    self.webView = webView;
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.view addSubview:self.progressView];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        }
        make.width.equalTo(self.view);
        make.height.mas_equalTo(4);
    }];
    
    [self.webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
}

-(WKWebView*)createWebView {
    NSURL *url =[NSURL URLWithString:self.url];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    
    WKPreferences *preference = [[WKPreferences alloc] init];
    preference.javaScriptEnabled = YES;

    WKUserContentController * wkUController = [[WKUserContentController alloc] init];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = preference;
    config.userContentController = wkUController;

    if (self.noCache) {
        if (@available(iOS 9.0, *)) {
            config.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
        }
    }
    
    CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    WKWebView *webView = [[WKWebView alloc] initWithFrame:rect configuration:config];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    [webView loadRequest:urlRequest];
    return webView;
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    NSLog(@"page navigation finished");
    if ([self.webView canGoBack]) {
        if (!self.navigationItem.leftBarButtonItem) {
            UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav_back_press"]
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(goBack)];
            self.navigationItem.leftBarButtonItem = backItem;
        }
    } else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"page navigation err:%@", error);
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"Received event %@:%@", message.name, message.body);
}


- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    [self presentViewController:alertController animated:YES completion:^{}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        
        if(self.webView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


-(void)returnFunction:(NSNumber*)callbackId result:(NSDictionary*)result {
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSString *exec_template = @"window.app.returnFunction(%@, %@);";
    NSString *exec = [NSString stringWithFormat:exec_template, callbackId, s];
    [self.webView evaluateJavaScript:exec completionHandler:nil];
}

-(void)goBack {
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}
@end
