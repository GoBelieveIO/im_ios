//
//  CustomerMessageListViewController.h
//  im_demo
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol MessageViewControllerUserDelegate;

@interface CustomerMessageListViewController : UIViewController
@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, weak) id<MessageViewControllerUserDelegate> userDelegate;

@end
