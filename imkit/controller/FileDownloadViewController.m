//
//  FileViewController.m
//  gobelieve
//
//  Created by houxh on 2018/5/27.
//

#import "FileDownloadViewController.h"
#import "FileCache.h"
#import "TAHttpOperation.h"
#import "UIView+Toast.h"
#import "AudioDownloader.h"
#import <Masonry/Masonry.h>

@interface FileDownloadViewController ()
@property(nonatomic) NSMutableData *responseData;
@property(nonatomic) UIProgressView *progressView;
@property(nonatomic) long long contentLength;
@end

@implementation FileDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentLength = -1;
    self.responseData = [NSMutableData data];

    self.progressView = [[UIProgressView alloc] init];
    [self.view addSubview:self.progressView];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self.progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view);
        make.height.mas_equalTo(8);
        make.left.equalTo(self.view.mas_left).offset(32);
        make.right.equalTo(self.view.mas_right).offset(-32);
    }];
    
    [self downloadURL:self.url];
}
-(void)downloadURL:(NSString*)url{

    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60];
    

    
    
    [urlRequest setHTTPMethod:@"GET"];
    

    NSURLConnection *urlConnection = [[NSURLConnection alloc]initWithRequest:urlRequest
                                                   delegate:self
                                           startImmediately:NO];

        
    [urlConnection start];

}

#pragma mark -
#pragma mark NSURLConnection相关代理在 TACommHttp 中的实现
- (void)connection:(NSURLConnection*)connection
didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"response header:%@ %lld", response, [response expectedContentLength]);
    self.contentLength = [response expectedContentLength];
    if (self.contentLength == -1 && self.size > 0) {
        self.contentLength = self.size;
    }
}


-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data{
    [self.responseData appendData:data];
    if (self.contentLength > 0) {
        float progress = (self.responseData.length*1.0)/(self.contentLength*1.0);
        self.progressView.progress = progress;
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    self.progressView.progress = 1.0;
    NSData *data = self.responseData;
    NSData *fileData = data;
    
    FileCache *cache = [FileCache instance];
    [cache storeFile:fileData forKey:self.url];
    
    [self.delegate fileDownloadSuccess:self.url message:self.message];
    NSLog(@"did finish loading");

}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error{
    [self.view makeToast:@"下载失败"];
    NSLog(@"url connection error:%@", error);
}




@end
