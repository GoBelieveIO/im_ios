//
//  IMService.h
//  im
//
//  Created by houxh on 14-6-26.
//  Copyright (c) 2014年 potato. All rights reserved.
//

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

@protocol MessageObserver <NSObject>

@optional
-(void)onPeerMessage:(IMMessage*)msg;

//服务器ack
-(void)onPeerMessageACK:(int)msgLocalID uid:(int64_t)uid;
//接受方ack
-(void)onPeerMessageRemoteACK:(int)msgLocalID uid:(int64_t)uid;

-(void)onPeerMessageFailure:(int)msgLocalID uid:(int64_t)uid;

//对方正在输入
-(void)onPeerInputing:(int64_t)uid;

//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state;

@optional
-(void)onGroupMessage:(IMMessage*)msg;
-(void)onGroupMessageACK:(int)msgLocalID gid:(int64_t)gid;
-(void)onGroupMessageFailure:(int)msgLocalID gid:(int64_t)gid;


-(void)onGroupNotification:(NSString*)notification;

@end

@interface IMService : NSObject
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

-(void)addMessageObserver:(id<MessageObserver>)ob;
-(void)removeMessageObserver:(id<MessageObserver>)ob;
@end

