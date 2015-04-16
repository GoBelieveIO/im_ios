/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import "Message.h"

#define STATE_UNCONNECTED 0
#define STATE_CONNECTING 1
#define STATE_CONNECTED 2
#define STATE_CONNECTFAIL 3

@class IMessage;

@protocol IMPeerMessageHandler <NSObject>
-(BOOL)handleMessage:(IMMessage*)msg;
-(BOOL)handleMessageACK:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)handleMessageRemoteACK:(int)msgLocalID uid:(int64_t)uid;
-(BOOL)handleMessageFailure:(int)msgLocalID uid:(int64_t)uid;
@end

@protocol IMGroupMessageHandler <NSObject>

-(BOOL)handleMessage:(IMMessage*)msg;
-(BOOL)handleMessageACK:(int)msgLocalID gid:(int64_t)gid;
-(BOOL)handleMessageFailure:(int)msgLocalID gid:(int64_t)gid;

-(BOOL)handleGroupNotification:(NSString*)notification;

@end

@protocol IMConnectionObserver <NSObject>
@optional
//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state;

//用户在其他地方登陆
-(void)onLoginPoint:(LoginPoint*)lp;

@end

@protocol PeerMessageObserver <NSObject>
@optional
-(void)onPeerMessage:(IMMessage*)msg;

//服务器ack
-(void)onPeerMessageACK:(int)msgLocalID uid:(int64_t)uid;
//接受方ack
-(void)onPeerMessageRemoteACK:(int)msgLocalID uid:(int64_t)uid;

//消息发送失败
-(void)onPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid;

//对方正在输入
-(void)onPeerInputing:(int64_t)uid;

@end

@protocol GroupMessageObserver <NSObject>
@optional
-(void)onGroupMessage:(IMMessage*)msg;
-(void)onGroupMessageACK:(int)msgLocalID gid:(int64_t)gid;
-(void)onGroupMessageFailure:(int)msgLocalID gid:(int64_t)gid;

-(void)onGroupNotification:(NSString*)notification;
@end


@interface IMService : NSObject
@property(nonatomic, copy) NSString *host;
@property(nonatomic, copy) NSString *deviceID;
@property(nonatomic, copy) NSString *token;
@property(nonatomic, assign)int connectState;
@property(nonatomic, weak)id<IMPeerMessageHandler> peerMessageHandler;
@property(nonatomic, weak)id<IMGroupMessageHandler> groupMessageHandler;
+(IMService*)instance;

-(void)startRechabilityNotifier;

-(void)start;
-(void)stop;
-(void)enterForeground;
-(void)enterBackground;

-(BOOL)sendPeerMessage:(IMMessage*)msg;
-(BOOL)sendGroupMessage:(IMMessage*)msg;

//正在输入
-(void)sendInputing:(MessageInputing*)inputing;

-(void)addPeerMessageObserver:(id<PeerMessageObserver>)ob;
-(void)removePeerMessageObserver:(id<PeerMessageObserver>)ob;

-(void)addGroupMessageObserver:(id<GroupMessageObserver>)ob;
-(void)removeGroupMessageObserver:(id<GroupMessageObserver>)ob;

-(void)addConnectionObserver:(id<IMConnectionObserver>)ob;
-(void)removeConnectionObserver:(id<IMConnectionObserver>)ob;

@end

