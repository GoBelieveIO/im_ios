/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

#import "IUser.h"
#import "MessageContent.h"
#import "MessageSecret.h"
#import "MessageNotification.h"
#import "MessageGroupNotification.h"
#import "MessageImage.h"
#import "MessageVOIP.h"
#import "MessageLocation.h"
#import "MessageAudio.h"
#import "MessageHeadline.h"
#import "MessageAttachment.h"
#import "MessageText.h"
#import "MessageLink.h"
#import "MessageGroupVOIP.h"
#import "MessageTimeBase.h"
#import "MessageP2PSession.h"
#import "MessageVideo.h"
#import "MessageFile.h"
#import "MessageRevoke.h"
#import "MessageACK.h"
#import "MessageClassroom.h"
#import "MessageConference.h"
#import "MessageReaded.h"
#import "MessageTag.h"

//消息标志
#define MESSAGE_FLAG_DELETE 0x01
#define MESSAGE_FLAG_ACK 0x02
//#define MESSAGE_FLAG_PEER_ACK 0x04
#define MESSAGE_FLAG_FAILURE 0x08
#define MESSAGE_FLAG_UPLOADING 0x10
#define MESSAGE_FLAG_SENDING 0x20
#define MESSAGE_FLAG_LISTENED 0x40
#define MESSAGE_FLAG_READED 0x80

@interface IMessage : NSObject <NSCopying>
+(MessageContent*)fromRawDict:(NSDictionary *)dict;
+(MessageContent*)fromRaw:(NSString*)raw;

@property(nonatomic) int64_t msgId;
@property(nonatomic) int flags;
@property(nonatomic) int64_t sender;
@property(nonatomic) int64_t receiver;
@property(nonatomic) BOOL secret;
@property(nonatomic) NSString *rawContent;
@property(nonatomic, readonly) int type;
@property(nonatomic) NSString *uuid;
@property(nonatomic) NSArray *tags;

//点对点消息特有字段
@property(nonatomic, assign) int64_t groupId;// 群内私聊消息&群消息已读

//群组消息特有字段
@property(nonatomic) int readerCount;//群组消息已读数量
@property(nonatomic) int receiverCount;//群组消息接收者数量，未存储到数据库
@property(nonatomic, copy) NSString *reference;//回复or引用消息的uuid
@property(nonatomic, assign) int referenceCount;//回复数量 or 被引用次数

@property(nonatomic) MessageContent *content;
@property(nonatomic, readonly) MessageTextContent *textContent;
@property(nonatomic, readonly) MessageAudioContent *audioContent;
@property(nonatomic, readonly) MessageImageContent *imageContent;
@property(nonatomic, readonly) MessageLocationContent *locationContent;
@property(nonatomic, readonly) MessageLinkContent *linkContent;
@property(nonatomic, readonly) MessageVOIPContent *voipContent;
@property(nonatomic, readonly) MessageGroupVOIPContent *groupVOIPContent;
@property(nonatomic, readonly) MessageTimeBaseContent *timeBaseContent;
@property(nonatomic, readonly) MessageNotificationContent *notificationContent;
@property(nonatomic, readonly) MessageGroupNotificationContent *groupNotificationContent;
@property(nonatomic, readonly) MessageP2PSession *p2pSessionContent;
@property(nonatomic, readonly) MessageSecret *secretContent;
@property(nonatomic, readonly) MessageVideo *videoContent;
@property(nonatomic, readonly) MessageFile *fileContent;
@property(nonatomic, readonly) MessageRevoke *revokeContent;
@property(nonatomic, readonly) MessageACK *ackContent;
@property(nonatomic, readonly) MessageClassroom *classroomContent;
@property(nonatomic, readonly) MessageConference *conferenceContent;
@property(nonatomic, readonly) MessageReaded *readedContent;
@property(nonatomic, readonly) MessageTag *tagContent;

@property(nonatomic, readonly) MessageAttachmentContent *attachmentContent;

@property(nonatomic) int timestamp;
@property(nonatomic, readonly) BOOL isACK;
@property(nonatomic, readonly) BOOL isFailure;
@property(nonatomic, readonly) BOOL isListened;
@property(nonatomic, readonly) BOOL isReaded;

//当前用户发出的消息
@property(nonatomic) BOOL isOutgoing;
@property(nonatomic, readonly) BOOL isIncomming;//!isOutgoing

//UI, kvo
@property(nonatomic) BOOL uploading;
@property(nonatomic) BOOL downloading;
@property(nonatomic) BOOL playing;
@property(nonatomic) int progress;//[0,100]
@property(nonatomic) BOOL geocoding;

@property(nonatomic) IUser *senderInfo;

-(void)generateRaw;

-(void)addTag:(NSString*)tag;
-(void)removeTag:(NSString*)tag;
@end






