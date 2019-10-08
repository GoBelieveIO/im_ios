/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import "Message.h"
#import "TCPConnection.h"


@protocol IMPeerMessageHandler <NSObject>
-(BOOL)handleMessage:(IMMessage*)msg;
-(BOOL)handleMessageACK:(IMMessage*)msg error:(int)error;
-(BOOL)handleMessageFailure:(IMMessage*)msg;
@end

@protocol IMGroupMessageHandler <NSObject>
-(BOOL)handleMessages:(NSArray*)msgs;
-(BOOL)handleMessageACK:(IMMessage*)msg error:(int)error;
-(BOOL)handleMessageFailure:(IMMessage*)msg;
@end

@protocol IMCustomerMessageHandler <NSObject>
-(BOOL)handleCustomerSupportMessage:(CustomerMessage*)msg;
-(BOOL)handleMessage:(CustomerMessage*)msg;
-(BOOL)handleMessageACK:(CustomerMessage*)msg;
-(BOOL)handleMessageFailure:(CustomerMessage*)msg;
@end

//保存消息的同步key
@protocol IMSyncKeyHandler <NSObject>
-(BOOL)saveSyncKey:(int64_t)syncKey;
-(BOOL)saveGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid;
@end

@protocol PeerMessageObserver <NSObject>
@optional
-(void)onPeerMessage:(IMMessage*)msg;
-(void)onPeerSecretMessage:(IMMessage*)msg;
//服务器ack
-(void)onPeerMessageACK:(IMMessage*)msg error:(int)error;
//消息发送失败
-(void)onPeerMessageFailure:(IMMessage*)msg;

@end

@protocol GroupMessageObserver <NSObject>
@optional
-(void)onGroupMessages:(NSArray*)msgs;
-(void)onGroupMessageACK:(IMMessage*)msg error:(int)error;
-(void)onGroupMessageFailure:(IMMessage*)msg;
@end

@protocol RoomMessageObserver <NSObject>
@optional
-(void)onRoomMessage:(RoomMessage*)rm;

@end

@protocol RTMessageObserver <NSObject>

@optional
-(void)onRTMessage:(RTMessage*)rt;

@end

@protocol SystemMessageObserver <NSObject>
@optional
-(void)onSystemMessage:(NSString*)sm;

@end

@protocol CustomerMessageObserver <NSObject>
@optional
-(void)onCustomerMessage:(CustomerMessage*)msg;
-(void)onCustomerSupportMessage:(CustomerMessage*)msg;

//服务器ack
-(void)onCustomerMessageACK:(CustomerMessage*)msg;
//消息发送失败
-(void)onCustomerMessageFailure:(CustomerMessage*)msg;
@end


/*消息如何接收
 *1.初始化消息的同步key和所有超级群的同步key
 *2.上线之后，自动同步所有离线消息
 *3.收到同步消息的通知后，同步新消息
*/
__attribute__((objc_runtime_name("GoBelieveIMService")))
@interface IMService : TCPConnection
@property(nonatomic, copy) NSString *deviceID;
@property(nonatomic, copy) NSString *token;
//客服app需要设置，普通app不需要设置
@property(nonatomic) int64_t appID;

//离线消息的同步key
@property(nonatomic) int64_t syncKey;

@property(nonatomic, weak)id<IMPeerMessageHandler> peerMessageHandler;
@property(nonatomic, weak)id<IMGroupMessageHandler> groupMessageHandler;
@property(nonatomic, weak)id<IMCustomerMessageHandler> customerMessageHandler;
@property(nonatomic, strong)id<IMSyncKeyHandler> syncKeyHandler;

+(IMService*)instance;

//超级群消息的同步key
-(void)addSuperGroupSyncKey:(int64_t)syncKey gid:(int64_t)gid;
-(void)removeSuperGroupSyncKey:(int64_t)gid;
-(void)clearSuperGroupSyncKey;


-(void)sendPeerMessageAsync:(IMMessage*)msg;
-(void)sendGroupMessageAsync:(IMMessage*)msg;
-(void)sendRoomMessageAsync:(RoomMessage*)msg;
//顾客->客服
-(void)sendCustomerMessageAsync:(CustomerMessage*)im;
//客服->顾客
-(void)sendCustomerSupportMessageAsync:(CustomerMessage*)im;
-(void)sendRTMessageAsync:(RTMessage*)msg;

-(BOOL)sendPeerMessage:(IMMessage*)msg;
-(BOOL)sendGroupMessage:(IMMessage*)msg;
-(BOOL)sendRoomMessage:(RoomMessage*)msg;
//顾客->客服
-(BOOL)sendCustomerMessage:(CustomerMessage*)im;
//客服->顾客
-(BOOL)sendCustomerSupportMessage:(CustomerMessage*)im;
-(BOOL)sendRTMessage:(RTMessage*)msg;

-(void)enterRoom:(int64_t)roomID;
-(void)leaveRoom:(int64_t)roomID;

//更新未读的消息数目
-(void)sendUnreadCount:(int)unread;

-(void)addPeerMessageObserver:(id<PeerMessageObserver>)ob;
-(void)removePeerMessageObserver:(id<PeerMessageObserver>)ob;

-(void)addGroupMessageObserver:(id<GroupMessageObserver>)ob;
-(void)removeGroupMessageObserver:(id<GroupMessageObserver>)ob;

-(void)addRoomMessageObserver:(id<RoomMessageObserver>)ob;
-(void)removeRoomMessageObserver:(id<RoomMessageObserver>)ob;

-(void)addSystemMessageObserver:(id<SystemMessageObserver>)ob;
-(void)removeSystemMessageObserver:(id<SystemMessageObserver>)ob;

-(void)addCustomerMessageObserver:(id<CustomerMessageObserver>)ob;
-(void)removeCustomerMessageObserver:(id<CustomerMessageObserver>)ob;

-(void)addRTMessageObserver:(id<RTMessageObserver>)ob;
-(void)removeRTMessageObserver:(id<RTMessageObserver>)ob;

@end

