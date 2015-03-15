//
//  MEESImageViewController.m
//  Message
//
//  Created by 杨朋亮 on 14/2/15.
//  Copyright (c) 2015年 daozhu. All rights reserved.
//

#import "MEESImageViewController.h"

#import "UIView+Toast.h"

#import <AssetsLibrary/AssetsLibrary.h>

@interface MEESImageViewController ()

@end

@implementation MEESImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if(self.isFullSize){
        
        self.saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        CGRect frame = CGRectMake(30, self.view.frame.size.height - 80, 30,30);
        [self.saveBtn setFrame:frame];
        [self.saveBtn addTarget:self action:@selector(saveImage:) forControlEvents:UIControlEventTouchUpInside];
        [self.saveBtn setBackgroundImage:[UIImage imageNamed:@"save"] forState:UIControlStateNormal];
        
        [self.view addSubview:self.saveBtn];
        
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (self.saveBtn) {
       [self.view bringSubviewToFront:self.saveBtn];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

 - (void) saveImage:(id)sender{
     
     ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
     if (status != ALAuthorizationStatusAuthorized) {
         //show alert for asking the user to give permission
        [self.view makeToast:@"请允许读取相册!可以到系统设置里修改" duration:0.9 position:@"center"];
        return;
     }
     //TODO 权限问题
     UIImageWriteToSavedPhotosAlbum(self.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
 }
 
 
 - (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
     
     //TODO 错误描述处理，相册权限处理
     if (error != NULL){
         [self.view makeToast:@"保存失败!" duration:0.9 position:@"center"];
     }else{
         [self.view makeToast:@"保存成功!" duration:0.9 position:@"center"];
     }
 }
 

@end
