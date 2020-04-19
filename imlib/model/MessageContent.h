/*
 Copyright (c) 2014-2015, GoBelieve
 All rights reserved.
 
 This source code is licensed under the BSD-style license found in the
 LICENSE file in the root directory of this source tree. An additional grant
 of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

//消息类型
#define MESSAGE_UNKNOWN 0
#define MESSAGE_TEXT 1
#define MESSAGE_IMAGE 2
#define MESSAGE_AUDIO 3
#define MESSAGE_LOCATION 4
#define MESSAGE_GROUP_NOTIFICATION 5 //群通知
#define MESSAGE_LINK 6
#define MESSAGE_HEADLINE 7  //客服的标题
#define MESSAGE_VOIP 8
#define MESSAGE_GROUP_VOIP 9
#define MESSAGE_P2P_SESSION 10
#define MESSAGE_SECRET 11
#define MESSAGE_VIDEO 12
#define MESSAGE_FILE 13
#define MESSAGE_REVOKE 14
#define MESSAGE_ACK 15
#define MESSAGE_CLASSROOM 16 //群课堂

#define MESSAGE_TIME_BASE  254 //虚拟的消息，不会存入磁盘
#define MESSAGE_ATTACHMENT 255 //消息附件， 只存在本地磁盘

@interface MessageContent : NSObject
@property(nonatomic, copy) NSString *raw;
@property(nonatomic, readonly) NSString *uuid;
@property(nonatomic, readonly) int type;

//protected
@property(nonatomic)NSDictionary *dict;

- (id)initWithRaw:(NSString*)raw;
@end
