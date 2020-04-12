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

//消息标志
#define MESSAGE_FLAG_DELETE 1
#define MESSAGE_FLAG_ACK 2
//#define MESSAGE_FLAG_PEER_ACK 4
#define MESSAGE_FLAG_FAILURE 8
#define MESSAGE_FLAG_UPLOADING 16
#define MESSAGE_FLAG_SENDING 32
#define MESSAGE_FLAG_LISTENED 64


@interface IMessage : NSObject <NSCopying>
+(MessageContent*)fromRaw:(NSString*)raw;

@property(nonatomic) int64_t msgId;
@property(nonatomic) int msgLocalID;
@property(nonatomic) int flags;
@property(nonatomic) int64_t sender;
@property(nonatomic) int64_t receiver;
@property(nonatomic) BOOL secret;

@property(nonatomic, copy) NSString *rawContent;
@property(nonatomic, readonly) int type;
@property(nonatomic, readonly) NSString *uuid;

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

@property(nonatomic, readonly) MessageAttachmentContent *attachmentContent;

@property(nonatomic) int timestamp;
@property(nonatomic, readonly) BOOL isACK;
@property(nonatomic, readonly) BOOL isFailure;
@property(nonatomic, readonly) BOOL isListened;

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

@end






