//
//  CustomerMessageViewController.h
//  imkit
//
//  Created by houxh on 16/1/19.
//  Copyright © 2016年 beetle. All rights reserved.
//

#import "MessageViewController.h"

//最近发出的消息
#define LATEST_CUSTOMER_MESSAGE        @"latest_customer_message"

//清空会话的未读消息数
#define CLEAR_CUSTOMER_NEW_MESSAGE @"clear_customer_single_conv_new_message_notify"

@interface CustomerMessageViewController : MessageViewController<TCPConnectionObserver>

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, copy) NSString *peerName;

@property(nonatomic, assign) int64_t storeID;
@property(nonatomic, assign) int64_t sellerID;
@property(nonatomic, assign) int64_t appID;


//protect
- (void)onBack;

-(BOOL)saveMessage:(IMessage*)msg;

@end
