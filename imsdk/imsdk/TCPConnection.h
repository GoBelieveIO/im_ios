//
//  TCPConnection.h
//  podcasting
//
//  Created by houxh on 15/6/25.
//  Copyright (c) 2015年 beetle. All rights reserved.
//

#import <Foundation/Foundation.h>

#define STATE_UNCONNECTED 0
#define STATE_CONNECTING 1
#define STATE_CONNECTED 2
#define STATE_CONNECTFAIL 3
#define STATE_AUTHENTICATION_FAIL 4

#define ENABLE_SSL

#define HOST  @"imnode2.gobelieve.io"
#ifdef ENABLE_SSL
#define PORT 24430
#else
#define PORT 23000
#endif

@protocol TCPConnectionObserver <NSObject>
@optional
//同IM服务器连接的状态变更通知
-(void)onConnectState:(int)state;

@end


@class AsyncTCP;
@interface TCPConnection : NSObject
//public
@property(nonatomic, assign)int connectState;
@property(nonatomic, copy) NSString *host;
@property(nonatomic)BOOL reachable;
@property(nonatomic, strong) dispatch_queue_t queue;

//protect
@property(nonatomic)int port;
@property(nonatomic, assign)int heartbeatHZ;
@property(nonatomic)AsyncTCP *tcp;
@property(nonatomic, assign)BOOL suspended;

//subclass override
-(BOOL)sendPing;


-(BOOL)handleData:(NSData*)data;

-(void)onConnect;
-(void)onClose;



//protect method
-(void)ping;
-(void)pong;

//认证失败，2s后重新连接
-(void)reconnect2S;

-(void)runOnMainThread:(dispatch_block_t)block;
-(void)runOnWorkQueue:(dispatch_block_t)block;
-(void)assertWorkQueue;

//public method
-(void)start;
-(void)stop;

-(void)enterForeground;
-(void)enterBackground;

-(void)addConnectionObserver:(id<TCPConnectionObserver>)ob;
-(void)removeConnectionObserver:(id<TCPConnectionObserver>)ob;

-(void)onReachabilityChange:(BOOL)reachable;
@end
