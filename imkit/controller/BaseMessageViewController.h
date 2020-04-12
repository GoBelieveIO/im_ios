/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <UIKit/UIKit.h>
#import "IMService.h"
#import "IMessage.h"
#import "IMessageDB.h"
#import "Outbox.h"

//消息撤回的时限
#define REVOKE_EXPIRE 120

/*
 at对象的用户名问题
 本地显示的优先级 用户备注 > 群内昵称 > 用户名
 
 派生类实现
 - (void)checkAtName:(IMessage*)msg
 替换掉消息内容中的at对象的用户名
 
 派生类重载
 - (void)sendTextMessage:(NSString*)text at:(NSArray*)atUsers atNames:(NSArray*)atNames;
 将有可能是本地备注的用户名修改为群内昵称或用户名

 */
@protocol MessageViewControllerUserDelegate <NSObject>
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid;
//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb;
@end

//基类处理tableview相关的数据
@interface BaseMessageViewController : UIViewController

@property(nonatomic) id<IMessageDB> messageDB;

@property(nonatomic, assign) int64_t currentUID;
@property(nonatomic, assign) NSString *cid;

@property(nonatomic, assign) int messageID;//加载此消息id前后的消息
@property(nonatomic, assign) int64_t conversationID;

@property(nonatomic, weak) id<MessageViewControllerUserDelegate> userDelegate;

//protected
@property(nonatomic, assign) BOOL hasLateMore;
@property(nonatomic, assign) BOOL hasEarlierMore;
@property(nonatomic) NSMutableArray *messages;
@property(nonatomic) NSMutableDictionary *attachments;
@property(nonatomic) int lastReceivedTimestamp;

//protected overwrite by derived class
//从本地获取用户信息, IUser的name字段为空时，显示identifier字段
- (IUser*)getUser:(int64_t)uid;
//从服务器获取用户信息
- (void)asyncGetUser:(int64_t)uid cb:(void(^)(IUser*))cb;
- (void)sendMessage:(IMessage *)msg withImage:(UIImage*)image;
- (void)sendMessage:(IMessage*)message;
- (IMessage*)newOutMessage;

-(void)resendMessage:(IMessage*)message;
-(void)saveMessageAttachment:(IMessage*)msg address:(NSString*)address;
-(BOOL)saveMessage:(IMessage*)msg;
-(BOOL)removeMessage:(IMessage*)msg;
-(BOOL)markMessageFailure:(IMessage*)msg;
-(BOOL)markMesageListened:(IMessage*)msg;
-(BOOL)eraseMessageFailure:(IMessage*)msg;

- (void)loadData;
//返回新加载数据的最近一条消息的行号
- (int)loadEarlierData;
//返回新加载消息的条数
- (int)loadLateData;


//返回值表示是否添加了timebase
- (BOOL)insertMessage:(IMessage*)msg;
- (int)deleteMessage:(IMessage*)msg;
- (int)replaceMessage:(IMessage*)msg dest:(IMessage*)other;

- (void)downloadMessageContent:(IMessage*)message;
- (void)downloadMessageContent:(NSArray*)messages count:(int)count;

- (void)checkAtName:(IMessage*)msg;
- (void)checkAtName:(NSArray*)messages count:(int)count;

- (void)revokeMessage:(IMessage*)message;
- (void)sendTextMessage:(NSString*)text at:(NSArray*)atUsers atNames:(NSArray*)atNames;
- (void)sendImageMessage:(UIImage*)image;
- (void)sendAudioMessage:(NSString*)path second:(int)second;
- (void)sendLocationMessage:(CLLocationCoordinate2D)location address:(NSString*)address;
- (void)sendVideoMessage:(NSURL*)url;

- (void)loadSenderInfo:(IMessage*)msg;
- (void)loadSenderInfo:(NSArray*)messages count:(int)count;

- (void)updateNotificationDesc:(IMessage*)message;
- (void)updateNotificationDesc:(NSArray*)messages count:(int)count;

- (NSString*)localImageURL;
- (NSString*)localAudioURL;

- (IMessage*)getMessageWithID:(int)msgLocalID;
- (IMessage*)getMessageWithUUID:(NSString*)uuid;

- (IMessage*)messageForRowAtIndexPath:(NSIndexPath *)indexPath;

+ (void)playMessageReceivedSound;
+ (void)playMessageSentSound;

@end
