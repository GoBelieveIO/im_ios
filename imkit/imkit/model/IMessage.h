//
//  IMessage.h
//  im
//
//  Created by houxh on 14-6-28.
//  Copyright (c) 2014年 potato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

#define MESSAGE_UNKNOWN 0
#define MESSAGE_TEXT 1
#define MESSAGE_IMAGE 2
#define MESSAGE_AUDIO 3
#define MESSAGE_LOCATION 4
#define MESSAGE_GROUP_NOTIFICATION 5 //群通知


#define MESSAGE_FLAG_DELETE 1
#define MESSAGE_FLAG_ACK 2
#define MESSAGE_FLAG_PEER_ACK 4
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

//created
@property(nonatomic) int64_t master;
@property(nonatomic) NSString *groupName;
@property(nonatomic) NSArray *members;

//GROUP_MEMBER_ADDED,GROUP_MEMBER_LEAVED
@property(nonatomic) int64_t member;

-(id)initWithRaw:(NSString*)raw;

@end

@interface MessageContent : NSObject

- (id)initWithText:(NSString*)text;
- (id)initWithImageURL:(NSString*)imageURL;
- (id)initWithAudio:(Audio*)audio;
- (id)initWithNotification:(GroupNotification*)notification;
- (id)initWithRaw:(NSString*)raw;

@property(nonatomic)int type;
@property(nonatomic)NSString *raw;

@property(nonatomic, readonly)NSString *text;
@property(nonatomic, readonly)Audio *audio;
@property(nonatomic, readonly)CLLocationCoordinate2D location;

@property(nonatomic, readonly)GroupNotification *notification;
@property(nonatomic, copy) NSString *notificationDesc;

@property(nonatomic, readonly)NSString *imageURL;
-(NSString*) littleImageURL;

@end

@interface MessageContent(Text)
@property(nonatomic, readonly)NSString *text;
@end

@interface IMessage : NSObject
@property(nonatomic) int msgLocalID;
@property(nonatomic) int flags;
@property(nonatomic) int64_t sender;
@property(nonatomic) int64_t receiver;
@property(nonatomic) MessageContent *content;
@property(nonatomic) int timestamp;
@property(nonatomic, readonly) BOOL isACK;
@property(nonatomic, readonly) BOOL isPeerACK;
@property(nonatomic, readonly) BOOL isFailure;
@property(nonatomic)           BOOL isListened;
@end


#define CONVERSATION_PEER 1
#define CONVERSATION_GROUP 2
@interface Conversation : NSObject
@property(nonatomic)int type;
@property(nonatomic, assign)int64_t cid;
@property(nonatomic, copy)NSString *name;
@property(nonatomic, copy)NSString *avatarURL;
@property(nonatomic)IMessage *message;
@property(nonatomic)int newMsgCount;
@end