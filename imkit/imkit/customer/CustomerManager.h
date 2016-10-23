/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

#ifndef CLEAR_CUSTOMER_NEW_MESSAGE
#define CLEAR_CUSTOMER_NEW_MESSAGE @"clear_customer_single_conv_new_message_notify"
#endif

/*
 错误码
 1000 网络错误
 */


//只有在打开客服聊天界面的情况下，才会建立一个socket的长链接来收发消息
//退出聊天界面后， 用apns来推送新消息的提醒，从而保证资源消耗的最优化
/* 应用没有用户系统
 * 1.app启动时
 * [[CustomerManager instance] initWithAppID:appID appKey:appKey]
 * if ([CustomerManager instance].clientID == 0) {
 *     [[CustomerManager instance] registerClient:name completion:^() {
 *           [[CustomerManager instance] login]
 *     }]
 * } else {
 *     [[CustomerManager instance] login]
 * }
 *
 * 应用有用户系统
 * 1.app启动时
 * [[CustomerManager instance] initWithAppID:appID appKey:appKey]
 *
 *
 * 2.用户登录后，使用用户的id和用户名称来注册顾客id
 * if ([CustomerManager instance].uid != 当前登录的用户id) {
 *     [[CustomerManager instance] registerClient:uid name:name avatar:avatar completion:^() {
 *           [[CustomerManager instance] login]
 *     }]
 * } else {
 *      [[CustomerManager instance] login]
 * }
 *
 *
 * 3.用户注销后
 * [[CustomerManager instance] unbindDeviceToken:^() {
 *      [CustomerManager instance] unregisterClient()
 * }]
 */
@interface CustomerManager : NSObject

+(CustomerManager*)instance;

@property(nonatomic, assign) int64_t appID;
@property(nonatomic, copy) NSString *appKey;
@property(nonatomic, copy) NSString *deviceID;

//顾客资料
@property(nonatomic, assign) int64_t clientID;
@property(nonatomic, copy) NSString *uid;//应用的用户ID
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatar;


//加载顾客资料
//开发者判断clientID是否为0，用来决定是否需要调用registerClient接口
-(void)initWithAppID:(int64_t)appID appKey:(NSString*)appKey deviceID:(NSString*)deviceID;

//name用户名,可以让顾客填写或者系统根据手机的某些信息自动生成
//创建一个新的顾客id,该顾客没有任何的历史纪录和用户信息
//如果注册失败是因为网络波动导致，开发者可尝试多次调用，从而提供注册的成功率
-(void)registerClient:(NSString*)name
           cmopletion:(void (^)(int64_t clientID, NSError *error))completion;

//应用自身的用户id和用户信息
//如果此uid之前未注册，会生成一个新的顾客id,否则返回之前注册获得的顾客id
//在用户登录之后调用
//如果注册失败是因为网络波动导致，开发者可尝试多次调用，从而提供注册的成功率
-(void)registerClient:(NSString*)uid name:(NSString*)name avatar:(NSString*)avatar
           cmopletion:(void (^)(int64_t clientID, NSError *error))completion;

//清空当前顾客的登录信息
-(void)unregisterClient;

//顾客登录
-(void)login;

//设置顾客信息
-(void)setClientName:(NSString*)name avatar:(NSString*)avatar;

//绑定推送的devicetoken
//在CLEAR_CUSTOMER_NEW_MESSAGE通知消息的处理函数中清空未读小红点的状态
//所有离线消息都会通过apns推送到客户端，
//客户端可以在AppDelegate的didReceiveRemoteNotification函数中设置未读小红点的状态
-(void)bindDeviceToken:(NSData*)deviceToken completion:(void (^)(NSError *error))completion;

//关闭离线消息的推送，新消息用户将得不到提醒
//同时app也将无法更新未读小红点的状态
//注销用户时调用，在回调中需要调用unregisterClient
-(void)unbindDeviceToken:(void (^)(NSError *error))completion;

//获取未读消息标志，在回调中保存未读小红点的状态
//此接口仅需在app启动和进入前台的时候调用
//在app进入前台调用此接口是为了避免在后台期间，系统在收到推送时没有唤醒app
-(void)getUnreadMessageWithCompletion:(void(^)(BOOL hasUnread, NSError* error))completion;

//打开客服聊天界面
//clientID必须有有效值(clientID > 0),否则不会打开任何界面
-(void)pushCustomerViewControllerInViewController:(UINavigationController*)controller title:(NSString*)title;
-(void)presentCustomerViewControllerInViewController;

@end
