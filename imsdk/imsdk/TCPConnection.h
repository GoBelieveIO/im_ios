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

//protect
@property(nonatomic)int port;
@property(nonatomic, assign)int heartbeatHZ;
@property(nonatomic)AsyncTCP *tcp;

//subclass override
-(void)sendPing;


-(BOOL)handleData:(NSData*)data;

-(void)onConnect;
-(void)onClose;



//protect method
-(void)ping;
-(void)pong;
-(void)reconnect2S;

//public method
-(void)start;
-(void)stop;

-(void)enterForeground;
-(void)enterBackground;

-(void)addConnectionObserver:(id<TCPConnectionObserver>)ob;
-(void)removeConnectionObserver:(id<TCPConnectionObserver>)ob;

-(void)startRechabilityNotifier;
@end
