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


#define MESSAGE_FLAG_DELETE 1
#define MESSAGE_FLAG_ACK 2
#define MESSAGE_FLAG_PEER_ACK 4
#define MESSAGE_FLAG_FAILURE 8
#define MESSAGE_FLAG_UPLOADING 16
#define MESSAGE_FLAG_SENDING 32
#define MESSAGE_FLAG_LISTENED 64

@interface Audio : NSObject
@property(nonatomic, copy) NSString *url;
@property(nonatomic) int duration;
@end

@interface MessageContent : NSObject
@property(nonatomic)int type;
@property(nonatomic)NSString *raw;

@property(nonatomic, readonly)NSString *text;
@property(nonatomic, readonly)NSString *imageURL;
@property(nonatomic, readonly)Audio *audio;
@property(nonatomic, readonly)CLLocationCoordinate2D location;

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