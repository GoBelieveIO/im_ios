/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

#define MESSAGE_UNKNOWN 0
#define MESSAGE_TEXT 1
#define MESSAGE_IMAGE 2
#define MESSAGE_AUDIO 3
#define MESSAGE_LOCATION 4
#define MESSAGE_GROUP_NOTIFICATION 5 //群通知
#define MESSAGE_ATTACHMENT 255 //消息附件


#define MESSAGE_FLAG_DELETE 1
#define MESSAGE_FLAG_ACK 2
//#define MESSAGE_FLAG_PEER_ACK 4
#define MESSAGE_FLAG_FAILURE 8
#define MESSAGE_FLAG_UPLOADING 16
#define MESSAGE_FLAG_SENDING 32
#define MESSAGE_FLAG_LISTENED 64

#define NOTIFICATION_GROUP_CREATED 1
#define NOTIFICATION_GROUP_DISBANDED 2
#define NOTIFICATION_GROUP_MEMBER_ADDED 3
#define NOTIFICATION_GROUP_MEMBER_LEAVED 4

@interface Audio : NSObject
@property(nonatomic, copy) NSString *url;
@property(nonatomic) int duration;
@end

@interface GroupNotification : NSObject

@property(nonatomic, copy) NSString *raw;
@property(nonatomic) int type;

@property(nonatomic) int64_t groupID;

@property(nonatomic) int timestamp;
//created
@property(nonatomic) int64_t master;
@property(nonatomic) NSString *groupName;
@property(nonatomic) NSArray *members;

//GROUP_MEMBER_ADDED,GROUP_MEMBER_LEAVED
@property(nonatomic) int64_t member;

-(id)initWithRaw:(NSString*)raw;

@end

//消息附件
@interface MessageContentAttachment : NSObject
@property(nonatomic) int msgLocalID;

@property(nonatomic) NSString *address;
@end

@interface MessageContent : NSObject

- (id)initWithText:(NSString*)text;
- (id)initWithImageURL:(NSString*)imageURL;
- (id)initWithAudio:(Audio*)audio;
- (id)initWithNotification:(GroupNotification*)notification;
- (id)initWithLocation:(CLLocationCoordinate2D)location;
- (id)initWithAttachment:(int)msgLocalID address:(NSString*)address;
- (id)initWithRaw:(NSString*)raw;

@property(nonatomic) int type;
@property(nonatomic) NSString *raw;

//text message
@property(nonatomic, readonly) NSString *text;

//audio message
@property(nonatomic, readonly) Audio *audio;

//location message
@property(nonatomic, readonly) CLLocationCoordinate2D location;
@property(nonatomic, readonly) NSString *snapshotURL;
@property(nonatomic, copy) NSString *address;

//notification message
@property(nonatomic, readonly) GroupNotification *notification;
@property(nonatomic, copy) NSString *notificationDesc;

//image message
@property(nonatomic, readonly) NSString *imageURL;
@property(nonatomic, readonly) NSString *littleImageURL;

//message attachment
@property(nonatomic, readonly) MessageContentAttachment *attachment;

@end

@interface IUser : NSObject
@property(nonatomic) int64_t uid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;

//name为nil时，界面显示identifier字段
@property(nonatomic, copy) NSString *identifier;
@end

@interface IMessage : NSObject
@property(nonatomic) int msgLocalID;
@property(nonatomic) int flags;
@property(nonatomic) int64_t sender;
@property(nonatomic) int64_t receiver;
@property(nonatomic) MessageContent *content;
@property(nonatomic) int timestamp;
@property(nonatomic, readonly) BOOL isACK;
@property(nonatomic, readonly) BOOL isFailure;
@property(nonatomic, readonly) BOOL isListened;

//UI, kvo
@property(nonatomic) BOOL uploading;
@property(nonatomic) BOOL downloading;
@property(nonatomic) BOOL playing;
@property(nonatomic) int progress;//[0,100]
@property(nonatomic) BOOL geocoding;

@property(nonatomic) IUser *senderInfo;

@end

@interface IGroup : NSObject
@property(nonatomic, assign) int64_t gid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;

//name为nil时，界面显示identifier字段
@property(nonatomic, copy) NSString *identifier;

@end

#define CONVERSATION_PEER 1
#define CONVERSATION_GROUP 2
@interface Conversation : NSObject
@property(nonatomic) int type;
@property(nonatomic, assign) int64_t cid;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy) NSString *avatarURL;
@property(nonatomic) IMessage *message;

@property(nonatomic) int newMsgCount;
@property(nonatomic, copy) NSString *detail;
@end
